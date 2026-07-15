#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

@MainActor
struct BatchTaskExecutionContext {
    let taskReference: BatchQueueExecution.TaskReference
    let taskSnapshot: BatchTask
    let configuration: BatchConfigurationSnapshot?
    let memoryBudget: MediaMemoryBudget
    let route: String
    let totalProgressUnits: Int
    let startedAt: Date

    let renderHealthValidator:
        @MainActor (RecordCard, BatchConfigurationSnapshot) throws -> [CardTextBlock]
}

@MainActor
final class BatchTaskProcessor {
    typealias Handler = @MainActor (BatchTaskExecutionContext, BatchQueueStore) async -> Void

    private let handler: Handler

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    func process(context: BatchTaskExecutionContext, in store: BatchQueueStore) async {
        await handler(context, store)
    }
}
#endif
