#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 diagnostics refresh coordinator")
struct V1DiagnosticsRefreshCoordinatorTests {

    @Test("shareDiagnosticsState projects events from the loaded snapshot")
    func shareDiagnosticsStateProjectsEventsFromTheLoadedSnapshot() {
        let event =
            PhotoMemoShareDiagnosticEvent(
                stage: .appDrain,
                message: "loaded"
            )
        let snapshot =
            PhotoMemoiOSProcessingDiagnosticsSnapshot(
                events: [event],
                shareDiagnosticsAvailability: .available
            )

        let coordinator =
            V1DiagnosticsRefreshCoordinator(
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
            PhotoMemoShareDiagnosticEvent(
                stage: .appEnqueueCreated,
                message: "refreshed"
            )
        let refreshedSnapshot =
            PhotoMemoiOSProcessingDiagnosticsSnapshot(
                events: [refreshedEvent],
                shareDiagnosticsAvailability: .available
            )
        var refreshCount = 0

        let coordinator =
            V1DiagnosticsRefreshCoordinator(
                loadSnapshot: {
                    PhotoMemoiOSProcessingDiagnosticsSnapshot()
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
            PhotoMemoShareDiagnosticEvent(
                stage: .appRequestValidated,
                message: "fallback"
            )
        let fallbackSnapshot =
            PhotoMemoiOSProcessingDiagnosticsSnapshot(
                events: [fallbackEvent],
                shareDiagnosticsAvailability: .available
            )

        let coordinator =
            V1DiagnosticsRefreshCoordinator(
                loadSnapshot: {
                    fallbackSnapshot
                },
                refreshSnapshot: {
                    .failure(
                        PhotoMemoError(
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
            V1DiagnosticsRefreshCoordinator(
                loadSnapshot: {
                    PhotoMemoiOSProcessingDiagnosticsSnapshot()
                },
                refreshSnapshot: {
                    .success(
                        PhotoMemoiOSProcessingDiagnosticsSnapshot()
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
