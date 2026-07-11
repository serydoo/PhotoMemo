#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

@MainActor
final class SettingsRepository {

    private let settingsService:
        SettingsService

    init(
        settingsService: SettingsService
    ) {
        self.settingsService =
            settingsService
    }

    func buildBatchConfigurationSnapshot()
    -> BatchConfigurationSnapshot {

        settingsService
            .buildBatchConfigurationSnapshot()
    }

    func activeConfigurationSlotID()
    -> WorkspaceConfigurationSlotID {

        settingsService
            .activeConfigurationSlotID
    }

    func updateActiveConfigurationSlotID(
        _ slotID:
            WorkspaceConfigurationSlotID
    ) {

        settingsService
            .activeConfigurationSlotID =
            slotID
    }

    func saveSelectedTemplate(
        _ template: Template?
    ) {

        settingsService
            .selectedTemplate = template
        settingsService
            .saveTemplate()
    }

    func saveSelectedBadge(
        _ badge: Badge?
    ) {

        settingsService
            .selectedBadge = badge
        settingsService
            .saveBadge()
    }

    func saveSelectedMemorySubject(
        _ subject: MemorySubject?
    ) {

        settingsService
            .saveSelectedMemorySubject(
                subject
            )
    }

    func saveV1SubjectLibrary(
        subjects: [MemorySubject],
        selectedSubjectID: MemorySubject.ID?,
        memoryPresets: [MemoryPreset] = [],
        selectedMemoryPresetID: MemoryPreset.ID? = nil
    ) {

        settingsService
            .saveV1SubjectLibrary(
                subjects: subjects,
                selectedSubjectID: selectedSubjectID,
                memoryPresets: memoryPresets,
                selectedMemoryPresetID:
                    selectedMemoryPresetID
            )
    }

    func savePhotoDescriptionSettings(
        shouldWrite: Bool,
        override: String
    ) {

        settingsService
            .shouldWritePhotoDescription =
            shouldWrite
        settingsService
            .photoDescriptionOverride =
            override
        settingsService
            .savePhotoDescriptionSettings()
    }

    func saveLocationDisplayConfiguration(
        _ configuration: ExpressionModuleConfiguration?
    ) {
        settingsService
            .saveLocationDisplayConfiguration(
                configuration
            )
    }

    func saveMediaOutputMode(
        _ mode: V1MediaOutputMode
    ) {
        settingsService
            .saveMediaOutputMode(mode)
    }

    func saveEditorState(
        selectedAnchorID: UUID?,
        selectedAlbumIdentifier: String,
        selectedAlbumTitle: String
    ) {

        settingsService
            .saveEditorState(
                selectedAnchorID:
                    selectedAnchorID,
                selectedAlbumIdentifier:
                    selectedAlbumIdentifier,
                selectedAlbumTitle:
                    selectedAlbumTitle
            )
    }

    func loadV1ConfigurationBootstrapState()
    -> V1ConfigurationBootstrapState {

        let bootstrapReadState =
            settingsService
            .loadV1BootstrapReadState()
        if let aggregate =
            bootstrapReadState.configurationLibrary,
           let active = Self.activeSelection(
               in: aggregate
           ) {
            let projection =
                V1ConfigurationDraftProjection(
                    configuration:
                        active.configuration
                )
            return V1ConfigurationBootstrapState(
                configurationLibrary: aggregate,
                draftProjection: projection,
                subjects:
                    aggregate.subjects.map(\.subject),
                selectedSubjectID:
                    active.subject.id,
                memoryPresets:
                    Self.memoryPresets(from: aggregate),
                selectedMemoryPresetID:
                    active.configuration.id,
                selectedSubject:
                    active.subject,
                customLogoBadge:
                    projection.logoMode == .customUpload
                    ? projection.badge
                    : nil,
                logoMode: projection.logoMode,
                outputTarget:
                    projection.outputTarget,
                mediaOutputMode:
                    projection.mediaOutputMode,
                selectedExistingAlbumIdentifier:
                    projection.selectedAlbumIdentifier,
                suggestedNewAlbumName:
                    projection.albumTitle.isEmpty
                    ? nil
                    : projection.albumTitle,
                locationDisplayConfiguration:
                    projection.locationConfiguration
            )
        }
        let subjectLibrary: V1SubjectLibraryRecord?
        let subjectLibraryReadFailure:
            PhotoMemoSharedDefaultsReadFailure?

        switch bootstrapReadState.subjectLibraryResult {
        case .success(let record):
            subjectLibrary = record
            subjectLibraryReadFailure = nil

        case .noValue:
            subjectLibrary = nil
            subjectLibraryReadFailure = nil

        case .decodingFailed(let failure):
            subjectLibrary = nil
            subjectLibraryReadFailure = failure
        }
        let savedSubject: MemorySubject?

        switch bootstrapReadState.subjectResult {
        case .success(let subject):
            savedSubject = subject

        case .noValue,
             .decodingFailed:
            savedSubject = nil
        }
        let savedBadge: Badge?

        switch bootstrapReadState.badgeResult {
        case .success(let badge):
            savedBadge = badge

        case .noValue,
             .decodingFailed:
            savedBadge = nil
        }
        let logoMode: V1LogoMode

        if savedBadge?.name
            == OptimizedSubjectAvatarAsset.subjectAvatarBadgeName {
            logoMode = .subjectAvatar
        } else if savedBadge?.type == .customUpload,
                  savedBadge?.imagePath != nil {
            logoMode = .customUpload
        } else {
            logoMode = .appleMini
        }

        let outputTarget:
            V1IOSOutputTarget
        let selectedExistingAlbumIdentifier:
            String

        switch bootstrapReadState.selectedAlbumIdentifier {
        case PhotoMemoAlbumSelection.systemLibraryIdentifier:
            outputTarget = .applePhotos
            selectedExistingAlbumIdentifier = ""

        case "",
             PhotoMemoAlbumSelection
             .automaticIdentifier:
            outputTarget = .automatic
            selectedExistingAlbumIdentifier = ""

        default:
            outputTarget = .existingAlbum
            selectedExistingAlbumIdentifier =
                bootstrapReadState
                .selectedAlbumIdentifier
        }

        let trimmedAlbumTitle =
            bootstrapReadState
            .selectedAlbumTitle
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let suggestedNewAlbumName =
            trimmedAlbumTitle.isEmpty
            || trimmedAlbumTitle == "系统图库"
            || trimmedAlbumTitle == "系统相册"
            ? nil
            : trimmedAlbumTitle

        return V1ConfigurationBootstrapState(
            subjects:
                subjectLibrary?.subjects,
            selectedSubjectID:
                subjectLibrary?.selectedSubjectID,
            memoryPresets:
                subjectLibrary?.memoryPresets ?? [],
            selectedMemoryPresetID:
                subjectLibrary?.selectedMemoryPresetID,
            selectedSubject:
                savedSubject,
            subjectLibraryReadFailure:
                subjectLibraryReadFailure,
            customLogoBadge:
                logoMode == .customUpload
                ? savedBadge
                : nil,
            logoMode:
                logoMode,
            outputTarget:
                outputTarget,
            mediaOutputMode:
                bootstrapReadState
                .mediaOutputMode,
            selectedExistingAlbumIdentifier:
                selectedExistingAlbumIdentifier,
            suggestedNewAlbumName:
                suggestedNewAlbumName,
            locationDisplayConfiguration:
                settingsService
                .loadLocationDisplayConfiguration()
        )
    }

    private static func activeSelection(
        in aggregate: ConfigurationLibraryRecord
    ) -> (
        subject: MemorySubject,
        configuration: MemoryConfigurationRecord
    )? {
        guard
            let subjectID = aggregate.activeSubjectID,
            let configurationID =
                aggregate.activeConfigurationID,
            let subjectRecord =
                aggregate.subjects.first(where: {
                    $0.subject.id == subjectID
                }),
            let configuration =
                subjectRecord.configurations.first(where: {
                    $0.id == configurationID
                })
        else {
            return nil
        }
        return (subjectRecord.subject, configuration)
    }

    private static func memoryPresets(
        from aggregate: ConfigurationLibraryRecord
    ) -> [MemoryPreset] {
        aggregate.subjects.flatMap { subjectRecord in
            subjectRecord.configurations.map { configuration in
                MemoryPreset(
                    id: configuration.id,
                    title: configuration.title,
                    summary: "",
                    regionTemplateIDs:
                        configuration.editor.regionTemplateIDs,
                    savedAt: configuration.savedAt,
                    selectedSubjectID:
                        subjectRecord.subject.id,
                    selectedTimeAnchorID:
                        configuration.selectedTimeAnchorID,
                    logoMode:
                        configuration.presentation.logo.mode,
                    usesCustomMemoryWriteText:
                        configuration.editor.memoryCopy.usesCustomText,
                    customMemoryWriteText:
                        configuration.editor.memoryCopy.customText
                )
            }
        }
    }

    func saveConfigurationLibrary(
        _ aggregate: ConfigurationLibraryRecord,
        afterSuccessfulProjection:
            @MainActor (
                BatchConfigurationSnapshot,
                ConfigurationLibrarySaveReceipt
            ) -> Void = { _, _ in }
    ) async throws -> ConfigurationLibrarySaveReceipt {
        try await settingsService
            .saveConfigurationLibrary(
                aggregate,
                afterSuccessfulProjection:
                    afterSuccessfulProjection
            )
    }

    func loadConfigurationLibrary()
    async throws -> ConfigurationLibraryLoadReceipt {
        try await settingsService
            .loadConfigurationLibrary()
    }
}
#endif
