#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct ConfigurationBootstrapCoordinator {

    private let loadFromCoordinator:
        (() -> MemoMarkResult<
            ConfigurationBootstrapState
        >)?

    private let fallbackLoad:
        () -> ConfigurationBootstrapState

    init(
        loadFromCoordinator:
            (() -> MemoMarkResult<
                ConfigurationBootstrapState
            >)? = nil,
        fallbackLoad: @escaping () ->
            ConfigurationBootstrapState
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
            loadTransaction:
                configurationCoordinator.map {
                    LoadConfigurationBootstrapTransaction(
                        configurationCoordinator: $0
                    )
                }
        )
    }

    init(
        loadTransaction:
            LoadConfigurationBootstrapTransaction?
    ) {
        self.init(
            loadFromCoordinator:
                loadTransaction.map { transaction in
                    { transaction.apply() }
                },
            fallbackLoad: {
                ConfigurationBootstrapState(
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
    -> ConfigurationBootstrapState {
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
