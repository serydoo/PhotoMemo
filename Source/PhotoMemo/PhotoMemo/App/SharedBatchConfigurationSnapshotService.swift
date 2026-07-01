import Foundation

struct SharedBatchConfigurationSnapshotService {

    private let snapshotProvider:
        BatchConfigurationSnapshotProvider

    init(
        defaults: UserDefaults =
            PhotoMemoSharedContainer
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

    func loadAnchorsResult()
    -> PhotoMemoSharedDefaultsReadResult<
        [Anchor]
    > {

        snapshotProvider.loadAnchorsResult()
    }

    func loadTemplateResult()
    -> PhotoMemoSharedDefaultsReadResult<
        Template
    > {

        snapshotProvider.loadTemplateResult()
    }

    func loadBadgeResult()
    -> PhotoMemoSharedDefaultsReadResult<
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
