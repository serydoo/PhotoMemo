#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import Foundation
import Photos

@MainActor
final class BackgroundBatchQueueWorker {

    private let queueRuntime: any BackgroundQueueRuntime
    private let prepareQueue:
        @MainActor () async -> BackgroundQueuePreparationResult
    private let hasPhotoLibraryAuthorization: () -> Bool
    private var cancellationRequested = false

    init(
        queueRuntime: any BackgroundQueueRuntime,
        prepareQueue: @escaping @MainActor () async -> BackgroundQueuePreparationResult,
        hasPhotoLibraryAuthorization: @escaping () -> Bool = {
            let status = PHPhotoLibrary.authorizationStatus(
                for: .readWrite
            )
            return status == .authorized || status == .limited
        }
    ) {
        self.queueRuntime = queueRuntime
        self.prepareQueue = prepareQueue
        self.hasPhotoLibraryAuthorization =
            hasPhotoLibraryAuthorization
    }

    func run() async -> BackgroundQueueRunResult {
        cancellationRequested = false

        let preparationResult = await prepareQueue()
        if let runResult =
            preparationResult.runResultWithoutProcessing {
            return runResult
        }
        guard hasPhotoLibraryAuthorization() else {
            return .requiresUserAction
        }

        await queueRuntime.startProcessingIfNeeded()
        while queueRuntime.isProcessing {
            guard !Task.isCancelled,
                  !cancellationRequested else {
                await queueRuntime
                    .stopProcessingForBackgroundExpiration()
                return .retryScheduled
            }
            try? await Task.sleep(
                for: .milliseconds(250)
            )
        }

        return BackgroundQueueRunResult.resolve(
            cancellationRequested: cancellationRequested,
            retryRequested:
                preparationResult
                .requiresRetryAfterProcessing,
            pendingTaskCount: queueRuntime.pendingTaskCount
        )
    }

    func cancel() async {
        cancellationRequested = true
        await queueRuntime
            .stopProcessingForBackgroundExpiration()
    }
}
#endif
