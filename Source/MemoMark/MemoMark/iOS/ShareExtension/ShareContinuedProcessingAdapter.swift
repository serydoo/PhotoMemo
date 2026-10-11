#if os(iOS) && MEMOMARK_SHARE_EXTENSION
import BackgroundTasks
import Foundation

@available(iOS 26.0, *)
@MainActor
enum ShareContinuedProcessingAdapter {
    private static let identifierPrefix = "com.serydoo.PhotoMemo.iOS.continued-processing.share"
    private static var continuationStore: ExternalIntakeRequestStore {
        ExternalIntakeRequestStore(
            defaults: MemoMarkSharedContainer.sharedUserDefaults,
            lockURL: MemoMarkSharedContainer.externalIntakeDirectoryURL
                .appendingPathComponent(".external-intake-requests.lock")
        )
    }

    static func submit(requestID: UUID) async -> Bool {
        let identifier = "\(identifierPrefix).\(requestID.uuidString)"
        let pendingSystemIdentifiers = await withCheckedContinuation { continuation in
            BGTaskScheduler.shared.getPendingTaskRequests { requests in
                continuation.resume(returning: Set(requests.map(\.identifier)))
            }
        }
        do {
            let owner = try continuationStore.reserveContinuation(
                requestID: requestID,
                identifier: identifier,
                pendingSystemIdentifiers: pendingSystemIdentifiers
            )
            guard owner == identifier else {
                ShareContinuedProcessingDiagnostics.record(
                    "share.continued.joined",
                    detail: "identifier=\(owner)"
                )
                return true
            }
        } catch {
            ShareContinuedProcessingDiagnostics.record(
                "share.continued.reservationFailed",
                identifier: identifier,
                error: error
            )
            return false
        }

        let registered = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: identifier,
            using: nil
        ) { task in
            Task { @MainActor in
                await handle(task, identifier: identifier, requestID: requestID)
            }
        }
        guard registered else {
            ShareContinuedProcessingDiagnostics.record(
                "share.continued.registrationRejected",
                detail: "identifier=\(identifier)"
            )
            _ = try? continuationStore.finishContinuation(identifier: identifier)
            return false
        }

        let language = MemoMarkLanguage.interfaceStored
        let subtitle = ContinuedProcessingMessageFormatter.preparingSubtitle(language: language)
        do {
            _ = try await ContinuedProcessingSubmission.submit(
                identifier: identifier,
                title: ContinuedProcessingMessageFormatter.processingTitle(language: language),
                subtitle: subtitle,
                immediate: false
            )
            ShareContinuedProcessingDiagnostics.record(
                "share.continued.submitted",
                detail: "identifier=\(identifier)"
            )
            return true
        } catch {
            ShareContinuedProcessingDiagnostics.record(
                "share.continued.submissionRejected",
                identifier: identifier,
                error: error
            )
            _ = try? continuationStore.finishContinuation(identifier: identifier)
            return false
        }
    }

    private static func handle(
        _ task: BGTask,
        identifier: String,
        requestID: UUID
    ) async {
        guard let continuedTask = task as? BGContinuedProcessingTask else {
            MemoMarkShareDiagnostics.record(
                stage: .extensionContinuedProcessingFailure,
                message: "reason=unexpectedTaskType",
                requestID: requestID
            )
            task.setTaskCompleted(success: false)
            return
        }

        // A delayed callback from a superseded registration has no authority
        // to hold requests now owned by a different continuation.
        guard (try? continuationStore.renewContinuation(identifier: identifier)) == true else {
            MemoMarkShareDiagnostics.record(
                stage: .extensionContinuedProcessingFailure,
                message: "reason=continuationOwnershipLost",
                requestID: requestID
            )
            continuedTask.setTaskCompleted(success: false)
            return
        }
        let runID = UUID()
        var runningOperation: Task<Bool, Error>?
        var renewalFailed = false
        let heartbeat = Task { @MainActor in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(5))
                    guard !Task.isCancelled else { return }
                    guard try continuationStore.renewContinuation(identifier: identifier) else {
                        renewalFailed = true
                        runningOperation?.cancel()
                        return
                    }
                    ProcessingPresentationAuthority.renew(
                        leaseID: runID,
                        defaults: MemoMarkSharedContainer.sharedUserDefaults
                    )
                } catch is CancellationError {
                    return
                } catch {
                    renewalFailed = true
                    runningOperation?.cancel()
                    return
                }
            }
        }
        ProcessingPresentationAuthority.renew(
            leaseID: runID,
            defaults: MemoMarkSharedContainer.sharedUserDefaults
        )
        defer {
            heartbeat.cancel()
            ProcessingPresentationAuthority.release(
                leaseID: runID,
                defaults: MemoMarkSharedContainer.sharedUserDefaults
            )
        }

        var activeRequestID = requestID
        let operation = Task { @MainActor in
            var processedAnyRequest = false
            while !Task.isCancelled {
                guard !renewalFailed else { throw CocoaError(.fileWriteUnknown) }
                guard let nextRequestID = try continuationStore.nextContinuation(identifier: identifier) else {
                    return processedAnyRequest
                }
                activeRequestID = nextRequestID
                processedAnyRequest = true
                let taskWorker = ShareContinuedProductionWorker()
                try await taskWorker.run(
                    requestID: nextRequestID,
                    presentationOwnerID: runID,
                    continuationIdentifier: identifier
                ) { session in
                    continuedTask.progress.totalUnitCount = Int64(session.totalProgressUnits)
                    continuedTask.progress.completedUnitCount = Int64(session.completedProgressUnits)
                    let message = ContinuedProcessingMessageFormatter.message(
                        for: session,
                        language: MemoMarkLanguage.interfaceStored
                    )
                    continuedTask.updateTitle(message.title, subtitle: message.subtitle)
                }
            }
            throw CancellationError()
        }
        runningOperation = operation
        continuedTask.expirationHandler = {
            operation.cancel()
        }

        do {
            let processedAnyRequest = try await operation.value
            if !processedAnyRequest || operation.isCancelled {
                MemoMarkShareDiagnostics.record(
                    stage: .extensionContinuedProcessingFailure,
                    message: "reason=noRequestProcessed;cancelled=\(operation.isCancelled)",
                    requestID: activeRequestID
                )
            }
            continuedTask.setTaskCompleted(success: processedAnyRequest && !operation.isCancelled)
            ShareContinuedProcessingDiagnostics.record(
                "share.continued.finished",
                detail: "identifier=\(identifier);processed=\(processedAnyRequest);cancelled=\(operation.isCancelled)"
            )
            _ = try? continuationStore.finishContinuation(identifier: identifier)
        } catch {
            var interruptedRequestIDs = Set<UUID>()
            do {
                interruptedRequestIDs = Set(try continuationStore.finishContinuation(
                    identifier: identifier,
                    suspendRequestsAt: Date()
                ))
            } catch {
                ShareContinuedProcessingDiagnostics.record(
                    "share.continued.sessionCloseFailed",
                    identifier: identifier,
                    error: error
                )
            }
            if !renewalFailed { interruptedRequestIDs.insert(activeRequestID) }
            for interruptedRequestID in interruptedRequestIDs {
                do {
                    try await ShareContinuedProductionWorker.preserveInterruptedRequest(interruptedRequestID)
                } catch {
                    ShareContinuedProcessingDiagnostics.record(
                        "share.continued.recoveryHoldFailed",
                        identifier: identifier,
                        error: error
                    )
                }
            }
            if !operation.isCancelled {
                let bootstrap = BatchQueueDurableLedger.bootstrap(
                    persistence: BatchQueuePersistence()
                )
                if bootstrap.error == nil {
                    let snapshot = await bootstrap.ledger.refreshedSnapshot()
                    let pending: [ExternalPhotoIntakeRequest]
                    let pendingStateIsKnown: Bool
                    switch continuationStore.loadRequestsForProcessingResult() {
                    case .success(let requests):
                        pending = requests
                        pendingStateIsKnown = true
                    case .noValue:
                        pending = []
                        pendingStateIsKnown = true
                    case .decodingFailed:
                        pending = []
                        pendingStateIsKnown = false
                    }
                    let admitted = Set(snapshot.jobs.compactMap(\.intakeRequestID))
                    let sessions = Set(interruptedRequestIDs.map { interruptedID in
                        snapshot.jobs.first(where: { $0.intakeRequestID == interruptedID }).map { $0.executionSessionID ?? $0.id }
                            ?? pending.first(where: { $0.id == interruptedID })?.continuedExecutionSessionID
                            ?? interruptedID
                    })
                    for sessionID in sessions {
                        let waiting = pending.filter {
                            interruptedRequestIDs.contains($0.id) && !admitted.contains($0.id)
                                && ($0.continuedExecutionSessionID ?? $0.id) == sessionID
                        }
                        let pendingCount = waiting.reduce(0) { $0 + $1.intakePayloads.count }
                        let hasMember = snapshot.jobs.contains { ($0.executionSessionID ?? $0.id) == sessionID }
                        if let message = ExecutionSessionSuspensionNotification.makeFailure(
                            id: sessionID, jobs: snapshot.jobs,
                            pendingItemCount: pendingStateIsKnown && (hasMember || pendingCount > 0) ? pendingCount : nil,
                            language: MemoMarkLanguage.interfaceStored) {
                            await ShareContinuedCompletionNotification.deliverSuspension(
                                message, ledger: bootstrap.ledger, requestID: activeRequestID)
                        }
                    }
                }
            }
            _ = MemoMarkShareDiagnostics.recordContinuedProcessingFailure(
                error,
                requestID: activeRequestID
            )
            continuedTask.setTaskCompleted(success: false)
            ShareContinuedProcessingDiagnostics.record(
                "share.continued.interrupted",
                identifier: identifier,
                error: error
            )
        }
    }
}
#endif
