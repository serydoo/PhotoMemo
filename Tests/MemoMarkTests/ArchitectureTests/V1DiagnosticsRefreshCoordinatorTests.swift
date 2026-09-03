#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("V1 diagnostics refresh coordinator")
struct V1DiagnosticsRefreshCoordinatorTests {

    @Test("shareDiagnosticsState projects events from the loaded snapshot")
    func shareDiagnosticsStateProjectsEventsFromTheLoadedSnapshot() {
        let event =
            MemoMarkShareDiagnosticEvent(
                stage: .appDrain,
                message: "loaded"
            )
        let snapshot =
            MemoMarkiOSProcessingDiagnosticsSnapshot(
                events: [event],
                shareDiagnosticsAvailability: .available
            )

        let coordinator =
            DiagnosticsRefreshCoordinator(
                loadSnapshot: {
                    snapshot
                },
                refreshSnapshot: {
                    .success(snapshot)
                },
                clearCompletedHistory: { _ in }
            )

        let state =
            coordinator
            .shareDiagnosticsState()

        #expect(state.snapshot == snapshot)
        #expect(state.events == [event])
    }

    @Test("refreshedState prefers refreshed repository-backed snapshot")
    func refreshedStatePrefersRepositoryBackedSnapshot() {
        let refreshedEvent =
            MemoMarkShareDiagnosticEvent(
                stage: .appEnqueueCreated,
                message: "refreshed"
            )
        let refreshedSnapshot =
            MemoMarkiOSProcessingDiagnosticsSnapshot(
                events: [refreshedEvent],
                shareDiagnosticsAvailability: .available
            )
        var refreshCount = 0

        let coordinator =
            DiagnosticsRefreshCoordinator(
                loadSnapshot: {
                    MemoMarkiOSProcessingDiagnosticsSnapshot()
                },
                refreshSnapshot: {
                    refreshCount += 1
                    return .success(
                        refreshedSnapshot
                    )
                },
                clearCompletedHistory: { _ in }
            )

        let state =
            coordinator
            .refreshedState()

        #expect(refreshCount == 1)
        #expect(
            state.snapshot
            == refreshedSnapshot
        )
        #expect(
            state.events == [refreshedEvent]
        )
    }

    @Test("refreshedState falls back to share diagnostics state on refresh failure")
    func refreshedStateFallsBackToShareDiagnosticsStateOnRefreshFailure() {
        let fallbackEvent =
            MemoMarkShareDiagnosticEvent(
                stage: .appRequestValidated,
                message: "fallback"
            )
        let fallbackSnapshot =
            MemoMarkiOSProcessingDiagnosticsSnapshot(
                events: [fallbackEvent],
                shareDiagnosticsAvailability: .available
            )

        let coordinator =
            DiagnosticsRefreshCoordinator(
                loadSnapshot: {
                    fallbackSnapshot
                },
                refreshSnapshot: {
                    .failure(
                        MemoMarkError(
                            code: .unexpected,
                            message: "refresh failed"
                        )
                    )
                },
                clearCompletedHistory: { _ in }
            )

        let state =
            coordinator
            .refreshedState()

        #expect(
            state.snapshot
            == fallbackSnapshot
        )
        #expect(
            state.events == [fallbackEvent]
        )
    }

    @Test("clearCompletedQueueHistory preserves the active job identifier")
    func clearCompletedQueueHistoryPreservesTheActiveJobIdentifier() {
        let preservedJobID =
            UUID()
        var receivedJobID: UUID?

        let coordinator =
            DiagnosticsRefreshCoordinator(
                loadSnapshot: {
                    MemoMarkiOSProcessingDiagnosticsSnapshot()
                },
                refreshSnapshot: {
                    .success(
                        MemoMarkiOSProcessingDiagnosticsSnapshot()
                    )
                },
                clearCompletedHistory: {
                    receivedJobID = $0
                }
            )

        coordinator.clearCompletedQueueHistory(
            preservingJobID: preservedJobID
        )

        #expect(
            receivedJobID
            == preservedJobID
        )
    }
}
#endif
