#if os(iOS)
import BackgroundTasks
import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
@MainActor
final class PhotoMemoBackgroundTaskCoordinator {

    static let taskIdentifier = PhotoMemoBackgroundTaskSubmission.taskIdentifier
    private static var didRegister = false

    private let worker: BackgroundBatchQueueWorker

    init(
        batchQueueStore: BatchQueueStore,
        prepareQueue: @escaping @MainActor () -> BackgroundQueuePreparationResult
    ) {
        self.worker = BackgroundBatchQueueWorker(
            batchQueueStore: batchQueueStore,
            prepareQueue: prepareQueue
        )
    }

    func register() {
        guard !Self.didRegister else {
            return
        }
        Self.didRegister = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Task { @MainActor in
                guard let self else {
                    processingTask.setTaskCompleted(
                        success: false
                    )
                    return
                }
                await self.handle(processingTask)
            }
        }
    }

    func scheduleIfNeeded() {
        _ = PhotoMemoBackgroundTaskSubmission.submit()
    }

    private func handle(_ task: BGProcessingTask) async {
        task.expirationHandler = { [weak self] in
            Task { @MainActor in
                self?.worker.cancel()
            }
        }

        let result = await worker.run()
        if result == .retryScheduled {
            scheduleIfNeeded()
        }
        complete(task, with: result)
    }

    private func complete(
        _ task: BGProcessingTask,
        with result: BackgroundQueueRunResult
    ) {
        task.setTaskCompleted(
            success: result.systemTaskSucceeded
        )
    }

}
#endif
#endif
