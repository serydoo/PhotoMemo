#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Reads the canonical durable configuration after a successful save so an
/// intake request receives one immutable production snapshot rather than a
/// view-created settings service.
@MainActor
struct LoadProductionConfigurationSnapshotTransaction {

    private let loadSnapshot:
        () -> BatchConfigurationSnapshot

    init(
        loadSnapshot: @escaping () -> BatchConfigurationSnapshot
    ) {
        self.loadSnapshot =
            loadSnapshot
    }

    init(
        configurationRepository:
            ConfigurationRepository
    ) {
        self.init(
            loadSnapshot: {
                configurationRepository
                    .loadDefaultBatchConfigurationSnapshot()
            }
        )
    }

    func apply() -> BatchConfigurationSnapshot {
        loadSnapshot()
    }
}
#endif
