#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1ConfigurationBootstrapCoordinator {

    private let loadFromCoordinator:
        (() -> PhotoMemoResult<
            V1ConfigurationBootstrapState
        >)?

    private let fallbackLoad:
        () -> V1ConfigurationBootstrapState

    init(
        loadFromCoordinator:
            (() -> PhotoMemoResult<
                V1ConfigurationBootstrapState
            >)? = nil,
        fallbackLoad: @escaping () ->
            V1ConfigurationBootstrapState
    ) {
        self.loadFromCoordinator =
            loadFromCoordinator
        self.fallbackLoad =
            fallbackLoad
    }

    init(
        configurationCoordinator:
            ConfigurationCoordinator?
    ) {
        self.init(
            loadFromCoordinator:
                configurationCoordinator.map {
                    coordinator in
                    {
                        LoadV1ConfigurationBootstrapIntent(
                            coordinator:
                                coordinator
                        )
                        .executeSynchronously()
                    }
                },
            fallbackLoad: {
                V1ConfigurationBootstrapState(
                    customLogoBadge: nil,
                    logoMode: .appleMini,
                    outputTarget: .automatic,
                    mediaOutputMode:
                        .originalFormat,
                    selectedExistingAlbumIdentifier:
                        "",
                    suggestedNewAlbumName: nil
                )
            }
        )
    }

    func loadState()
    -> V1ConfigurationBootstrapState {
        guard let loadFromCoordinator else {
            return fallbackLoad()
        }

        switch loadFromCoordinator() {
        case .success(let state):
            return state
        case .failure:
            return fallbackLoad()
        }
    }
}
#endif
