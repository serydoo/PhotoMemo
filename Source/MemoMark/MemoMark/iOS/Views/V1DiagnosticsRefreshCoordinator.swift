#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct DiagnosticsRefreshState:
    Equatable {

    let snapshot:
        MemoMarkiOSProcessingDiagnosticsSnapshot

    let events:
        [MemoMarkShareDiagnosticEvent]
}

struct DiagnosticsRefreshCoordinator {

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
                    Task { @MainActor in
                        await backgroundStatusService
                            .clearCompletedHistory()
                    }
                    return
                }

                Task { @MainActor in
                    _ = await ClearCompletedQueueHistoryIntent(
                        preservingJobID:
                            preservingJobID,
                        coordinator:
                            queueCoordinator
                    )
                    .execute()
                }
            }
        )
    }

    func shareDiagnosticsState()
    -> DiagnosticsRefreshState {
        let snapshot =
            loadSnapshot()

        return state(
            from: snapshot
        )
    }

    func refreshedState()
    -> DiagnosticsRefreshState {
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
    ) -> DiagnosticsRefreshState {
        DiagnosticsRefreshState(
            snapshot: snapshot,
            events: snapshot.events
        )
    }
}
#endif
