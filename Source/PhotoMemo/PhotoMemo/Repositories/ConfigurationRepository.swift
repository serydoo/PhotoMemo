#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

@MainActor
final class ConfigurationRepository {

    private let settingsService:
        SettingsService

    private let sharedSnapshotService:
        SharedBatchConfigurationSnapshotService

    init(
        settingsService: SettingsService,
        sharedSnapshotService:
            SharedBatchConfigurationSnapshotService
    ) {
        self.settingsService =
            settingsService
        self.sharedSnapshotService =
            sharedSnapshotService
    }

    func loadDefaultBatchConfigurationSnapshot()
    -> BatchConfigurationSnapshot {

        settingsService
            .buildBatchConfigurationSnapshot()
    }

    func loadSharedBatchConfigurationSnapshot()
    -> BatchConfigurationSnapshot {

        sharedSnapshotService
            .loadSnapshot()
    }

    func resolvedAlbumTitle(
        for identifier: String
    ) -> String? {

        sharedSnapshotService
            .resolvedAlbumTitle(
                for: identifier
            )
    }

    func upsertBirthdayAnchor(
        title: String,
        date: Date
    ) -> Anchor {

        if let index = settingsService
            .anchors
            .firstIndex(where: {
                $0.type == .birthday
            }) {
            settingsService
                .anchors[index]
                .title = title
            settingsService
                .anchors[index]
                .date = date
            settingsService
                .anchors[index]
                .isCountdown = false
            settingsService
                .saveAnchors()
            return settingsService
                .anchors[index]
        }

        let anchor =
            Anchor(
                type: .birthday,
                title: title,
                date: date
            )
        settingsService
            .anchors
            .append(anchor)
        settingsService
            .saveAnchors()
        return anchor
    }
}
#endif
