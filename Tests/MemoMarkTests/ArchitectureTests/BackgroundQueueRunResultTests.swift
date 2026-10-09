#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Background queue run result")
struct BackgroundQueueRunResultTests {

    @Test("Only completed work succeeds the system task")
    func systemCompletionPolicy() {
        #expect(BackgroundQueueRunResult.completed.systemTaskSucceeded)
        #expect(!BackgroundQueueRunResult.retryScheduled.systemTaskSucceeded)
        #expect(!BackgroundQueueRunResult.requiresUserAction.systemTaskSucceeded)
        #expect(BackgroundQueueRunResult.paused.systemTaskSucceeded)
    }

    @Test("Native Continued Processing success requires an entirely completed nonempty session")
    @MainActor func continuedCompletionRequiresSavedWork() {
        let configuration = SettingsService().buildBatchConfigurationSnapshot()
        for phase in [BatchTaskPhase.completed, .failed, .cancelled, .queued] {
            let id = UUID()
            var job = BatchJob(title: "QA", configuration: configuration,
                tasks: [BatchTask(sourceURL: URL(fileURLWithPath: "/tmp/continued.jpg"), phase: phase)])
            job.executionSessionID = id
            let session = ExecutionSession(id: id, jobs: [job])
            #expect(BackgroundQueueRunResult.completed.continuedTaskSucceeded(session: session) == (phase == .completed))
            #expect(!BackgroundQueueRunResult.paused.continuedTaskSucceeded(session: session))
            #expect(!BackgroundQueueRunResult.retryScheduled.continuedTaskSucceeded(session: session))
        }
        #expect(!BackgroundQueueRunResult.completed.continuedTaskSucceeded(session: nil))
        #expect(!BackgroundQueueRunResult.completed.continuedTaskSucceeded(session: ExecutionSession(id: UUID(), jobs: [])))
    }

    @Test("Cancellation only schedules a retry when durable pending work remains")
    func cancellationCompletionPolicy() {
        #expect(
            BackgroundQueueRunResult.resolve(
                cancellationRequested: true,
                retryRequested: false,
                pendingTaskCount: 0
            ) == .completed
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
