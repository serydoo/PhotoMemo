#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Application boundary for the queue execution loop. It exposes only the
/// current durable projection needed to select and run a task; media
/// coordination never receives the observable queue facade itself.
@MainActor
protocol BatchQueueProcessingRuntime:
    BatchTaskExecutionRuntime {

    var canContinueProcessing: Bool { get }

    func markProcessingStarted()

    func nextPendingTaskReference()
    -> BatchTaskReference?

    func processingTask(
        at reference: BatchTaskReference
    ) -> BatchTask?

    func processingConfiguration(
        at reference: BatchTaskReference
    ) -> BatchConfigurationSnapshot?

    func processingLoopDidFinish(
        shouldRestart: Bool
    ) async
}

extension BatchQueueStore: BatchQueueProcessingRuntime {

    func processingTask(
        at reference: BatchTaskReference
    ) -> BatchTask? {

        currentTask(at: reference)
    }

    func processingConfiguration(
        at reference: BatchTaskReference
    ) -> BatchConfigurationSnapshot? {

        currentJob(at: reference)?.configuration
    }
}
#endif
