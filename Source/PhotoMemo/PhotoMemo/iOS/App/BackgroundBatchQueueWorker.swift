#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Photos

@MainActor
final class BackgroundBatchQueueWorker {

    private let batchQueueStore: BatchQueueStore
    private let prepareQueue:
        @MainActor () -> BackgroundQueuePreparationResult
    private let hasPhotoLibraryAuthorization: () -> Bool
    private var cancellationRequested = false

    init(
        batchQueueStore: BatchQueueStore,
        prepareQueue: @escaping @MainActor () -> BackgroundQueuePreparationResult,
        hasPhotoLibraryAuthorization: @escaping () -> Bool = {
            let status = PHPhotoLibrary.authorizationStatus(
                for: .readWrite
            )
            return status == .authorized || status == .limited
        }
    ) {
        self.batchQueueStore = batchQueueStore
        self.prepareQueue = prepareQueue
        self.hasPhotoLibraryAuthorization =
            hasPhotoLibraryAuthorization
    }

    func run() async -> BackgroundQueueRunResult {
        cancellationRequested = false

        let preparationResult = prepareQueue()
        if let runResult =
            preparationResult.runResultWithoutProcessing {
            return runResult
        }
        guard hasPhotoLibraryAuthorization() else {
            return .requiresUserAction
        }

        batchQueueStore.startProcessingIfNeeded()
        while batchQueueStore.isProcessing {
            guard !Task.isCancelled,
                  !cancellationRequested else {
                batchQueueStore
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
            pendingTaskCount: batchQueueStore.pendingTaskCount
        )
    }

    func cancel() {
        cancellationRequested = true
        batchQueueStore
            .stopProcessingForBackgroundExpiration()
    }
}
#endif
