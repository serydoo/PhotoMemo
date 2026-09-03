#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Reads the already-established configuration bootstrap representation.
///
/// This transaction deliberately does not choose presentation fallback. A
/// missing or unreadable store remains visible to the Bootstrap Adapter, which
/// owns the existing safe default-state projection for the Configuration
/// Center.
@MainActor
struct LoadConfigurationBootstrapTransaction {

    private let loadBootstrapState:
        () -> MemoMarkResult<ConfigurationBootstrapState>

    init(
        loadBootstrapState: @escaping () -> MemoMarkResult<
            ConfigurationBootstrapState
        >
    ) {
        self.loadBootstrapState = loadBootstrapState
    }

    init(
        settingsRepository: SettingsRepository
    ) {
        self.init(
            loadBootstrapState: {
                .success(
                    settingsRepository
                        .loadConfigurationBootstrapState()
                )
            }
        )
    }

    init(
        configurationCoordinator: ConfigurationCoordinator?
    ) {
        self.init(
            loadBootstrapState: {
                guard let configurationCoordinator else {
                    return .failure(
                        MemoMarkError(
                            code: .configurationUnavailable,
                            message: "Configuration bootstrap is unavailable without an active configuration coordinator."
                        )
                    )
                }
                return configurationCoordinator
                    .loadConfigurationBootstrapState()
            }
        )
    }

    func apply() -> MemoMarkResult<ConfigurationBootstrapState> {
        loadBootstrapState()
    }
}
#endif
