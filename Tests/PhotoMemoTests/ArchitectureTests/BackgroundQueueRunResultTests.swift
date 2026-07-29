#if !PHOTOMEMO_SHARE_EXTENSION
import Testing
@testable import PhotoMemo

@Suite("Background queue run result")
struct BackgroundQueueRunResultTests {

    @Test("Only completed work succeeds the system task")
    func systemCompletionPolicy() {
        #expect(BackgroundQueueRunResult.completed.systemTaskSucceeded)
        #expect(!BackgroundQueueRunResult.retryScheduled.systemTaskSucceeded)
        #expect(!BackgroundQueueRunResult.requiresUserAction.systemTaskSucceeded)
    }

    @Test("Cancellation always schedules a retry")
    func cancellationCompletionPolicy() {
        #expect(
            BackgroundQueueRunResult.resolve(
                cancellationRequested: true,
                retryRequested: false,
                pendingTaskCount: 0
            ) == .retryScheduled
        )
        #expect(
            BackgroundQueueRunResult.resolve(
                cancellationRequested: false,
                retryRequested: false,
                pendingTaskCount: 0
            ) == .completed
        )
        #expect(
            BackgroundQueueRunResult.resolve(
                cancellationRequested: false,
                retryRequested: false,
                pendingTaskCount: 1
            ) == .retryScheduled
        )
        #expect(
            BackgroundQueueRunResult.resolve(
                cancellationRequested: false,
                retryRequested: true,
                pendingTaskCount: 0
            ) == .retryScheduled
        )
    }
}
#endif
