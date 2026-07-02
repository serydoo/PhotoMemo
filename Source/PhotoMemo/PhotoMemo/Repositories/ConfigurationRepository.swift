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

    func syncAnchors(
        from subject: MemorySubject?,
        fallbackTitle: String,
        fallbackDate: Date
    ) -> Anchor {

        guard
            let subject,
            !subject.timeAnchors.isEmpty
        else {
            return upsertBirthdayAnchor(
                title: fallbackTitle,
                date: fallbackDate
            )
        }

        settingsService.anchors =
            subject.timeAnchors.map {
                mappedAnchor(from: $0)
            }
        settingsService.saveAnchors()

        let resolvedAnchor =
            subject.primaryTimeAnchor
            .map(mappedAnchor(from:))
            ?? settingsService.anchors.first
            ?? upsertBirthdayAnchor(
                title: fallbackTitle,
                date: fallbackDate
            )

        return resolvedAnchor
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
                .anchors[index]
                .expressionStyle =
                MemoryAnchorExpressionStyle
                .resolvedStyle(
                    for: .birthday,
                    candidate:
                        settingsService
                        .anchors[index]
                        .expressionStyle
                )
            settingsService
                .saveAnchors()
            return settingsService
                .anchors[index]
        }

        let anchor =
            Anchor(
                type: .birthday,
                title: title,
                date: date,
                expressionStyle:
                    MemoryAnchorExpressionStyle
                    .defaultStyle(
                        for: .birthday
                    )
            )
        settingsService
            .anchors
            .append(anchor)
        settingsService
            .saveAnchors()
        return anchor
    }

    private func mappedAnchor(
        from timeAnchor:
            MemorySubject.TimeAnchor
    ) -> Anchor {
        let anchorType =
            timeAnchor.resolvedAnchorType

        return Anchor(
            id: timeAnchor.id,
            type: anchorType,
            title: timeAnchor.title,
            date: timeAnchor.date,
            isCountdown:
                anchorType.defaultCountdown,
            expressionStyle:
                timeAnchor
                .resolvedExpressionStyle
        )
    }
}
#endif
