import Foundation

struct BatchConfigurationSnapshotProvider {

    private let defaults: UserDefaults

    private enum Keys {

        static let anchors = "photomemo.anchors"

        static let selectedTemplate =
            "photomemo.selectedTemplate"

        static let selectedBadge =
            "photomemo.selectedBadge"

        static let shouldWritePhotoDescription =
            "photomemo.shouldWritePhotoDescription"

        static let photoDescriptionOverride =
            "photomemo.photoDescriptionOverride"

        static let selectedAnchorID =
            "photomemo.selectedAnchorID"

        static let selectedAlbumIdentifier =
            "photomemo.selectedAlbumIdentifier"
    }

    init(
        defaults: UserDefaults =
            PhotoMemoSharedContainer.sharedUserDefaults
    ) {
        self.defaults = defaults
    }

    func loadSnapshot() -> BatchConfigurationSnapshot {

        makeSnapshot(
            template: loadTemplate(),
            badge: loadBadge(),
            anchors: loadAnchors(),
            selectedAnchorIDString:
                defaults.string(
                    forKey: Keys.selectedAnchorID
                ) ?? "",
            shouldWritePhotoDescription:
                defaults.object(
                    forKey:
                        Keys.shouldWritePhotoDescription
                ) != nil
                ? defaults.bool(
                    forKey:
                        Keys.shouldWritePhotoDescription
                )
                : true,
            photoDescriptionOverride:
                defaults.string(
                    forKey:
                        Keys.photoDescriptionOverride
                ) ?? "",
            selectedAlbumIdentifier:
                defaults.string(
                    forKey:
                        Keys.selectedAlbumIdentifier
                ) ?? ""
        )
    }

    func makeSnapshot(
        template: Template?,
        badge: Badge?,
        anchors: [Anchor],
        selectedAnchorIDString: String,
        shouldWritePhotoDescription: Bool,
        photoDescriptionOverride: String,
        selectedAlbumIdentifier: String
    ) -> BatchConfigurationSnapshot {

        BatchConfigurationSnapshot(
            template:
                (template ?? .template1)
                .normalizedForEditing,
            badge:
                badge?.type == BadgeType.none
                ? nil
                : badge,
            anchor: resolvedAnchor(
                identifierString:
                    selectedAnchorIDString,
                anchors: anchors
            ),
            shouldWritePhotoDescription:
                shouldWritePhotoDescription,
            photoDescriptionOverride:
                photoDescriptionOverride,
            selectedAlbumIdentifier:
                normalizedAlbumIdentifier(
                    selectedAlbumIdentifier
                )
        )
    }

    func normalizedAlbumIdentifier(
        _ identifier: String
    ) -> String {

        PhotoMemoAlbumSelection
            .normalizedIdentifier(identifier)
    }
}

private extension BatchConfigurationSnapshotProvider {

    func loadAnchors() -> [Anchor] {

        guard
            let data = defaults.data(
                forKey: Keys.anchors
            ),
            let anchors =
                try? JSONDecoder().decode(
                    [Anchor].self,
                    from: data
                )
        else {
            return []
        }

        return anchors
    }

    func loadTemplate() -> Template? {

        guard
            let data = defaults.data(
                forKey: Keys.selectedTemplate
            ),
            let template =
                try? JSONDecoder().decode(
                    Template.self,
                    from: data
                )
        else {
            return nil
        }

        return template.normalizedForEditing
    }

    func loadBadge() -> Badge? {

        guard
            let data = defaults.data(
                forKey: Keys.selectedBadge
            )
        else {
            return nil
        }

        return try? JSONDecoder().decode(
            Badge.self,
            from: data
        )
    }

    func resolvedAnchor(
        identifierString: String,
        anchors: [Anchor]
    ) -> Anchor? {

        guard
            let identifier = UUID(
                uuidString: identifierString
            )
        else {
            return nil
        }

        return anchors.first {
            $0.id == identifier
        }
    }
}
