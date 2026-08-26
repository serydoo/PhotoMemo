#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct RefreshQueueProcessingStatusIntent:
    MemoMarkIntent {

    let refreshExternalIntake:
        () -> Void

    let diagnosticsRepository:
        DiagnosticsRepository

    func execute()
    async -> MemoMarkResult<
        MemoMarkiOSProcessingDiagnosticsSnapshot
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> MemoMarkResult<
        MemoMarkiOSProcessingDiagnosticsSnapshot
    > {

        refreshExternalIntake()

        return diagnosticsRepository
            .loadProcessingDiagnosticsSnapshot()
    }
}

struct LoadQueueProcessingDiagnosticsSnapshotIntent:
    MemoMarkIntent {

    let loadFromRepository:
        (() -> MemoMarkResult<
            MemoMarkiOSProcessingDiagnosticsSnapshot
        >)?

    let fallbackLoad:
        () -> MemoMarkiOSProcessingDiagnosticsSnapshot

    init(
        diagnosticsRepository:
            DiagnosticsRepository?,
        fallbackLoad: @escaping () ->
            MemoMarkiOSProcessingDiagnosticsSnapshot = {
                MemoMarkiOSProcessingDiagnosticsSnapshot
                    .load()
            }
    ) {
        self.init(
            loadFromRepository:
                diagnosticsRepository.map { repository in
                    {
                        repository
                            .loadProcessingDiagnosticsSnapshot()
                    }
                },
            fallbackLoad: fallbackLoad
        )
    }

    init(
        loadFromRepository:
            (() -> MemoMarkResult<
                MemoMarkiOSProcessingDiagnosticsSnapshot
            >)? = nil,
        fallbackLoad: @escaping () ->
            MemoMarkiOSProcessingDiagnosticsSnapshot
    ) {
        self.loadFromRepository =
            loadFromRepository
        self.fallbackLoad =
            fallbackLoad
    }

    func execute()
    async -> MemoMarkResult<
        MemoMarkiOSProcessingDiagnosticsSnapshot
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> MemoMarkResult<
        MemoMarkiOSProcessingDiagnosticsSnapshot
    > {

        guard let loadFromRepository else {
            return .success(
                fallbackLoad()
            )
        }

        switch loadFromRepository() {
        case .success(let snapshot):
            return .success(snapshot)
        case .failure:
            return .success(
                fallbackLoad()
            )
        }
    }
}

struct ClearCompletedQueueHistoryIntent:
    MemoMarkIntent {

    let preservingJobID: UUID?

    let coordinator:
        QueueCoordinator

    func execute()
    async -> MemoMarkResult<
        Void
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> MemoMarkResult<
        Void
    > {

        coordinator
            .clearCompletedHistory(
                preserving: preservingJobID
            )
    }
}
#endif
