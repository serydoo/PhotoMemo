#if !PHOTOMEMO_SHARE_EXTENSION
import Testing
@testable import PhotoMemo

@Suite("Background queue preparation result")
struct BackgroundQueuePreparationResultTests {

    @Test("Only prepared and empty results may complete normally")
    func normalCompletionPolicy() {
        #expect(BackgroundQueuePreparationResult.prepared.canRunQueue)
        #expect(BackgroundQueuePreparationResult.preparedRequiringRetry.canRunQueue)
        #expect(BackgroundQueuePreparationResult.nothingToProcess.canRunQueue)
        #expect(!BackgroundQueuePreparationResult.retryableFailure.canRunQueue)
        #expect(!BackgroundQueuePreparationResult.permanentFailure.canRunQueue)
        #expect(BackgroundQueuePreparationResult.prepared.runResultWithoutProcessing == nil)
        #expect(
            BackgroundQueuePreparationResult
                .preparedRequiringRetry
                .runResultWithoutProcessing == nil
        )
        #expect(BackgroundQueuePreparationResult.nothingToProcess.runResultWithoutProcessing == .completed)
        #expect(BackgroundQueuePreparationResult.retryableFailure.runResultWithoutProcessing == .retryScheduled)
        #expect(BackgroundQueuePreparationResult.permanentFailure.runResultWithoutProcessing == .requiresUserAction)
        #expect(
            BackgroundQueuePreparationResult
                .preparedRequiringRetry
                .requiresRetryAfterProcessing
        )
    }

    @Test("Preparation counts distinguish empty, prepared, and retryable outcomes")
    func countResolutionPolicy() {
        #expect(
            BackgroundQueuePreparationResult.resolve(
                enqueuedRequestCount: 0,
                failedRequestCount: 0,
                pendingTaskCount: 0
            ) == .nothingToProcess
        )
        #expect(
            BackgroundQueuePreparationResult.resolve(
                enqueuedRequestCount: 1,
                failedRequestCount: 0,
                pendingTaskCount: 1
            ) == .prepared
        )
        #expect(
            BackgroundQueuePreparationResult.resolve(
                enqueuedRequestCount: 1,
                failedRequestCount: 1,
                pendingTaskCount: 1
            ) == .preparedRequiringRetry
        )
        #expect(
            BackgroundQueuePreparationResult.resolve(
                enqueuedRequestCount: 0,
                failedRequestCount: 0,
                pendingTaskCount: 1
            ) == .prepared
        )
        #expect(
            BackgroundQueuePreparationResult.resolve(
                enqueuedRequestCount: 0,
                failedRequestCount: 1,
                pendingTaskCount: 0
            ) == .retryableFailure
        )
    }
}
#endif
