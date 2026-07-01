#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct RefreshQueueProcessingStatusIntent:
    PhotoMemoIntent {

    let refreshExternalIntake:
        () -> Void

    let diagnosticsRepository:
        DiagnosticsRepository

    func execute()
    async -> PhotoMemoResult<
        PhotoMemoiOSProcessingDiagnosticsSnapshot
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> PhotoMemoResult<
        PhotoMemoiOSProcessingDiagnosticsSnapshot
    > {

        refreshExternalIntake()

        return diagnosticsRepository
            .loadProcessingDiagnosticsSnapshot()
    }
}

struct LoadQueueProcessingDiagnosticsSnapshotIntent:
    PhotoMemoIntent {

    let loadFromRepository:
        (() -> PhotoMemoResult<
            PhotoMemoiOSProcessingDiagnosticsSnapshot
        >)?

    let fallbackLoad:
        () -> PhotoMemoiOSProcessingDiagnosticsSnapshot

    init(
        diagnosticsRepository:
            DiagnosticsRepository?,
        fallbackLoad: @escaping () ->
            PhotoMemoiOSProcessingDiagnosticsSnapshot = {
                PhotoMemoiOSProcessingDiagnosticsSnapshot
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
            (() -> PhotoMemoResult<
                PhotoMemoiOSProcessingDiagnosticsSnapshot
            >)? = nil,
        fallbackLoad: @escaping () ->
            PhotoMemoiOSProcessingDiagnosticsSnapshot
    ) {
        self.loadFromRepository =
            loadFromRepository
        self.fallbackLoad =
            fallbackLoad
    }

    func execute()
    async -> PhotoMemoResult<
        PhotoMemoiOSProcessingDiagnosticsSnapshot
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> PhotoMemoResult<
        PhotoMemoiOSProcessingDiagnosticsSnapshot
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
    PhotoMemoIntent {

    let preservingJobID: UUID?

    let coordinator:
        QueueCoordinator

    func execute()
    async -> PhotoMemoResult<
        Void
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> PhotoMemoResult<
        Void
    > {

        coordinator
            .clearCompletedHistory(
                preserving: preservingJobID
            )
    }
}
#endif
