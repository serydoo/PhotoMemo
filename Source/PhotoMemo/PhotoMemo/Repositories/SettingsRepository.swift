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
        selectedSubjectID: MemorySubject.ID?
    ) {

        settingsService
            .saveV1SubjectLibrary(
                subjects: subjects,
                selectedSubjectID: selectedSubjectID
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
            selectedExistingAlbumIdentifier:
                selectedExistingAlbumIdentifier,
            suggestedNewAlbumName:
                suggestedNewAlbumName
        )
    }
}
#endif
