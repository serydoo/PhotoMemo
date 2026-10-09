#if os(iOS) && DEBUG
import BackgroundTasks
import Foundation
import UIKit
import os
import ImageIO
import UniformTypeIdentifiers
#if !MEMOMARK_SHARE_EXTENSION
import Photos
#endif

/// Opt-in development markers and signed-device production-path experiments.
/// Submission, host callback and marker completion are separate evidence.
@available(iOS 26.0, *)
enum ContinuedProcessingSpike {
    static let identifierPrefix = "com.serydoo.PhotoMemo.iOS.continued-spike"
    static let nextMarkerKey = "continuedProcessingSpike.nextMarker"
    static let enabledUntilKey = "continuedProcessingSpike.enabledUntil"
    static let productionEnabledUntilKey = "continuedProcessingSpike.productionEnabledUntil"
    static let descriptionProbeValueKey = "continuedProcessingSpike.descriptionProbeValue"
    static let hostQueueUntilKey = "continuedProcessingSpike.hostQueueUntil"
    static let hostQueueIdentifierKey = "continuedProcessingSpike.hostQueueIdentifier"
    static let hostHandoffUntilKey = "continuedProcessingSpike.hostHandoffUntil"
    static let evidenceKey = "continuedProcessingSpike.evidence"
    private static func shareCompletionKey(_ requestID: UUID) -> String {
        "continuedProcessingSpike.shareCompletionRequested." + requestID.uuidString
    }

    static func markShareCompletionRequested(requestID: UUID) {
        defaults.set(true, forKey: shareCompletionKey(requestID))
        MemoMarkBackgroundProbe.record("extension.shareCompletionRequested", detail: "request=\(requestID)")
    }

    private static func waitForShareCompletionRequest(requestID: UUID) async throws {
        for _ in 0..<300 {
            try Task.checkCancellation()
            if defaults.bool(forKey: shareCompletionKey(requestID)) { return }
            try await Task.sleep(for: .milliseconds(100))
        }
        throw CocoaError(.userCancelled)
    }
    private static var defaults: UserDefaults { MemoMarkSharedContainer.sharedUserDefaults }
    private static var continuationStore: ExternalIntakeRequestStore {
        ExternalIntakeRequestStore(defaults: defaults,
            lockURL: MemoMarkSharedContainer.externalIntakeDirectoryURL.appendingPathComponent(".external-intake-requests.lock"))
    }


    static var isEnabled: Bool {
        defaults.double(forKey: enabledUntilKey) > Date().timeIntervalSince1970
    }

    static func submitMarker(requestID: UUID) async -> Bool {
#if MEMOMARK_SHARE_EXTENSION
        let hostHandoff = defaults.double(forKey: hostHandoffUntilKey) > Date().timeIntervalSince1970
        let identifier: String
        if hostHandoff && defaults.double(forKey: hostQueueUntilKey) > Date().timeIntervalSince1970 {
            identifier = defaults.string(forKey: hostQueueIdentifierKey)
                ?? MemoMarkBackgroundTaskSubmission.continuedTaskIdentifier
            record("hostQueueSubmission", identifier: identifier)
        } else if hostHandoff {
            guard let registered = defaults.string(forKey: nextMarkerKey) else {
                record("missingHostRegistration", identifier: identifierPrefix)
                return false
            }
            identifier = registered
            record("hostHandoffSubmission", identifier: identifier)
        } else {
            identifier = identifierPrefix + "." + UUID().uuidString
            record("extensionProbeV4AllJPEGInputs", identifier: identifier)
        }
#else
        guard let identifier = defaults.string(forKey: nextMarkerKey) else {
            record("missingRegistration", identifier: identifierPrefix)
            return false
        }
        defaults.removeObject(forKey: nextMarkerKey)
#endif
#if MEMOMARK_SHARE_EXTENSION
        let coalescingEnabled = !hostHandoff && defaults.double(forKey: productionEnabledUntilKey) > Date().timeIntervalSince1970
        if coalescingEnabled {
            do {
                let routed = try continuationStore.reserveContinuation(requestID: requestID, identifier: identifier)
                if routed != identifier {
                    let joinedIdentifier = identifierPrefix + ".coalesced." + requestID.uuidString
                    defaults.set(requestID.uuidString, forKey: joinedIdentifier)
                    defaults.synchronize()
                    record("coalesced", identifier: joinedIdentifier)
                    MemoMarkBackgroundProbe.record("extension.production.intakeCoalesced.\(requestID)", detail: "owner=\(routed)")
                    return true
                }
            } catch {
                record("continuationReservationFailed", identifier: identifier, error: error)
                return false
            }
        }
        if !hostHandoff {
        let registered = BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            Task { @MainActor in
                record("extensionCallback", identifier: task.identifier)
                MemoMarkBackgroundProbe.record("extension.availableMemoryAtCallback", detail: String(os_proc_available_memory()))
                guard let task = task as? BGContinuedProcessingTask else {
                    task.setTaskCompleted(success: false)
                    return
                }
                task.progress.totalUnitCount = 45
                let operation = Task { @MainActor in
                    if defaults.double(forKey: productionEnabledUntilKey) > Date().timeIntervalSince1970 {
                        var currentRequestID: UUID?
                        let presentationID = UUID()
                        var renewalFailed = false
                        let heartbeat = Task { @MainActor in
                            while !Task.isCancelled {
                                do {
                                    try await Task.sleep(for: .seconds(5))
                                    if coalescingEnabled {
                                        _ = try continuationStore.renewContinuation(identifier: task.identifier)
                                    }
                                    ProcessingPresentationAuthority.renew(leaseID: presentationID, defaults: defaults)
                                } catch is CancellationError { return }
                                catch { renewalFailed = true; return }
                            }
                        }
                        ProcessingPresentationAuthority.renew(leaseID: presentationID, defaults: defaults)
                        defer {
                            heartbeat.cancel()
                            ProcessingPresentationAuthority.release(leaseID: presentationID, defaults: defaults)
                        }
                        do {
                            guard let marker = defaults.string(forKey: task.identifier),
                                  let initialRequestID = UUID(uuidString: marker) else { throw CocoaError(.fileReadCorruptFile) }
                            currentRequestID = initialRequestID
                            record("extensionProductionStarted", identifier: task.identifier)
                            var legacyRequestID: UUID? = initialRequestID
                            while true {
                                let next: UUID?
                                if coalescingEnabled {
                                    next = try continuationStore.nextContinuation(identifier: task.identifier)
                                } else {
                                    next = legacyRequestID
                                    legacyRequestID = nil
                                }
                                guard let next else { break }
                                currentRequestID = next
                                try Task.checkCancellation()
                                guard !renewalFailed else { throw CocoaError(.fileWriteUnknown) }
                                try await waitForShareCompletionRequest(requestID: next)
                                let worker = ShareContinuedProductionWorker()
                                try await worker.run(requestID: next, presentationOwnerID: presentationID,
                                    continuationIdentifier: coalescingEnabled ? task.identifier : nil) { session in
                                    task.progress.totalUnitCount = Int64(session.totalProgressUnits)
                                    task.progress.completedUnitCount = Int64(session.completedProgressUnits)
                                    let message = ContinuedProcessingMessageFormatter.message(
                                        for: session, language: MemoMarkLanguage.interfaceStored)
                                    task.updateTitle(message.title, subtitle: message.subtitle)
                                    MemoMarkBackgroundProbe.record("extension.production.systemProgress.\(task.identifier)",
                                        detail: "completed=\(session.completedCount) total=\(session.totalCount) units=\(session.completedProgressUnits)/\(session.totalProgressUnits)")
                                }
                                record("extensionRequestCompleted", identifier: identifierPrefix + ".coalesced." + next.uuidString)
                                MemoMarkBackgroundProbe.record("extension.production.requestCompleted.\(next)")
                            }
                            record("extensionProductionCompleted", identifier: task.identifier)
                            task.setTaskCompleted(success: true)
                        } catch {
                            var interrupted: Set<UUID> = currentRequestID.map { [$0] } ?? []
                            if coalescingEnabled {
                                do { interrupted.formUnion(try continuationStore.finishContinuation(identifier: task.identifier, suspendRequestsAt: Date())) }
                                catch { record("extensionContinuationCloseFailed", identifier: task.identifier, error: error) }
                            }
                            for requestID in interrupted {
                                do { try await ShareContinuedProductionWorker.preserveInterruptedRequest(requestID) }
                                catch { record("extensionIntakeHoldFailed", identifier: task.identifier, error: error) }
                            }
                            record("extensionProductionInterrupted", identifier: task.identifier, error: error)
                            task.setTaskCompleted(success: false)
                        }
                        return
                    }
                    for step in 1...45 {
                        do { try await Task.sleep(for: .seconds(1)) }
                        catch {
                            record("extensionMarkerCancelled", identifier: task.identifier)
                            task.setTaskCompleted(success: false)
                            return
                        }
                        task.progress.completedUnitCount = Int64(step)
                        record("extensionMarkerStep\(step)", identifier: task.identifier)
                    }
                    do {
                        guard let marker = defaults.string(forKey: task.identifier),
                              let requestID = UUID(uuidString: marker) else {
                            throw CocoaError(.fileReadCorruptFile)
                        }
                        try runJPEGProbe(requestID: requestID)
                        record("extensionJPEGReadbackPassed", identifier: task.identifier)
                        record("extensionMarkerCompleted", identifier: task.identifier)
                        task.setTaskCompleted(success: true)
                    } catch {
                        record("extensionJPEGFailed", identifier: task.identifier, error: error)
                        task.setTaskCompleted(success: false)
                    }
                }
                task.expirationHandler = {
                    record("extensionExpirationRequested", identifier: task.identifier)
                    MemoMarkBackgroundProbe.record("extension.production.expirationState",
                        detail: "progressCancelled=\(task.progress.isCancelled)")
                    operation.cancel()
                }
                await operation.value
            }
        }
        record(registered ? "extensionRegistered" : "extensionRegistrationRejected", identifier: identifier)
        guard registered else {
            if coalescingEnabled { _ = try? continuationStore.finishContinuation(identifier: identifier) }
            return false
        }
        }
#endif
        // Durable intake remains recoverable if system admission is rejected.
        let isProductionProbe = defaults.double(forKey: productionEnabledUntilKey) > Date().timeIntervalSince1970
        let language = MemoMarkLanguage.interfaceStored
        let subtitle = isProductionProbe
            ? ContinuedProcessingMessageFormatter.preparingSubtitle(language: language) : "验证后台接收"
        let title = isProductionProbe
            ? ContinuedProcessingMessageFormatter.processingTitle(language: language) : "MemoMark"
#if MEMOMARK_SHARE_EXTENSION
        let immediate = hostHandoff
#else
        let immediate = false
#endif
        defaults.set(requestID.uuidString, forKey: identifier)
        defaults.synchronize()
        do {
            let submittedOnMainThread = try await ContinuedProcessingSubmission.submit(
                identifier: identifier, title: title, subtitle: subtitle,
                immediate: immediate)
            record(submittedOnMainThread ? "submissionOnMainThread" : "submissionOffMainThread",
                   identifier: identifier)
            if #available(iOS 27.0, *) {
                record("submissionConfirmed", identifier: identifier)
            } else {
                // Legacy return does not prove daemon-side acceptance.
                record("legacySubmissionReturned", identifier: identifier)
            }
            record("submitted", identifier: identifier)
            return true
        } catch {
#if MEMOMARK_SHARE_EXTENSION
            if coalescingEnabled { _ = try? continuationStore.finishContinuation(identifier: identifier) }
#endif
            record("rejected", identifier: identifier, error: error)
            return false
        }
    }

#if MEMOMARK_SHARE_EXTENSION
    /// Bounded real-media probe only. It neither consumes intake nor writes Photos.
    private static func runJPEGProbe(requestID: UUID) throws {
        let executionLock = ProcessingExecutionFileLock(url: MemoMarkSharedContainer.baseDirectoryURL.appendingPathComponent("BatchQueue/.execution.lock"))
        guard try executionLock.acquire() else { throw POSIXError(.EWOULDBLOCK) }
        defer { executionLock.release() }
        MemoMarkBackgroundProbe.record("extension.availableMemoryAfterDismissal", detail: String(os_proc_available_memory()))
        let store = ExternalIntakeRequestStore(defaults: defaults,
            lockURL: MemoMarkSharedContainer.externalIntakeDirectoryURL.appendingPathComponent(".external-intake-requests.lock"))
        guard let request = store.loadRequestsForProcessing().first(where: { $0.id == requestID }),
              !request.urls.isEmpty else { throw CocoaError(.fileReadCorruptFile) }
        for (index, sourceURL) in request.urls.enumerated() {
            try Task.checkCancellation()
            try autoreleasepool {
                try verifyJPEG(sourceURL: sourceURL, requestID: requestID, index: index)
            }
            MemoMarkBackgroundProbe.record("extension.inputReadbackPassed",
                detail: "request=\(requestID) index=\(index) count=\(request.urls.count)")
        }
    }

    private static func verifyJPEG(sourceURL: URL, requestID: UUID, index: Int) throws {
        guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 1920,
                kCGImageSourceCreateThumbnailWithTransform: true
              ] as CFDictionary) else { throw CocoaError(.fileReadCorruptFile) }
        let directory = MemoMarkSharedContainer.baseDirectoryURL.appendingPathComponent("tmp/ContinuedJPEGProbe", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let output = directory.appendingPathComponent(requestID.uuidString + "-\(index).jpg")
        defer { try? FileManager.default.removeItem(at: output) }
        guard let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
        guard CGImageDestinationFinalize(destination),
              let readback = CGImageSourceCreateWithURL(output as CFURL, nil),
              let decoded = CGImageSourceCreateImageAtIndex(readback, 0, nil),
              decoded.width == image.width, decoded.height == image.height else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
#endif

    private static var applicationState: String {
#if MEMOMARK_SHARE_EXTENSION
        "extension"
#else
        String(UIApplication.shared.applicationState.rawValue)
#endif
    }

    static func record(_ event: String, identifier: String, error: Error? = nil) {
        let key = evidenceKey + "." + identifier + "." + event
        let record: [String: Any] = [
            "event": event, "identifier": identifier,
            "timestamp": Date().timeIntervalSince1970,
            "applicationState": applicationState,
            "error": error.map { String(describing: $0) } ?? ""
        ]
        defaults.set(record, forKey: key)
        defaults.synchronize()
        MemoMarkShareDiagnostics.record(stage: .extensionHandoffRequested,
            message: "continuedSpike event=\(event) identifier=\(identifier) state=\(applicationState)")
    }

#if !MEMOMARK_SHARE_EXTENSION
    static func register(queue: BatchQueueStore) {
        if ProcessInfo.processInfo.arguments.contains("-processingQueueSnapshotProbe") {
            let rows: [[String: Any]] = queue.jobs.map { job in
                ["job": job.id.uuidString,
                 "session": (job.executionSessionID ?? job.id).uuidString,
                 "intake": job.intakeRequestID?.uuidString ?? "",
                 "state": String(describing: job.state),
                 "historyDeleted": job.historyDeletedAt != nil,
                 "descriptionEnabled": job.configuration.shouldWritePhotoDescription,
                 "customDescriptionEnabled": job.configuration.usesCustomMemoryWriteText,
                 "customDescriptionLength": job.configuration.customMemoryWriteText.count,
                 "customDescriptionDigest": ProcessingIdentity.digest(Data(job.configuration.customMemoryWriteText.utf8)),
                 "descriptionOverrideLength": job.configuration.photoDescriptionOverride.count,

                 "tasks": job.tasks.map { task -> [String: Any] in
                     ["id": task.id.uuidString, "phase": String(describing: task.phase),
                      "source": task.sourceIdentifier ?? "",
                      "saved": task.savedAssetIdentifier ?? "",
                      "updatedAt": job.updatedAt.timeIntervalSince1970]
                 }]
            }
            defaults.set(["timestamp": Date().timeIntervalSince1970, "jobs": rows],
                         forKey: "processingQueueSnapshotProbe")
            defaults.synchronize()
        }
        if ProcessInfo.processInfo.arguments.contains("-processingSourceVersionProbe") {
            Task { @MainActor in
                let options = PHFetchOptions()
                options.predicate = NSPredicate(format: "title == %@", "MemoMark QA Inputs")
                guard let album = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options).firstObject else { return }
                let assets = PHAsset.fetchAssets(in: album, options: nil)
                var versions: [String: String] = [:]
                for index in 0..<assets.count {
                    let identifier = assets.object(at: index).localIdentifier
                    do { versions[identifier] = try await ProcessingSourceVersionResolver.version(for: identifier) ?? "unresolved" }
                    catch { versions[identifier] = "error" }
                }
                defaults.set(versions, forKey: "processingSourceVersionProbe")
                defaults.synchronize()
            }
        }
        if ProcessInfo.processInfo.arguments.contains("-processingReliabilityDiagnostics") {
            Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            let rows: [[String: String]] = queue.jobs.flatMap { job in
                job.tasks.map { task in
                    ["job": job.id.uuidString, "task": task.id.uuidString,
                     "phase": String(describing: task.phase),
                     "sourceExtension": task.sourceURL.pathExtension,
                     "sourceIdentifier": task.sourceIdentifier ?? "",
                     "source": task.processingIdentity?.sourceDigest ?? "legacy",
                     "semantics": task.processingIdentity?.semanticsDigest ?? "legacy",
                     "savedAsset": task.savedAssetIdentifier ?? "",
                     "captureDate": task.captureDate.map { String($0.timeIntervalSince1970) } ?? ""]
                }
            }
            let snapshots = queue.jobs.sorted { $0.updatedAt > $1.updatedAt }.prefix(3)
                .compactMap { try? ProcessingIdentity.canonicalSemantics(JSONEncoder().encode($0.configuration)) }
            defaults.set(snapshots, forKey: "processingReliabilitySemantics")
            defaults.set(rows, forKey: "processingReliabilityDiagnostics")
            defaults.synchronize()
            }
        }
        let hostQueueProbe = ProcessInfo.processInfo.arguments.contains("-continuedHostQueueProbe")
        if !ProcessInfo.processInfo.arguments.contains("-continuedHostUniqueQueueProbe") {
            defaults.removeObject(forKey: hostQueueIdentifierKey)
        }
        if hostQueueProbe {
            defaults.set(Date().addingTimeInterval(600).timeIntervalSince1970, forKey: hostQueueUntilKey)
        } else {
            defaults.removeObject(forKey: hostQueueUntilKey)
        }
        if hostQueueProbe || ProcessInfo.processInfo.arguments.contains("-continuedHostHandoffProbe") {
            let deadline = Date().addingTimeInterval(600).timeIntervalSince1970
            defaults.set(deadline, forKey: enabledUntilKey)
            defaults.set(deadline, forKey: hostHandoffUntilKey)
            defaults.removeObject(forKey: productionEnabledUntilKey)
        } else {
            defaults.removeObject(forKey: hostHandoffUntilKey)
        }
        if ProcessInfo.processInfo.arguments.contains("-continuedProductionPipelineProbe") {
            let deadline = Date().addingTimeInterval(600).timeIntervalSince1970
            defaults.set(deadline, forKey: enabledUntilKey)
            defaults.set(deadline, forKey: productionEnabledUntilKey)
            defaults.synchronize()
        }
        let arguments = ProcessInfo.processInfo.arguments
        MemoMarkBackgroundProbe.record("host.continuedProbeLaunchFlags",
            detail: "production=\(arguments.contains("-continuedProductionPipelineProbe"));disable=\(arguments.contains("-disableContinuedProcessingSpike"))")
        if arguments.contains("-uiTesting"), arguments.contains("-continuedProductionPipelineProbe"),
           let index = arguments.firstIndex(of: "-continuedPhotoDescriptionOverrideProbe"),
           arguments.indices.contains(index + 1), !arguments[index + 1].isEmpty,
           arguments[index + 1].count <= 64 {
            defaults.set(arguments[index + 1], forKey: descriptionProbeValueKey)
        } else {
            defaults.removeObject(forKey: descriptionProbeValueKey)
        }
        if ProcessInfo.processInfo.arguments.contains("-continuedProcessingSpike") {
            defaults.set(Date().addingTimeInterval(3600).timeIntervalSince1970, forKey: enabledUntilKey)
        }
        if ProcessInfo.processInfo.arguments.contains("-disableContinuedProcessingSpike") {
            defaults.removeObject(forKey: hostQueueUntilKey)
            defaults.removeObject(forKey: hostHandoffUntilKey)
            defaults.removeObject(forKey: productionEnabledUntilKey)
            defaults.removeObject(forKey: enabledUntilKey)
            // Cancel only this development probe, preserving production recovery.
            for (key, value) in defaults.dictionaryRepresentation()
            where key.hasPrefix(evidenceKey + ".") && key.hasSuffix(".submitted") {
                guard let event = value as? [String: Any],
                      let identifier = event["identifier"] as? String,
                      identifier.hasPrefix(identifierPrefix + ".") else { continue }
                BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
                record("cancelRequested", identifier: identifier)
            }
            defaults.synchronize()
        }
        // Restore the same concrete registration after process relaunch. A fresh
        // UUID here cannot match a task submitted before the host was restarted.
        let markerIdentifier = (ProcessInfo.processInfo.arguments.contains("-continuedProcessingForegroundProbe")
            ? nil : defaults.string(forKey: nextMarkerKey))
            ?? identifierPrefix + "." + UUID().uuidString
        defaults.set(markerIdentifier, forKey: nextMarkerKey)
        defaults.synchronize()
        let registered = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: markerIdentifier, using: nil
        ) { task in
            Task { @MainActor in
                record("hostCallback", identifier: task.identifier)
                guard let task = task as? BGContinuedProcessingTask else {
                    record("unexpectedTaskType", identifier: task.identifier)
                    task.setTaskCompleted(success: false)
                    return
                }
                task.progress.totalUnitCount = 1
                let operation = Task { @MainActor in
                    guard !Task.isCancelled,
                          let marker = defaults.string(forKey: task.identifier) else {
                        task.setTaskCompleted(success: false)
                        return
                    }
                    defaults.set(marker, forKey: task.identifier + ".acknowledged")
                    defaults.synchronize()
                    let verified = defaults.string(forKey: task.identifier + ".acknowledged") == marker
                    if verified { task.progress.completedUnitCount = 1 }
                    record(verified ? "markerCompleted" : "markerFailed", identifier: task.identifier)
                    task.setTaskCompleted(success: verified && !Task.isCancelled)
                }
                task.expirationHandler = { operation.cancel() }
                await operation.value
            }
        }
        record(registered ? "registered" : "registrationRejected", identifier: markerIdentifier)
        if ProcessInfo.processInfo.arguments.contains("-continuedProcessingForegroundProbe") {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                _ = await submitMarker(requestID: UUID())
            }
        }
    }
#endif
}
#endif
