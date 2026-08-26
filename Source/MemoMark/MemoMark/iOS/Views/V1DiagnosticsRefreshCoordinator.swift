#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct V1DiagnosticsRefreshState:
    Equatable {

    let snapshot:
        MemoMarkiOSProcessingDiagnosticsSnapshot

    let events:
        [MemoMarkShareDiagnosticEvent]
}

struct V1DiagnosticsRefreshCoordinator {

    private let loadSnapshot:
        () -> MemoMarkiOSProcessingDiagnosticsSnapshot

    private let refreshSnapshot:
        () -> MemoMarkResult<
            MemoMarkiOSProcessingDiagnosticsSnapshot
        >

    private let clearCompletedHistory:
        (UUID?) -> Void

    init(
        loadSnapshot: @escaping () ->
            MemoMarkiOSProcessingDiagnosticsSnapshot,
        refreshSnapshot: @escaping () ->
            MemoMarkResult<
                MemoMarkiOSProcessingDiagnosticsSnapshot
            >,
        clearCompletedHistory: @escaping (UUID?) -> Void
    ) {
        self.loadSnapshot =
            loadSnapshot
        self.refreshSnapshot =
            refreshSnapshot
        self.clearCompletedHistory =
            clearCompletedHistory
    }

    init(
        refreshExternalIntake:
            @escaping () -> Void,
        diagnosticsRepository:
            DiagnosticsRepository?,
        backgroundStatusService:
            MemoMarkBackgroundStatusService,
        queueCoordinator:
            QueueCoordinator?
    ) {
        self.init(
            loadSnapshot: {
                switch LoadQueueProcessingDiagnosticsSnapshotIntent(
                    diagnosticsRepository:
                        diagnosticsRepository
                )
                .executeSynchronously() {
                case .success(let snapshot):
                    return snapshot
                case .failure:
                    return MemoMarkiOSProcessingDiagnosticsSnapshot
                        .load()
                }
            },
            refreshSnapshot: {
                if let diagnosticsRepository {
                    return RefreshQueueProcessingStatusIntent(
                        refreshExternalIntake:
                            refreshExternalIntake,
                        diagnosticsRepository:
                            diagnosticsRepository
                    )
                    .executeSynchronously()
                }

                refreshExternalIntake()

                return .success(
                    MemoMarkiOSProcessingDiagnosticsSnapshot
                        .load()
                )
            },
            clearCompletedHistory: {
                preservingJobID in
                guard let queueCoordinator else {
                    backgroundStatusService
                        .clearCompletedHistory()
                    return
                }

                _ =
                    ClearCompletedQueueHistoryIntent(
                        preservingJobID:
                            preservingJobID,
                        coordinator:
                            queueCoordinator
                    )
                    .executeSynchronously()
            }
        )
    }

    func shareDiagnosticsState()
    -> V1DiagnosticsRefreshState {
        let snapshot =
            loadSnapshot()

        return state(
            from: snapshot
        )
    }

    func refreshedState()
    -> V1DiagnosticsRefreshState {
        switch refreshSnapshot() {
        case .success(let snapshot):
            return state(
                from: snapshot
            )
        case .failure:
            return shareDiagnosticsState()
        }
    }

    func clearCompletedQueueHistory(
        preservingJobID: UUID?
    ) {
        clearCompletedHistory(
            preservingJobID
        )
    }

    private func state(
        from snapshot:
            MemoMarkiOSProcessingDiagnosticsSnapshot
    ) -> V1DiagnosticsRefreshState {
        V1DiagnosticsRefreshState(
            snapshot: snapshot,
            events: snapshot.events
        )
    }
}
#endif
