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

        static let selectedAlbumTitle =
            "photomemo.selectedAlbumTitle"
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

    func loadAnchorsResult()
    -> PhotoMemoSharedDefaultsReadResult<
        [Anchor]
    > {

        decodeValueResult(
            [Anchor].self,
            forKey: Keys.anchors
        )
    }

    func loadTemplateResult()
    -> PhotoMemoSharedDefaultsReadResult<
        Template
    > {

        switch decodeValueResult(
            Template.self,
            forKey: Keys.selectedTemplate
        ) {
        case .noValue:
            return .noValue

        case .success(let template):
            return .success(
                template.normalizedForEditing
            )

        case .decodingFailed(let failure):
            return .decodingFailed(
                failure
            )
        }
    }

    func loadBadgeResult()
    -> PhotoMemoSharedDefaultsReadResult<
        Badge
    > {

        decodeValueResult(
            Badge.self,
            forKey: Keys.selectedBadge
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

    func resolvedAlbumTitle(
        for identifier: String
    ) -> String? {

        let normalizedIdentifier =
            normalizedAlbumIdentifier(identifier)

        guard
            !normalizedIdentifier.isEmpty,
            normalizedIdentifier
                == normalizedAlbumIdentifier(
                    defaults.string(
                        forKey: Keys.selectedAlbumIdentifier
                    ) ?? ""
                )
        else {
            return nil
        }

        if normalizedIdentifier
            == PhotoMemoAlbumSelection
            .systemLibraryIdentifier {
            return "系统相册"
        }

        let trimmedTitle =
            defaults.string(
                forKey: Keys.selectedAlbumTitle
            )?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        return trimmedTitle.isEmpty
            ? nil
            : trimmedTitle
    }
}

private extension BatchConfigurationSnapshotProvider {

    func loadAnchors() -> [Anchor] {

        switch loadAnchorsResult() {
        case .success(let anchors):
            return anchors

        case .noValue,
             .decodingFailed:
            return []
        }
    }

    func loadTemplate() -> Template? {

        switch loadTemplateResult() {
        case .success(let template):
            return template

        case .noValue,
             .decodingFailed:
            return nil
        }
    }

    func loadBadge() -> Badge? {

        switch loadBadgeResult() {
        case .success(let badge):
            return badge

        case .noValue,
             .decodingFailed:
            return nil
        }
    }

    func decodeValueResult<Value: Decodable>(
        _ valueType: Value.Type,
        forKey storageKey: String
    ) -> PhotoMemoSharedDefaultsReadResult<
        Value
    > {

        guard
            let data = defaults.data(
                forKey: storageKey
            )
        else {
            return .noValue
        }

        do {
            return .success(
                try JSONDecoder().decode(
                    valueType,
                    from: data
                )
            )
        } catch {
            return .decodingFailed(
                PhotoMemoSharedDefaultsReadFailure(
                    storageKey: storageKey,
                    payloadByteCount: data.count,
                    underlyingDescription:
                        String(
                            describing: error
                        )
                )
            )
        }
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
