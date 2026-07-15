#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct ConfigurationCompatibilityProjection: Equatable {
    let subjectLibrary: V1SubjectLibraryRecord
    let productionConfigurationReference:
        ProductionConfigurationReference
    let selectedSubject: MemorySubject
    let selectedSubjectText: String
    let template: Template
    let badge: Badge?
    let locationDisplayConfiguration:
        ExpressionModuleConfiguration?
    let photoDescriptionSettings:
        LegacyPhotoDescriptionSettings
    let editorState: LegacySettingsEditorState
    let mediaOutputMode: V1MediaOutputMode
    let savedAt: Date
}

struct ConfigurationSnapshotProjectionInput {
    let selectedTemplate: Template?
    let selectedBadge: Badge?
    let anchors: [Anchor]
    let selectedAnchorIDString: String
    let selectedAlbumIdentifier: String
    let shouldWritePhotoDescription: Bool
    let photoDescriptionOverride: String
    let mediaOutputMode: V1MediaOutputMode
}

@MainActor
struct ConfigurationProjectionService {

    private let legacyStore: LegacySettingsStore
    private let snapshotProvider:
        BatchConfigurationSnapshotProvider

    init(
        legacyStore: LegacySettingsStore,
        snapshotProvider: BatchConfigurationSnapshotProvider
    ) {
        self.legacyStore = legacyStore
        self.snapshotProvider = snapshotProvider
    }

    func projectAndPersist(
        _ aggregate: ConfigurationLibraryRecord
    ) throws -> ConfigurationCompatibilityProjection {
        let projection = try makeProjection(from: aggregate)
        try legacyStore.persistCompatibilityProjection(projection)
        return projection
    }

    func buildBatchConfigurationSnapshot(
        input: ConfigurationSnapshotProjectionInput,
        durableAggregate: ConfigurationLibraryRecord?
    ) -> BatchConfigurationSnapshot {
        let compatibilitySnapshot = snapshotProvider.makeSnapshot(
            template: input.selectedTemplate,
            badge: input.selectedBadge,
            anchors: input.anchors,
            selectedAnchorIDString:
                input.selectedAnchorIDString,
            memorySubjectText:
                legacyStore.selectedMemorySubjectText(),
            shouldWritePhotoDescription:
                input.shouldWritePhotoDescription,
            photoDescriptionOverride:
                input.photoDescriptionOverride,
            selectedAlbumIdentifier:
                input.selectedAlbumIdentifier,
            locationDisplayConfiguration:
                legacyStore.loadLocationDisplayConfiguration(),
            mediaOutputModeRawValue:
                input.mediaOutputMode.rawValue
        )
        guard let durableAggregate,
              let configurationID =
                durableAggregate.activeConfigurationID,
              let configuration = durableAggregate.subjects.lazy
                .flatMap(\.configurations)
                .first(where: { $0.id == configurationID })
        else {
            return compatibilitySnapshot
        }
        let reference = ProductionConfigurationReference(
            configurationID: configurationID,
            revision: configuration.revision
        )
        if let exact = try? ProductionConfigurationSnapshotFactory
            .resolve(
                reference: reference,
                from: durableAggregate
            ) {
            return exact
        }
        return compatibilitySnapshot
            .withProductionConfigurationReference(reference)
    }

    func normalizedAlbumIdentifier(
        _ identifier: String
    ) -> String {
        snapshotProvider.normalizedAlbumIdentifier(identifier)
    }

    private func makeProjection(
        from aggregate: ConfigurationLibraryRecord
    ) throws -> ConfigurationCompatibilityProjection {
        guard let activeSubjectID = aggregate.activeSubjectID,
              let activeConfigurationID =
                aggregate.activeConfigurationID,
              let activeSubjectRecord = aggregate.subjects.first(
                  where: { $0.subject.id == activeSubjectID }
              ),
              let activeConfiguration =
                activeSubjectRecord.configurations.first(
                    where: { $0.id == activeConfigurationID }
                )
        else {
            throw ConfigurationLibraryPersistenceError
                .missingActiveSelection
        }
        let subjectLibrary = V1SubjectLibraryRecord(
            subjects: aggregate.subjects.map(\.subject),
            selectedSubjectID: activeSubjectID,
            memoryPresets: aggregate.subjects.flatMap {
                subjectRecord in
                subjectRecord.configurations.map {
                    legacyMemoryPreset(
                        from: $0,
                        subjectID: subjectRecord.subject.id
                    )
                }
            },
            selectedMemoryPresetID: activeConfigurationID
        )
        return ConfigurationCompatibilityProjection(
            subjectLibrary: subjectLibrary,
            productionConfigurationReference:
                ProductionConfigurationReference(
                    configurationID: activeConfigurationID,
                    revision: activeConfiguration.revision
                ),
            selectedSubject: activeSubjectRecord.subject,
            selectedSubjectText: activeSubjectRecord.subject
                .resolvedExpressionSubjectText,
            template: activeConfiguration.editor.template
                .normalizedForEditing,
            badge: legacyBadge(
                from: activeConfiguration.presentation.logo.badge
            ),
            locationDisplayConfiguration:
                activeConfiguration.presentation
                .locationConfiguration,
            photoDescriptionSettings:
                LegacyPhotoDescriptionSettings(
                    shouldWrite: activeConfiguration.output
                        .photosDescriptionPolicy.isEnabled,
                    override: activeConfiguration.output
                        .photosDescriptionPolicy.overrideText
                ),
            editorState: LegacySettingsEditorState(
                selectedAnchorIDString:
                    activeConfiguration.selectedTimeAnchorID?
                    .uuidString ?? "",
                selectedAlbumIdentifier:
                    legacyAlbumIdentifier(
                        activeConfiguration.output.album
                    ),
                selectedAlbumTitle:
                    activeConfiguration.output.album.title
            ),
            mediaOutputMode:
                activeConfiguration.output.mediaMode,
            savedAt: activeConfiguration.savedAt
        )
    }

    private func legacyBadge(
        from descriptor:
            MemoryConfigurationRecord.Presentation.Logo
            .BadgeDescriptor?
    ) -> Badge? {
        guard let descriptor else {
            return nil
        }
        return Badge(
            id: descriptor.id,
            name: descriptor.name,
            type: descriptor.type,
            imageName: descriptor.imageName,
            imagePath: descriptor.assetReference?.relativePath,
            systemSymbol: descriptor.systemSymbol,
            isSystemDefault: descriptor.isSystemDefault
        )
    }

    private func legacyMemoryPreset(
        from configuration: MemoryConfigurationRecord,
        subjectID: UUID
    ) -> MemoryPreset {
        MemoryPreset(
            id: configuration.id,
            title: configuration.title,
            summary: "",
            regionTemplateIDs:
                configuration.editor.regionTemplateIDs,
            savedAt: configuration.savedAt,
            selectedSubjectID: subjectID,
            selectedTimeAnchorID:
                configuration.selectedTimeAnchorID,
            outputOption: .processedImage,
            storageOption: .appFolder,
            logoMode: configuration.presentation.logo.mode,
            usesCustomMemoryWriteText:
                configuration.editor.memoryCopy.usesCustomText,
            customMemoryWriteText:
                configuration.editor.memoryCopy.customText,
            savedOutputConfiguration:
                legacyOutputConfiguration(configuration.output)
        )
    }

    private func legacyOutputConfiguration(
        _ output: MemoryConfigurationRecord.Output
    ) -> V1SavedOutputConfiguration {
        let outputTarget: V1IOSOutputTarget
        switch output.album.destination {
        case .automatic:
            outputTarget = .automatic
        case .applePhotos:
            outputTarget = .applePhotos
        case .existingAlbum:
            outputTarget = .existingAlbum
        case .newAlbum:
            outputTarget = .newAlbum
        }
        return V1SavedOutputConfiguration(
            outputTarget: outputTarget,
            mediaOutputMode: output.mediaMode,
            selectedExistingAlbumIdentifier:
                output.album.destination == .existingAlbum
                ? output.album.identifier
                : "",
            newAlbumName:
                output.album.destination == .newAlbum
                ? output.album.title
                : ""
        )
    }

    private func legacyAlbumIdentifier(
        _ album: MemoryConfigurationRecord.Output.AlbumDescriptor
    ) -> String {
        switch album.destination {
        case .automatic:
            return PhotoMemoAlbumSelection.automaticIdentifier
        case .applePhotos:
            return PhotoMemoAlbumSelection.systemLibraryIdentifier
        case .existingAlbum, .newAlbum:
            return album.identifier
        }
    }
}
#endif
