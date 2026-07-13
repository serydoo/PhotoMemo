import Foundation

struct V1SavedConfigurationReadiness:
    Equatable {

    let isReady: Bool
    let presetTitle: String?
    let configurationID: UUID?
    let configurationRevision: Int?

    init(
        isReady: Bool,
        presetTitle: String?,
        configurationID: UUID? = nil,
        configurationRevision: Int? = nil
    ) {
        self.isReady = isReady
        self.presetTitle = presetTitle
        self.configurationID = configurationID
        self.configurationRevision =
            configurationRevision
    }
}

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

        static let selectedMemorySubjectText =
            "photomemo.selectedMemorySubjectText"

        static let selectedMemorySubject =
            "photomemo.selectedMemorySubject"

        static let subjectLibrary =
            "photomemo.v1.subjectLibrary"

        static let locationDisplayConfiguration =
            "photomemo.locationDisplayConfiguration"

        static let mediaOutputMode =
            "photomemo.v1.mediaOutputMode"

        static let personalProfile =
            "photomemo.personalProfile"

        static let productionConfigurationReference =
            "photomemo.productionConfigurationReference"
    }

    init(
        defaults: UserDefaults =
            PhotoMemoSharedContainer.sharedUserDefaults
    ) {
        self.defaults = defaults
    }

    func loadSnapshot() -> BatchConfigurationSnapshot {

        let snapshot = makeSnapshot(
            template: loadTemplate(),
            badge: loadBadge(),
            anchors: loadAnchors(),
            selectedAnchorIDString:
                defaults.string(
                    forKey: Keys.selectedAnchorID
                ) ?? "",
            memorySubjectText:
                defaults.string(
                    forKey:
                        Keys.selectedMemorySubjectText
                ),
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
                ) ?? "",
            locationDisplayConfiguration:
                loadLocationDisplayConfiguration(),
            mediaOutputModeRawValue:
                defaults.string(
                    forKey:
                        Keys.mediaOutputMode
                )
        )

        guard let reference =
            loadProductionConfigurationReference()
        else {
            return snapshot
        }
        return snapshot
            .withProductionConfigurationReference(
                reference
            )
    }

    func loadProductionConfigurationReference()
    -> ProductionConfigurationReference? {
        guard let data = defaults.data(
            forKey:
                Keys.productionConfigurationReference
        ) else {
            return nil
        }
        return try? JSONDecoder().decode(
            ProductionConfigurationReference.self,
            from: data
        )
    }

    func loadV1ConfigurationReadiness()
    -> V1SavedConfigurationReadiness {
        guard
            let data = defaults.data(
                forKey: Keys.subjectLibrary
            ),
            let record =
                try? JSONDecoder().decode(
                    StoredV1SubjectLibraryRecord.self,
                    from: data
                )
        else {
            return V1SavedConfigurationReadiness(
                isReady: false,
                presetTitle: nil
            )
        }

        let selectedPreset =
            resolvedSelectedPreset(
                from: record
            )
        let reference =
            loadProductionConfigurationReference()

        return V1SavedConfigurationReadiness(
            isReady: selectedPreset != nil,
            presetTitle:
                selectedPreset?
                .trimmedTitle,
            configurationID:
                reference?.configurationID,
            configurationRevision:
                reference?.revision
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
        memorySubjectText: String?,
        shouldWritePhotoDescription: Bool,
        photoDescriptionOverride: String,
        selectedAlbumIdentifier: String,
        locationDisplayConfiguration:
            ExpressionModuleConfiguration? = nil,
        mediaOutputModeRawValue: String? = nil
    ) -> BatchConfigurationSnapshot {
        let resolvedAnchor =
            resolvedAnchor(
                identifierString:
                    selectedAnchorIDString,
                anchors: anchors
            )
#if !PHOTOMEMO_SHARE_EXTENSION
        let frozenMemorySubject =
            makeFrozenMemorySubject(
                anchors: anchors,
                selectedAnchorID:
                    resolvedAnchor?.id
            )
        let frozenConfigurationSnapshot =
            ConfigurationSnapshotBuilder
            .build(from: frozenMemorySubject)
        let resolvedMemorySubjectText =
            frozenMemorySubject
            .resolvedExpressionSubjectText
#else
        let resolvedMemorySubjectText =
            normalizedSubjectText(
                memorySubjectText
            )
#endif

        let snapshot =
            BatchConfigurationSnapshot(
            template:
                (template ?? .classicWhite)
                .normalizedForEditing,
            badge:
                badge?.type == BadgeType.none
                ? nil
                : badge,
            anchor: resolvedAnchor,
            memorySubjectText:
                resolvedMemorySubjectText,
            locationDisplayConfiguration:
                locationDisplayConfiguration,
            shouldWritePhotoDescription:
                shouldWritePhotoDescription,
            photoDescriptionOverride:
                photoDescriptionOverride,
            selectedAlbumIdentifier:
                normalizedAlbumIdentifier(
                    selectedAlbumIdentifier
                ),
            mediaOutputModeRawValue:
                mediaOutputModeRawValue
        )

#if !PHOTOMEMO_SHARE_EXTENSION
        return snapshot
            .withCanonicalProductionSnapshot(
                frozenConfigurationSnapshot
            )
#else
        return snapshot
#endif
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

    struct StoredV1SubjectLibraryRecord:
        Decodable {

        let selectedSubjectID: UUID?
        let memoryPresets:
            [StoredMemoryPreset]
        let selectedMemoryPresetID: UUID?

        private enum CodingKeys:
            String,
            CodingKey {

            case selectedSubjectID
            case memoryPresets
            case selectedMemoryPresetID
        }

        init(from decoder: Decoder) throws {
            let container =
                try decoder.container(
                    keyedBy: CodingKeys.self
                )
            selectedSubjectID =
                try container.decodeIfPresent(
                    UUID.self,
                    forKey: .selectedSubjectID
                )
            memoryPresets =
                try container.decodeIfPresent(
                    [StoredMemoryPreset].self,
                    forKey: .memoryPresets
                ) ?? []
            selectedMemoryPresetID =
                try container.decodeIfPresent(
                    UUID.self,
                    forKey: .selectedMemoryPresetID
                )
        }
    }

    struct StoredMemoryPreset:
        Decodable {

        let id: UUID
        let title: String
        let selectedSubjectID: UUID?

        var trimmedTitle: String? {
            let trimmedTitle =
                title.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            return trimmedTitle.isEmpty
                ? nil
                : trimmedTitle
        }
    }

    func loadAnchors() -> [Anchor] {

        switch loadAnchorsResult() {
        case .success(let anchors):
            return anchors

        case .noValue,
             .decodingFailed:
            return []
        }
    }

    func resolvedSelectedPreset(
        from record:
            StoredV1SubjectLibraryRecord
    ) -> StoredMemoryPreset? {
        if let selectedMemoryPresetID =
            record.selectedMemoryPresetID,
           let selectedPreset =
            record.memoryPresets.first(
                where: {
                    $0.id == selectedMemoryPresetID
                }
            ) {
            return selectedPreset
        }

        if let selectedSubjectID =
            record.selectedSubjectID,
           let selectedSubjectPreset =
            record.memoryPresets.first(
                where: {
                    $0.selectedSubjectID
                    == selectedSubjectID
                }
            ) {
            return selectedSubjectPreset
        }

        return record.memoryPresets.first
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

    func loadLocationDisplayConfiguration()
    -> ExpressionModuleConfiguration? {
        guard
            let data =
                defaults.data(
                    forKey:
                        Keys.locationDisplayConfiguration
                )
        else {
            return nil
        }

        return try? JSONDecoder().decode(
            ExpressionModuleConfiguration.self,
            from: data
        )
    }

#if !PHOTOMEMO_SHARE_EXTENSION
    func makeFrozenMemorySubject(
        anchors: [Anchor],
        selectedAnchorID: UUID?
    ) -> MemorySubject {
        if let selectedSubject =
            loadSelectedSubjectLibrarySubject() {
            return selectedSubject
        }

        if let selectedSubject =
            loadSelectedMemorySubject() {
            return selectedSubject
        }

        return MemorySubjectAdapter.adapt(
            profile:
                loadPersonalProfile()
                ?? PersonalProfile(),
            anchors: anchors,
            selectedAnchorID: selectedAnchorID
        )
    }

    func loadSelectedMemorySubject() -> MemorySubject? {
        guard
            let data = defaults.data(
                forKey: Keys.selectedMemorySubject
            )
        else {
            return nil
        }

        return try? JSONDecoder().decode(
            MemorySubject.self,
            from: data
        )
    }

    func loadSelectedSubjectLibrarySubject() -> MemorySubject? {
        guard
            let data = defaults.data(
                forKey: Keys.subjectLibrary
            ),
            let record =
                try? JSONDecoder().decode(
                    V1SubjectLibraryRecord.self,
                    from: data
                ),
            !record.subjects.isEmpty
        else {
            return nil
        }

        if let selectedSubjectID =
            record.selectedSubjectID,
           let selectedSubject =
            record.subjects.first(
                where: {
                    $0.id == selectedSubjectID
                }
            ) {
            return selectedSubject
        }

        return record.subjects.first
    }

    func loadPersonalProfile() -> PersonalProfile? {
        guard
            let data = defaults.data(
                forKey: Keys.personalProfile
            )
        else {
            return nil
        }

        return try? JSONDecoder().decode(
            PersonalProfile.self,
            from: data
        )
    }
#endif

    func normalizedSubjectText(
        _ text: String?
    ) -> String? {

        guard let text else {
            return nil
        }

        let trimmed =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty
            ? nil
            : trimmed
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
