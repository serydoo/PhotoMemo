import Foundation

struct SharedBatchConfigurationSnapshotService {

    private let defaults: UserDefaults

    init(
        defaults: UserDefaults =
            PhotoMemoSharedContainer
            .sharedUserDefaults
    ) {
        self.defaults = defaults
    }

    func loadSnapshot() -> BatchConfigurationSnapshot {

        let selectedTemplate =
            loadTemplate()
            ?? .template1

        let selectedBadge =
            loadBadge()

        let anchors =
            loadAnchors()

        let selectedAnchorIDString =
            defaults.string(
                forKey:
                    "photomemo.selectedAnchorID"
            ) ?? ""

        let selectedAlbumIdentifier =
            PhotoMemoAlbumSelection
            .normalizedIdentifier(
                defaults.string(
                    forKey:
                        "photomemo.selectedAlbumIdentifier"
                ) ?? ""
            )

        let shouldWritePhotoDescription =
            defaults.object(
                forKey:
                    "photomemo.shouldWritePhotoDescription"
            ) != nil
            ? defaults.bool(
                forKey:
                    "photomemo.shouldWritePhotoDescription"
            )
            : true

        let photoDescriptionOverride =
            defaults.string(
                forKey:
                    "photomemo.photoDescriptionOverride"
            ) ?? ""

        let selectedAnchor =
            resolvedAnchor(
                identifierString:
                    selectedAnchorIDString,
                anchors: anchors
            )

        return BatchConfigurationSnapshot(
            template:
                selectedTemplate
                .normalizedForEditing,
            badge:
                selectedBadge?.type
                == BadgeType.none
                ? nil
                : selectedBadge,
            anchor: selectedAnchor,
            shouldWritePhotoDescription:
                shouldWritePhotoDescription,
            photoDescriptionOverride:
                photoDescriptionOverride,
            selectedAlbumIdentifier:
                selectedAlbumIdentifier
        )
    }
}

private extension SharedBatchConfigurationSnapshotService {

    func loadAnchors() -> [Anchor] {

        guard
            let data = defaults.data(
                forKey: "photomemo.anchors"
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
                forKey:
                    "photomemo.selectedTemplate"
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
                forKey:
                    "photomemo.selectedBadge"
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
