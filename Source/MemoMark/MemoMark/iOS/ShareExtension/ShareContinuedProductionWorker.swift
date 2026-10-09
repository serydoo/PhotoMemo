#if os(iOS) && DEBUG && MEMOMARK_SHARE_EXTENSION
import Foundation
import ActivityKit
import os

/// Opt-in signed-device production-path validation. Uses the original media
/// executor and save receipts. It is not the Release Share scheduling policy.
@available(iOS 26.0, *)
@MainActor
final class ShareContinuedProductionWorker {
    enum Failure: Error {
        case ownerUnavailable, requestUnavailable, admissionRejected, persistenceBlocked, unfinished
    }

    private let defaults = MemoMarkSharedContainer.sharedUserDefaults
    private let execution = BatchQueueExecution()
    private let arbiter = BackgroundExecutionArbiter(fileLock: .init(
        url: MemoMarkSharedContainer.baseDirectoryURL.appendingPathComponent("BatchQueue/.execution.lock")))
    private var stopRequested = false

    static func preserveInterruptedRequest(_ requestID: UUID) async throws {
        let store = ExternalIntakeRequestStore(defaults: MemoMarkSharedContainer.sharedUserDefaults,
            lockURL: MemoMarkSharedContainer.externalIntakeDirectoryURL.appendingPathComponent(".external-intake-requests.lock"))
        guard case .success = store.suspendRequest(requestID) else { throw Failure.persistenceBlocked }
        let bootstrap = BatchQueueDurableLedger.bootstrap(persistence: BatchQueuePersistence())
        guard bootstrap.error == nil else { throw Failure.persistenceBlocked }
        let snapshot = await bootstrap.ledger.refreshedSnapshot()
        guard !snapshot.isPersistenceBlocked else { throw Failure.persistenceBlocked }
        if let job = snapshot.jobs.first(where: { $0.intakeRequestID == requestID }) {
            if case .failure = await bootstrap.ledger.suspendExecutionSession(job.executionSessionID ?? job.id) {
                throw Failure.persistenceBlocked
            }
        }
        MemoMarkBackgroundProbe.record("extension.production.intakeSuspended.\(requestID)")
    }

    func run(requestID: UUID, presentationOwnerID: UUID? = nil, continuationIdentifier: String? = nil, progress: @escaping (ExecutionSession) -> Void) async throws {
        var acquiredLease: ExecutionLease?
        for _ in 0..<120 {
            try Task.checkCancellation()
            if let lease = arbiter.acquire(owner: .continuedProcessing) { acquiredLease = lease; break }
            try await Task.sleep(for: .seconds(1))
        }
        guard let lease = acquiredLease else { throw Failure.ownerUnavailable }
        MemoMarkBackgroundProbe.record("extension.production.leaseAcquired.\(requestID)", detail: "lease=\(lease.id)")
        MemoMarkBackgroundProbe.record("extension.production.systemConditions.\(requestID)",
            detail: "thermal=\(ProcessInfo.processInfo.thermalState.rawValue);lowPower=\(ProcessInfo.processInfo.isLowPowerModeEnabled)")
        let presentationID = presentationOwnerID ?? lease.id
        ProcessingPresentationAuthority.renew(leaseID: presentationID, defaults: defaults)
        let heartbeat = Task { @MainActor in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(5)) } catch { return }
                guard !Task.isCancelled else { return }
                ProcessingPresentationAuthority.renew(leaseID: presentationID, defaults: defaults)
            }
        }
        defer {
            heartbeat.cancel()
            if presentationOwnerID == nil {
                ProcessingPresentationAuthority.release(leaseID: presentationID, defaults: defaults)
            }
            _ = arbiter.release(lease)
            MemoMarkBackgroundProbe.record("extension.production.leaseReleased.\(requestID)", detail: "lease=\(lease.id)")
        }
        // The exclusive execution lease proves another worker cannot still
        // be encoding these process-owned interrupted scratch rasters.
        try CPUFileRasterExport.cleanupInterruptedRasters(in: FileManager.default.temporaryDirectory
            .appendingPathComponent("MemoMarkExports", isDirectory: true))
        try CPUFileRasterExport.cleanupInterruptedRasters(inProcessingRoot: FileManager.default.temporaryDirectory
            .appendingPathComponent("MemoMarkLivePhotoProcessing", isDirectory: true))
        let fallbackActivities = Activity<MemoMarkBackgroundActivityAttributes>.activities
        for activity in fallbackActivities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        MemoMarkBackgroundProbe.record("extension.production.fallbackActivitiesEnded", detail: String(fallbackActivities.count))
        let requests = ExternalIntakeRequestStore(defaults: defaults,
            lockURL: MemoMarkSharedContainer.externalIntakeDirectoryURL.appendingPathComponent(".external-intake-requests.lock"))
        MemoMarkBackgroundProbe.record("extension.production.beforeIntakeRead", detail: "availableMemory=\(os_proc_available_memory())")
        let request = requests.loadRequestsForProcessing().first(where: { $0.id == requestID })
        MemoMarkBackgroundProbe.record("extension.production.beforeLedgerBootstrap", detail: "availableMemory=\(os_proc_available_memory())")
        let bootstrap = BatchQueueDurableLedger.bootstrap(persistence: BatchQueuePersistence())
        guard bootstrap.error == nil else { throw Failure.persistenceBlocked }
        MemoMarkBackgroundProbe.record("extension.production.ledgerBootstrapped", detail: "availableMemory=\(os_proc_available_memory())")
        let ledger = bootstrap.ledger
        let accounting = BatchQueueCommerceAccounting(persistence: MemoMarkCommercePersistence())
        var commerce = accounting.loadSharedSnapshot(compatibleWith: .currentRuntime)
        var job: BatchJob
        if let existing = bootstrap.snapshot.jobs.first(where: { $0.intakeRequestID == requestID }) {
            job = existing
        } else {
            guard let request else { throw Failure.requestUnavailable }
            let resolver = ShareIntakePayloadResolver(livePhotoAssetIdentityResolver: PhotoKitLivePhotoAssetIdentityResolver(),
                                                      diagnosticsDefaults: defaults)
            let configuration = request.configurationSnapshot
            let permitsStaticFallback = LivePhotoStaticFallbackPolicy.allowsStaticFallback(
                mediaOutputModeRawValue: configuration.mediaOutputModeRawValue,
                livePhotoPolicyRawValue: configuration.livePhotoPolicyRawValue)
            let contexts = resolver.payloadContexts(for: request)
                .filter { resolver.isValidRequestSourceURL($0.payload.sourceURL) }
                .map { resolver.recoveredPayloadContext($0, requestID: requestID, permitsStaticFallback: permitsStaticFallback) }
            let payloads = resolver.uniquePayloadContextsForCurrentDrain(contexts, consumedPayloadKeys: []).contexts.map(\.payload)
            guard payloads.count == request.intakePayloads.count,
                  var candidate = execution.enqueue(payloads: payloads, configuration: configuration,
                                              launchSource: request.launchSource, intakeSummary: request.importSummary,
                                              intakeRequestID: requestID) else { throw Failure.admissionRejected }
            candidate.createdAt = request.receivedAt
            candidate.executionSuspendedAt = request.executionSuspendedAt
            candidate.executionSessionID = request.continuedExecutionSessionID
            MemoMarkBackgroundProbe.record("extension.production.beforeIdentityCompile", detail: "availableMemory=\(os_proc_available_memory())")
            candidate = try await BatchProcessingIdentityCompiler.prepare(candidate)
            MemoMarkBackgroundProbe.record("extension.production.identityCompiled", detail: "availableMemory=\(os_proc_available_memory())")
            guard candidate.tasks.allSatisfy({ $0.processingIdentity != nil }) else { throw Failure.admissionRejected }
            guard candidate.tasks.count <= commerce.batchLimit else { throw Failure.admissionRejected }
            let capacity = accounting.admissionCapacity(among: [], current: commerce)
            MemoMarkBackgroundProbe.record("extension.production.beforeAdmission", detail: "availableMemory=\(os_proc_available_memory())")
            let admissionResult = await ledger.admit(candidate, maximumPendingTaskCount: capacity)
            MemoMarkBackgroundProbe.record("extension.production.admissionReturned", detail: "availableMemory=\(os_proc_available_memory())")
            switch admissionResult {
            case .committed(let admission, _), .unchanged(let admission, _):
                guard let admission else { throw Failure.admissionRejected }
                job = admission.job
            case .failure:
                throw Failure.persistenceBlocked
            }
        }
        // Re-read after the actor admission boundary; a system interruption may
        // have persisted the hold while this request was compiling its identity.
        switch requests.loadRequestsForProcessingResult() {
        case .success(let pending):
            if let heldAt = pending.first(where: { $0.id == requestID })?.executionSuspendedAt {
                if case .failure = await ledger.suspendExecutionSession(job.executionSessionID ?? job.id, now: heldAt) {
                    throw Failure.persistenceBlocked
                }
                job.executionSuspendedAt = heldAt
            }
        case .noValue: break
        case .decodingFailed: throw Failure.persistenceBlocked
        }
        // Another owner may already have consumed this request after durable admission.
        if request != nil {
            guard case .success = requests.acknowledgeRequests([requestID]) else { throw Failure.persistenceBlocked }
        }
        let jobID = job.id
        guard job.executionSuspendedAt == nil else { throw Failure.unfinished }
        MemoMarkBackgroundProbe.record("extension.production.session.\(requestID)", detail: "session=\(job.executionSessionID ?? job.id)")
        var lastProgressCounts: (Int, Int)?
        @MainActor func reportProgress(_ job: BatchJob) async {
            // apply/admit already refreshed under the transaction lock. Do
            // not perform another synchronous disk read for every UI update.
            let snapshot = await ledger.snapshot()
            guard !snapshot.isPersistenceBlocked else { self.stopRequested = true; return }
            var pendingIntakeCount = 0
            if let continuationIdentifier {
                do {
                    let accepted = try requests.continuationRequestIDs(identifier: continuationIdentifier)
                    let admitted = Set(snapshot.jobs.compactMap(\.intakeRequestID))
                    switch requests.loadRequestsForProcessingResult() {
                    case .success(let pending):
                        pendingIntakeCount = pending.filter { accepted.contains($0.id) && !admitted.contains($0.id) }
                            .reduce(0) { $0 + $1.intakePayloads.count }
                    case .noValue: break
                    case .decodingFailed: self.stopRequested = true; return
                    }
                } catch { self.stopRequested = true; return }
            }
            let session = ExecutionSession(id: job.executionSessionID ?? job.id, jobs: snapshot.jobs,
                pendingIntakeTaskCount: pendingIntakeCount)
            let counts = (session.completedCount, session.totalCount)
            if lastProgressCounts.map({ $0.0 != counts.0 || $0.1 != counts.1 }) ?? true {
                MemoMarkBackgroundProbe.record("extension.production.progress.\(requestID)",
                    detail: "completed=\(session.completedCount) total=\(session.totalCount) units=\(session.completedProgressUnits)/\(session.totalProgressUnits)")
                lastProgressCounts = counts
            }
            progress(session)
        }
        let runtime = DurableBatchTaskExecutionRuntime(ledger: ledger, jobIDs: [jobID],
            cleanupSource: { ExternalPhotoIntakeStore.shared.cleanupManagedSourceIfNeeded(at: $0) },
            didCommit: { task, job in
                if task.phase == .completed {
                    let outcome = accounting.recordSuccessfulSave(for: task, current: commerce)
                    if let updated = outcome.updatedSnapshot {
                        guard accounting.saveSharedSnapshot(updated) else { self.stopRequested = true; return }
                        commerce = updated
                    }
                    if outcome.requiresRecovery { self.stopRequested = true }
                }
                await reportProgress(job)
            }, cancellation: { self.stopRequested = true },
            publishError: { message in MemoMarkBackgroundProbe.record("extension.production.persistenceError", detail: message) })
        MemoMarkBackgroundProbe.record("extension.production.beforeTaskLoop", detail: "availableMemory=\(os_proc_available_memory())")
        await reportProgress(job)
        while !Task.isCancelled, !stopRequested,
              !defaults.bool(forKey: "memomark.processing.executionPaused") {
            let snapshot = await ledger.refreshedSnapshot()
            guard !snapshot.isPersistenceBlocked else { throw Failure.persistenceBlocked }
            guard let currentJob = snapshot.jobs.first(where: { $0.id == jobID }),
                  currentJob.executionSuspendedAt == nil,
                  let task = currentJob.tasks.first(where: { $0.phase == .queued }) else { break }
            let budget = BatchTaskMemoryPolicy.mediaMemoryBudget(for: task)
            let reference = BatchTaskReference(jobID: jobID, taskID: task.id)
            await execution.process(context: .init(taskReference: reference, taskSnapshot: task,
                configuration: currentJob.configuration, memoryBudget: budget,
                route: BatchTaskMemoryPolicy.processingRoute(for: task),
                totalProgressUnits: budget.requiresExtendedPreviewPreparation ? 6 : 5,
                startedAt: Date()), runtime: runtime)
            MemoMarkBackgroundProbe.record("extension.production.taskReturned", detail: "request=\(requestID) task=\(task.id)")
        }
        if Task.isCancelled {
            let held = await ledger.suspendExecutionSession(job.executionSessionID ?? job.id)
            if case .failure = held { throw Failure.persistenceBlocked }
            MemoMarkBackgroundProbe.record("extension.production.sessionSuspended.\(requestID)")
        }
        let snapshot = await ledger.refreshedSnapshot()
        if Task.isCancelled, !snapshot.isPersistenceBlocked,
           let message = ExecutionSessionSuspensionNotification.make(
               id: job.executionSessionID ?? job.id, jobs: snapshot.jobs,
               language: MemoMarkLanguage.interfaceStored) {
            await ShareContinuedCompletionNotification.deliverSuspension(
                message, ledger: ledger, requestID: requestID)
        }
        if let remaining = snapshot.jobs.first(where: { $0.id == jobID }) {
            let phases = remaining.tasks.map { String(describing: $0.phase) }.joined(separator: ",")
            MemoMarkBackgroundProbe.record("extension.production.exitState.\(requestID)",
                detail: "cancelled=\(Task.isCancelled);stop=\(stopRequested);paused=\(defaults.bool(forKey: "memomark.processing.executionPaused"));phases=\(phases)")
        }
        guard !snapshot.isPersistenceBlocked,
              let completed = snapshot.jobs.first(where: { $0.id == jobID }),
              completed.tasks.allSatisfy({ $0.phase == .completed }) else { throw Failure.unfinished }
        await reportProgress(completed)
        let pendingIntakeRequestIDs: Set<UUID>?
        switch requests.loadRequestsForProcessingResult() {
        case .success(let pending): pendingIntakeRequestIDs = Set(pending.map(\.id))
        case .noValue: pendingIntakeRequestIDs = []
        case .decodingFailed: pendingIntakeRequestIDs = nil
        }
        if let message = ExecutionSessionCompletionNotification.make(
            id: completed.executionSessionID ?? completed.id, jobs: snapshot.jobs,
            language: MemoMarkLanguage.interfaceStored, pendingIntakeRequestIDs: pendingIntakeRequestIDs) {
            await ShareContinuedCompletionNotification.deliver(message, ledger: ledger, requestID: requestID)
        } else if pendingIntakeRequestIDs == nil || pendingIntakeRequestIDs?.isEmpty == false {
            MemoMarkBackgroundProbe.record("extension.production.completionDeferred.\(requestID)",
                detail: "pendingIntakes=\(pendingIntakeRequestIDs?.count ?? -1)")
        }
    }
}
#endif
