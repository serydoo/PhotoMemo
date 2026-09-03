import Foundation

struct SharedBatchConfigurationSnapshotService {

    private let snapshotProvider:
        BatchConfigurationSnapshotProvider

    init(
        defaults: UserDefaults =
            MemoMarkSharedContainer
            .sharedUserDefaults
    ) {
        self.snapshotProvider =
            BatchConfigurationSnapshotProvider(
                defaults: defaults
            )
    }

    func loadSnapshot() -> BatchConfigurationSnapshot {

        snapshotProvider.loadSnapshot()
    }

    func loadConfigurationReadiness()
    -> SavedConfigurationReadiness {

        snapshotProvider
            .loadConfigurationReadiness()
    }

    @available(*, deprecated, message: "Use loadConfigurationReadiness() instead.")
    func loadV1ConfigurationReadiness()
    -> SavedConfigurationReadiness {
        loadConfigurationReadiness()
    }

    func loadAnchorsResult()
    -> MemoMarkSharedDefaultsReadResult<
        [Anchor]
    > {

        snapshotProvider.loadAnchorsResult()
    }

    func loadTemplateResult()
    -> MemoMarkSharedDefaultsReadResult<
        Template
    > {

        snapshotProvider.loadTemplateResult()
    }

    func loadBadgeResult()
    -> MemoMarkSharedDefaultsReadResult<
        Badge
    > {

        snapshotProvider.loadBadgeResult()
    }

    func resolvedAlbumTitle(
        for identifier: String
    ) -> String? {

        snapshotProvider.resolvedAlbumTitle(
            for: identifier
        )
    }
}
