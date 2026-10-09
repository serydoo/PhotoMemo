#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Photos

@MainActor
final class BackgroundBatchQueueWorker {

    private let queueRuntime: any BackgroundQueueRuntime
    private let prepareQueue:
        @MainActor () async -> BackgroundQueuePreparationResult
    private let hasPhotoLibraryAuthorization: () -> Bool
    private var cancellationRequested = false
    private var activeRunID: UUID?
    private var activeLease: ExecutionLease?

    init(
        queueRuntime: any BackgroundQueueRuntime,
        prepareQueue: @escaping @MainActor () async -> BackgroundQueuePreparationResult,
        hasPhotoLibraryAuthorization: @escaping () -> Bool = {
            // Receipt-confirmed processing needs readback, not merely add access.
            PhotoLibraryCapability.current.canReadVisibleAssets
        }
    ) {
        self.queueRuntime = queueRuntime
        self.prepareQueue = prepareQueue
        self.hasPhotoLibraryAuthorization =
            hasPhotoLibraryAuthorization
    }

    func run(runID: UUID = UUID(), owner: BackgroundExecutionOwner = .bgProcessing,
             progress: @escaping @MainActor (ExecutionSession?) -> Void = { _ in }) async -> BackgroundQueueRunResult {
        guard owner == .bgProcessing || owner == .continuedProcessing else { return .retryScheduled }
        guard !Task.isCancelled, activeRunID == nil,
              let lease = queueRuntime.reserveSystemExecution(owner: owner) else {
            return .retryScheduled
        }
        activeRunID = runID
        activeLease = lease
        cancellationRequested = false
        let result = await runReservedQueue(lease: lease, progress: progress)
        // Preparation can yield to cancellation or return an error after a
        // collaborator starts processing. Quiesce that work before surrendering its lease.
        if queueRuntime.isProcessing && (Task.isCancelled || cancellationRequested || result != .completed) {
            await queueRuntime.stopProcessingForBackgroundExpiration(lease: lease)
        }
        await queueRuntime.finishSystemExecution(lease)
        activeRunID = nil
        activeLease = nil
        return result
    }

    private func runReservedQueue(lease: ExecutionLease,
                                  progress: @MainActor (ExecutionSession?) -> Void) async -> BackgroundQueueRunResult {
#if DEBUG
        MemoMarkBackgroundProbe.record("bgProcessing.leaseAcquired")
#endif
        let preparationResult = await prepareQueue()
        progress(queueRuntime.backgroundExecutionSession)
#if DEBUG
        MemoMarkBackgroundProbe.record("bgProcessing.queuePrepared", detail: String(describing: preparationResult))
#endif
        if let runResult =
            preparationResult.runResultWithoutProcessing {
            return runResult
        }
        guard !queueRuntime.isProcessingPaused else {
            return .paused
        }
        guard queueRuntime.executablePendingTaskCount > 0 else {
            return queueRuntime.pendingTaskCount > 0 ? .paused : .completed
        }
        guard !Task.isCancelled, !cancellationRequested else { return .retryScheduled }
        guard hasPhotoLibraryAuthorization(), queueRuntime.canProcessPhotoLibraryDestinations else {
            return .requiresUserAction
        }

#if DEBUG
        MemoMarkBackgroundProbe.record("bgProcessing.processingStarted")
#endif
        await queueRuntime.startProcessingIfNeeded()
        while queueRuntime.isProcessing {
            progress(queueRuntime.backgroundExecutionSession)
            guard !Task.isCancelled,
                  !cancellationRequested else {
                await queueRuntime
                    .stopProcessingForBackgroundExpiration(lease: lease)
                return .retryScheduled
            }
            try? await Task.sleep(
                for: .milliseconds(250)
            )
        }

        progress(queueRuntime.backgroundExecutionSession)
        if queueRuntime.isProcessingPaused {
            return .paused
        }

        if queueRuntime.executablePendingTaskCount == 0, queueRuntime.pendingTaskCount > 0 {
            return .paused
        }
        return BackgroundQueueRunResult.resolve(
            cancellationRequested: cancellationRequested,
            retryRequested:
                preparationResult
                .requiresRetryAfterProcessing,
            pendingTaskCount: queueRuntime.executablePendingTaskCount
        )
    }

    func cancel(runID: UUID? = nil) async {
        if let runID, activeRunID != runID { return }
        guard let lease = activeLease else { return }
        cancellationRequested = true
        await queueRuntime.stopProcessingForBackgroundExpiration(lease: lease)
    }
}
#endif
