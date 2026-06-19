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
}
