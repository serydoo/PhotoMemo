#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct SubjectConfigurationRecord:
    Codable,
    Hashable {

    var subject: MemorySubject
    var configurations: [MemoryConfigurationRecord]
    var assetManifest: PortableAssetManifest
}

struct LegacyConfigurationCompatibilitySettings:
    Hashable {

    var template: Template
    var badge: Badge?
    var logoMode: V1LogoMode
    var locationConfiguration:
        ExpressionModuleConfiguration?
    var shouldWritePhotosDescription: Bool
    var photosDescriptionOverride: String
    var selectedAlbumIdentifier: String
    var selectedAlbumTitle: String
    var mediaOutputMode: V1MediaOutputMode

    init(
        template: Template,
        badge: Badge?,
        logoMode: V1LogoMode,
        locationConfiguration:
            ExpressionModuleConfiguration?,
        shouldWritePhotosDescription: Bool,
        photosDescriptionOverride: String,
        selectedAlbumIdentifier: String,
        selectedAlbumTitle: String,
        mediaOutputMode: V1MediaOutputMode
    ) {
        self.template = template
        self.badge = badge
        self.logoMode = logoMode
        self.locationConfiguration =
            locationConfiguration
        self.shouldWritePhotosDescription =
            shouldWritePhotosDescription
        self.photosDescriptionOverride =
            photosDescriptionOverride
        self.selectedAlbumIdentifier =
            selectedAlbumIdentifier
        self.selectedAlbumTitle =
            selectedAlbumTitle
        self.mediaOutputMode = mediaOutputMode
    }
}

struct ConfigurationLibraryRecord:
    Codable,
    Hashable {

    static let earliestSchemaVersion = 1
    static let latestSchemaVersion = 1

    let schemaVersion: Int
    var revision: Int
    var subjects: [SubjectConfigurationRecord]
    var activeSubjectID: UUID?
    var activeConfigurationID: UUID?

    init(
        revision: Int,
        subjects: [SubjectConfigurationRecord],
        activeSubjectID: UUID?,
        activeConfigurationID: UUID?
    ) {
        self.schemaVersion = Self.latestSchemaVersion
        self.revision = revision
        self.subjects = subjects
        self.activeSubjectID = activeSubjectID
        self.activeConfigurationID =
            activeConfigurationID
    }

    var validationResult:
        ConfigurationRecordValidationResult {
        var issues: [ConfigurationRecordValidationIssue] = []
        var seenSubjectIDs: Set<UUID> = []
        var reportedSubjectIDs: Set<UUID> = []
        var seenConfigurationIDs: Set<UUID> = []
        var reportedConfigurationIDs: Set<UUID> = []

        if !Self.isValidRevision(revision) {
            issues.append(
                .invalidLibraryRevision(revision)
            )
        }

        for subjectRecord in subjects {
            let subjectID = subjectRecord.subject.id
            if !seenSubjectIDs.insert(subjectID).inserted,
               reportedSubjectIDs.insert(subjectID).inserted {
                issues.append(
                    .duplicateSubjectID(subjectID)
                )
            }
            for configuration in
                subjectRecord.configurations {
                if !seenConfigurationIDs
                    .insert(configuration.id).inserted,
                   reportedConfigurationIDs
                    .insert(configuration.id).inserted {
                    issues.append(
                        .duplicateConfigurationID(
                            configuration.id
                        )
                    )
                }
            }
        }

        if activeSubjectID == nil,
           let activeConfigurationID {
            issues.append(
                .activeConfigurationWithoutActiveSubject(
                    activeConfigurationID
                )
            )
        }

        if let activeSubjectID,
           !subjects.contains(where: {
               $0.subject.id == activeSubjectID
           }) {
            issues.append(
                .missingActiveSubject(activeSubjectID)
            )
        }

        if let activeConfigurationID,
           !subjects.contains(where: { subjectRecord in
               subjectRecord.configurations.contains {
                   $0.id == activeConfigurationID
               }
           }) {
            issues.append(
                .missingActiveConfiguration(
                    activeConfigurationID
                )
            )
        }

        for subjectRecord in subjects {
            issues.append(
                contentsOf:
                    PortableMemoryConfigurationDocument
                    .subjectAssetIssues(
                        subjectRecord.subject
                    )
            )
            issues.append(
                contentsOf:
                    PortableMemoryConfigurationDocument
                    .manifestIssues(
                        subject: subjectRecord.subject,
                        configurations:
                            subjectRecord.configurations,
                        manifest:
                            subjectRecord.assetManifest
                    )
            )
            for configuration in
                subjectRecord.configurations {
                if !MemoryConfigurationRecord
                    .isValidRevision(
                        configuration.revision
                    ) {
                    issues.append(
                        .invalidConfigurationRevision(
                            configurationID:
                                configuration.id,
                            revision:
                                configuration.revision
                        )
                    )
                }
                if let selectedTimeAnchorID =
                    configuration.selectedTimeAnchorID,
                   subjectRecord.subject.timeAnchor(
                       id: selectedTimeAnchorID
                   ) == nil {
                    issues.append(
                        .selectedAnchorNotOwned(
                            subjectID:
                                subjectRecord.subject.id,
                            configurationID:
                                configuration.id,
                            anchorID:
                                selectedTimeAnchorID
                        )
                    )
                }
            }
        }

        if let activeSubjectID,
           let activeConfigurationID,
           let activeSubject = subjects.first(
               where: {
                   $0.subject.id == activeSubjectID
               }
           ),
           !activeSubject.configurations.contains(
               where: {
                   $0.id == activeConfigurationID
               }
           ) {
            issues.append(
                .configurationNotOwned(
                    subjectID: activeSubjectID,
                    configurationID:
                        activeConfigurationID
                )
            )
        }

        return issues.isEmpty ? .valid : .invalid(issues)
    }

    static func compatibilityResult(
        decoding data: Data
    ) -> ConfigurationDocumentCompatibilityResult<Self> {
        PortableMemoryConfigurationDocument
            .compatibilityResult(
                decoding: data,
                as: Self.self,
                earliestSupported:
                    earliestSchemaVersion,
                latestSupported:
                    latestSchemaVersion
            )
    }

    private enum CodingKeys:
        String,
        CodingKey {

        case schemaVersion
        case revision
        case subjects
        case activeSubjectID
        case activeConfigurationID
    }

    static func isValidRevision(
        _ revision: Int
    ) -> Bool {
        revision >= 0 && revision < Int.max
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )
        let schemaVersion = try container.decode(
            Int.self,
            forKey: .schemaVersion
        )
        try ConfigurationSchemaCompatibility
            .requireSupportedSchema(
                schemaVersion,
                earliestSupported:
                    Self.earliestSchemaVersion,
                latestSupported:
                    Self.latestSchemaVersion
            )

        self.schemaVersion = schemaVersion
        let revision = try container.decode(
            Int.self,
            forKey: .revision
        )
        guard Self.isValidRevision(revision) else {
            throw DecodingError.dataCorruptedError(
                forKey: .revision,
                in: container,
                debugDescription:
                    "Library revision must be in 0..<Int.max"
            )
        }
        self.revision = revision
        self.subjects = try container.decode(
            [SubjectConfigurationRecord].self,
            forKey: .subjects
        )
        self.activeSubjectID = try container.decodeIfPresent(
            UUID.self,
            forKey: .activeSubjectID
        )
        self.activeConfigurationID =
            try container.decodeIfPresent(
                UUID.self,
                forKey: .activeConfigurationID
            )
    }

    func encode(to encoder: Encoder) throws {
        guard Self.isValidRevision(revision) else {
            throw EncodingError.invalidValue(
                revision,
                .init(
                    codingPath: encoder.codingPath,
                    debugDescription:
                        "Library revision must be in 0..<Int.max"
                )
            )
        }
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )
        try container.encode(
            schemaVersion,
            forKey: .schemaVersion
        )
        try container.encode(
            revision,
            forKey: .revision
        )
        try container.encode(
            subjects,
            forKey: .subjects
        )
        try container.encodeIfPresent(
            activeSubjectID,
            forKey: .activeSubjectID
        )
        try container.encodeIfPresent(
            activeConfigurationID,
            forKey: .activeConfigurationID
        )
    }
}

extension ConfigurationLibraryRecord {

    static func migrating(
        _ legacy: V1SubjectLibraryRecord,
        compatibility:
            LegacyConfigurationCompatibilitySettings,
        revision: Int,
        savedAt: Date
    ) -> ConfigurationLibraryRecord {
        let activeSubjectID =
            legacy.subjects.contains(where: {
                $0.id == legacy.selectedSubjectID
            })
            ? legacy.selectedSubjectID
            : legacy.subjects.first?.id
        var activeConfigurationID: UUID?

        let migratedSubjects = legacy.subjects.map {
            originalSubject in
            var assetCollector = LegacyAssetCollector()
            let subject = assetCollector.portableSubject(
                originalSubject
            )
            let ownedPresets = legacy.memoryPresets.filter {
                preset in
                if let ownerID = preset.selectedSubjectID {
                    return ownerID == originalSubject.id
                }
                return originalSubject.id == activeSubjectID
            }
            let compatibilityRecipientID: UUID? = {
                guard originalSubject.id == activeSubjectID else {
                    return nil
                }
                return ownedPresets.first(where: {
                    $0.id == legacy.selectedMemoryPresetID
                })?.id
                ?? ownedPresets.first?.id
            }()

            var configurations = ownedPresets.map { preset in
                let isActiveConfiguration =
                    preset.id == compatibilityRecipientID
                return migratedConfiguration(
                    preset: preset,
                    subject: subject,
                    compatibility:
                        isActiveConfiguration
                        ? compatibility
                        : nil,
                    savedAt: savedAt,
                    assetCollector: &assetCollector
                )
            }

            if configurations.isEmpty {
                configurations = [
                    fallbackConfiguration(
                        for: subject,
                        savedAt: savedAt,
                        compatibility:
                            originalSubject.id
                            == activeSubjectID
                            ? compatibility
                            : nil,
                        assetCollector:
                            &assetCollector
                    )
                ]
            }

            if originalSubject.id == activeSubjectID {
                activeConfigurationID =
                    compatibilityRecipientID
                    ?? configurations.first?.id
            }

            return SubjectConfigurationRecord(
                subject: subject,
                configurations: configurations,
                assetManifest: .init(
                    entries: assetCollector.entries
                )
            )
        }

        return ConfigurationLibraryRecord(
            revision: revision,
            subjects: migratedSubjects,
            activeSubjectID: activeSubjectID,
            activeConfigurationID:
                activeConfigurationID
        )
    }

    private static func migratedConfiguration(
        preset: MemoryPreset,
        subject: MemorySubject,
        compatibility:
            LegacyConfigurationCompatibilitySettings?,
        savedAt: Date,
        assetCollector: inout LegacyAssetCollector
    ) -> MemoryConfigurationRecord {
        let template = compatibility?.template
            ?? deterministicClassicWhiteTemplate(
                basedOn: preset.id
            )
        let badge = compatibility?.badge
        let badgeAsset = assetCollector.reference(
            for: badge?.imagePath,
            role: .customLogo,
            ownerID: badge?.id ?? preset.id
        )
        let badgeDescriptor = badge.map {
            MemoryConfigurationRecord
                .Presentation.Logo.BadgeDescriptor(
                    id: $0.id,
                    name: $0.name,
                    type: $0.type,
                    imageName: $0.imageName,
                    systemSymbol: $0.systemSymbol,
                    isSystemDefault:
                        $0.isSystemDefault,
                    assetReference: badgeAsset
                )
        }
        let output = migratedOutput(
            preset: preset,
            compatibility: compatibility
        )

        return MemoryConfigurationRecord(
            id: preset.id,
            title: preset.title,
            revision: 1,
            savedAt: preset.savedAt ?? savedAt,
            selectedTimeAnchorID:
                preset.selectedTimeAnchorID,
            editor: .init(
                template: template,
                regionTemplateIDs:
                    preset.regionTemplateIDs,
                memoryCopy: .init(
                    usesCustomText:
                        preset
                        .usesCustomMemoryWriteText,
                    customText:
                        preset.customMemoryWriteText
                )
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration:
                    compatibility?
                    .locationConfiguration,
                logo: .init(
                    mode: compatibility?.logoMode
                        ?? preset.logoMode,
                    badge: badgeDescriptor
                )
            ),
            output: output
        )
    }

    private static func migratedOutput(
        preset: MemoryPreset,
        compatibility:
            LegacyConfigurationCompatibilitySettings?
    ) -> MemoryConfigurationRecord.Output {
        if let compatibility {
            return .init(
                mediaMode:
                    compatibility.mediaOutputMode,
                livePhotoPolicy:
                    livePhotoPolicy(
                        for: compatibility
                            .mediaOutputMode
                    ),
                photosDescriptionPolicy: .init(
                    isEnabled:
                        compatibility
                        .shouldWritePhotosDescription,
                    overrideText:
                        compatibility
                        .photosDescriptionOverride
                ),
                album: .init(
                    destination:
                        albumDestination(
                            identifier:
                                compatibility
                                .selectedAlbumIdentifier
                        ),
                    identifier:
                        compatibility
                        .selectedAlbumIdentifier,
                    title:
                        compatibility
                        .selectedAlbumTitle
                )
            )
        }

        let savedOutput = preset.savedOutputConfiguration
        let mediaMode = savedOutput?.mediaOutputMode
            ?? .originalFormat
        return .init(
            mediaMode: mediaMode,
            livePhotoPolicy:
                livePhotoPolicy(for: mediaMode),
            photosDescriptionPolicy: .init(
                isEnabled: false,
                overrideText: ""
            ),
            album: .init(
                destination: savedOutput.map {
                    albumDestination(
                        for: $0.outputTarget
                    )
                } ?? .automatic,
                identifier:
                    savedOutput?
                    .selectedExistingAlbumIdentifier
                    ?? "",
                title:
                    savedOutput?.newAlbumName
                    ?? ""
            )
        )
    }

    private static func fallbackConfiguration(
        for subject: MemorySubject,
        savedAt: Date,
        compatibility:
            LegacyConfigurationCompatibilitySettings?,
        assetCollector: inout LegacyAssetCollector
    ) -> MemoryConfigurationRecord {
        let id = MemoryConfigurationRecord
            .fallbackID(for: subject.id)
        let fallbackPreset = MemoryPreset(
            id: id,
            title: "默认配置",
            summary: "",
            regionTemplateIDs: [:],
            savedAt: savedAt,
            selectedSubjectID: subject.id,
            selectedTimeAnchorID:
                subject.activeTimeAnchorID
                ?? subject.primaryTimeAnchor?.id,
            logoMode:
                compatibility?.logoMode
                ?? .appleMini
        )
        return migratedConfiguration(
            preset: fallbackPreset,
            subject: subject,
            compatibility: compatibility,
            savedAt: savedAt,
            assetCollector: &assetCollector
        )
    }

    private static func deterministicClassicWhiteTemplate(
        basedOn id: UUID
    ) -> Template {
        func item(
            _ source: TemplateItem,
            discriminator: UInt8
        ) -> TemplateItem {
            TemplateItem(
                id: MemoryConfigurationRecord
                    .deterministicUUID(
                        basedOn: id,
                        discriminator: discriminator
                    ),
                type: source.type,
                name: source.name,
                value: source.value,
                isEnabled: source.isEnabled
            )
        }

        func area(
            name: String,
            item source: TemplateItem,
            areaDiscriminator: UInt8,
            itemDiscriminator: UInt8
        ) -> TemplateArea {
            TemplateArea(
                id: MemoryConfigurationRecord
                    .deterministicUUID(
                        basedOn: id,
                        discriminator:
                            areaDiscriminator
                    ),
                name: name,
                items: [
                    item(
                        source,
                        discriminator:
                            itemDiscriminator
                    )
                ]
            )
        }

        return Template(
            id: MemoryConfigurationRecord
                .deterministicUUID(
                    basedOn: id,
                    discriminator: 0x10
                ),
            preset: .classicWhite,
            name: "Classic White",
            leftTopArea: area(
                name: "Left Top",
                item: .relationshipDeviceLine,
                areaDiscriminator: 0x11,
                itemDiscriminator: 0x12
            ),
            leftBottomArea: area(
                name: "Left Bottom",
                item: .captureDateLine,
                areaDiscriminator: 0x13,
                itemDiscriminator: 0x14
            ),
            rightTopArea: area(
                name: "Right Top",
                item: .cameraSummary,
                areaDiscriminator: 0x15,
                itemDiscriminator: 0x16
            ),
            rightBottomArea: area(
                name: "Right Bottom",
                item: .memorySummary,
                areaDiscriminator: 0x17,
                itemDiscriminator: 0x18
            ),
            badgeArea: area(
                name: "Badge",
                item: .badge,
                areaDiscriminator: 0x19,
                itemDiscriminator: 0x1A
            )
        )
    }

    private static func livePhotoPolicy(
        for mediaMode: V1MediaOutputMode
    ) -> MemoryConfigurationRecord
        .Output.LivePhotoPolicy {
        switch mediaMode {
        case .originalFormat:
            return .preserveMotion
        case .staticImage:
            return .staticImageOnly
        }
    }

    private static func albumDestination(
        identifier: String
    ) -> MemoryConfigurationRecord
        .Output.AlbumDescriptor.Destination {
        let normalized = identifier.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        switch normalized {
        case "", "__photomemo_auto__":
            return .automatic
        case "__photomemo_system__":
            return .applePhotos
        default:
            return .existingAlbum
        }
    }

    private static func albumDestination(
        for target: V1IOSOutputTarget
    ) -> MemoryConfigurationRecord
        .Output.AlbumDescriptor.Destination {
        switch target {
        case .automatic:
            return .automatic
        case .applePhotos:
            return .applePhotos
        case .existingAlbum:
            return .existingAlbum
        case .newAlbum:
            return .newAlbum
        }
    }
}

private struct LegacyAssetCollector {

    private(set) var entries:
        [PortableAssetManifest.Entry] = []

    mutating func portableSubject(
        _ subject: MemorySubject
    ) -> MemorySubject {
        var portable = subject
        portable.identity.avatarImagePath = reference(
            for: subject.identity.avatarImagePath,
            role: .subjectAvatar,
            ownerID: subject.id
        )?.relativePath
        portable.identity.avatarBadgeImagePath = reference(
            for: subject.identity.avatarBadgeImagePath,
            role: .subjectAvatarBadge,
            ownerID: subject.id
        )?.relativePath
        portable.identity.avatarPreviewImagePath = reference(
            for: subject.identity.avatarPreviewImagePath,
            role: .subjectAvatarPreview,
            ownerID: subject.id
        )?.relativePath
        return portable
    }

    mutating func reference(
        for path: String?,
        role: PortableAssetManifest.Role,
        ownerID: UUID
    ) -> PortableAssetReference? {
        guard let path = normalized(path) else {
            return nil
        }

        let originalFileName = URL(
            fileURLWithPath: path
        ).lastPathComponent
        let relativePath: String
        if PortableAssetReference.isValid(path) {
            relativePath = path
        } else {
            relativePath = "Assets/\(ownerID.uuidString.lowercased())-\(originalFileName)"
        }
        guard let reference = try? PortableAssetReference(
            relativePath: relativePath
        ) else {
            return nil
        }

        if !entries.contains(where: {
            $0.role == role
            && $0.reference == reference
        }) {
            entries.append(
                .init(
                    id: MemoryConfigurationRecord
                        .deterministicUUID(
                            basedOn: ownerID,
                            discriminator:
                                discriminator(for: role)
                        ),
                    role: role,
                    reference: reference,
                    originalFileName:
                        originalFileName
                )
            )
        }
        return reference
    }

    private func normalized(
        _ path: String?
    ) -> String? {
        guard let path else {
            return nil
        }
        let trimmed = path.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return trimmed.isEmpty ? nil : trimmed
    }

    private func discriminator(
        for role: PortableAssetManifest.Role
    ) -> UInt8 {
        switch role {
        case .subjectAvatar:
            return 0xA1
        case .subjectAvatarBadge:
            return 0xA2
        case .subjectAvatarPreview:
            return 0xA3
        case .customLogo:
            return 0xA4
        }
    }
}
#endif
