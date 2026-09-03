#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct ConfigurationSaveRequest:
    Hashable {

    struct TimeAnchor:
        Hashable {

        let title: String

        let date: Date
    }

    struct AlbumSelection:
        Hashable {

        let identifier: String

        let title: String
    }

    let subject: MemorySubject?
    let subjects: [MemorySubject]
    let selectedSubjectID: MemorySubject.ID?
    let shouldSaveSubjectLibrary: Bool
    let memoryPresets: [MemoryPreset]
    let selectedMemoryPresetID: MemoryPreset.ID?
    let presentationRoute:
        MemoryConfigurationRecord.Presentation.Route
    let template: Template

    let badge: Badge?

    let locationDisplayConfiguration:
        ExpressionModuleConfiguration?

    let shouldWritePhotoDescription: Bool

    let photoDescriptionOverride: String

    let timeAnchor: TimeAnchor

    let albumSelection: AlbumSelection

    let mediaOutputMode:
        MediaOutputMode

    init(
        subject: MemorySubject? = nil,
        subjects: [MemorySubject] = [],
        selectedSubjectID: MemorySubject.ID? = nil,
        shouldSaveSubjectLibrary: Bool = true,
        memoryPresets: [MemoryPreset] = [],
        selectedMemoryPresetID: MemoryPreset.ID? = nil,
        presentationRoute:
            MemoryConfigurationRecord.Presentation.Route = .classicWhite,
        template: Template,
        badge: Badge?,
        locationDisplayConfiguration:
            ExpressionModuleConfiguration? = nil,
        shouldWritePhotoDescription: Bool,
        photoDescriptionOverride: String,
        timeAnchor: TimeAnchor,
        albumSelection: AlbumSelection,
        mediaOutputMode:
            MediaOutputMode = .originalFormat
    ) {
        self.subject = subject
        self.subjects = subjects
        self.selectedSubjectID =
            selectedSubjectID
        self.shouldSaveSubjectLibrary =
            shouldSaveSubjectLibrary
        self.memoryPresets =
            memoryPresets
        self.selectedMemoryPresetID =
            selectedMemoryPresetID
        self.presentationRoute = presentationRoute
        self.template = template
        self.badge = badge
        self.locationDisplayConfiguration =
            locationDisplayConfiguration
        self.shouldWritePhotoDescription =
            shouldWritePhotoDescription
        self.photoDescriptionOverride =
            photoDescriptionOverride
        self.timeAnchor = timeAnchor
        self.albumSelection = albumSelection
        self.mediaOutputMode =
            mediaOutputMode
    }
}

struct ConfigurationSaveReceipt:
    Hashable {

    let anchor: Anchor
}

struct ConfigurationBootstrapState:
    Hashable {

    let configurationLibrary:
        ConfigurationLibraryRecord?

    let configurationLibraryRecoveryFailed:
        Bool

    let draftProjection:
        ConfigurationDraftProjection?

    let subjects: [MemorySubject]?
    let selectedSubjectID: MemorySubject.ID?
    let memoryPresets: [MemoryPreset]
    let selectedMemoryPresetID: MemoryPreset.ID?
    let selectedSubject: MemorySubject?
    let subjectLibraryReadFailure:
        MemoMarkSharedDefaultsReadFailure?
    let customLogoBadge:
        Badge?

    let logoMode:
        ConfigurationLogoMode

    let outputTarget:
        ConfigurationOutputTarget

    let mediaOutputMode:
        MediaOutputMode

    let selectedExistingAlbumIdentifier:
        String

    let suggestedNewAlbumName:
        String?

    let locationDisplayConfiguration:
        ExpressionModuleConfiguration?

    init(
        configurationLibrary:
            ConfigurationLibraryRecord? = nil,
        configurationLibraryRecoveryFailed:
            Bool = false,
        draftProjection:
            ConfigurationDraftProjection? = nil,
        subjects: [MemorySubject]? = nil,
        selectedSubjectID: MemorySubject.ID? = nil,
        memoryPresets: [MemoryPreset] = [],
        selectedMemoryPresetID: MemoryPreset.ID? = nil,
        selectedSubject: MemorySubject? = nil,
        subjectLibraryReadFailure:
            MemoMarkSharedDefaultsReadFailure? = nil,
        customLogoBadge: Badge?,
        logoMode: ConfigurationLogoMode,
        outputTarget: ConfigurationOutputTarget,
        mediaOutputMode:
            MediaOutputMode = .originalFormat,
        selectedExistingAlbumIdentifier: String,
        suggestedNewAlbumName: String?,
        locationDisplayConfiguration:
            ExpressionModuleConfiguration? = nil
    ) {
        self.configurationLibrary =
            configurationLibrary
        self.configurationLibraryRecoveryFailed =
            configurationLibraryRecoveryFailed
        self.draftProjection = draftProjection
        self.subjects = subjects
        self.selectedSubjectID =
            selectedSubjectID
        self.memoryPresets = memoryPresets
        self.selectedMemoryPresetID =
            selectedMemoryPresetID
        self.selectedSubject = selectedSubject
        self.subjectLibraryReadFailure =
            subjectLibraryReadFailure
        self.customLogoBadge = customLogoBadge
        self.logoMode = logoMode
        self.outputTarget = outputTarget
        self.mediaOutputMode =
            mediaOutputMode
        self.selectedExistingAlbumIdentifier =
            selectedExistingAlbumIdentifier
        self.suggestedNewAlbumName =
            suggestedNewAlbumName
        self.locationDisplayConfiguration =
            locationDisplayConfiguration
    }
}

struct SaveConfigurationIntent:
    MemoMarkIntent {

    let request:
        ConfigurationSaveRequest

    let coordinator:
        ConfigurationCoordinator

    func execute()
    async -> MemoMarkResult<
        ConfigurationSaveReceipt
    > {

        coordinator
            .saveConfiguration(
                request
            )
    }
}

struct LoadConfigurationBootstrapIntent:
    MemoMarkIntent {

    let coordinator:
        ConfigurationCoordinator

    func execute()
    async -> MemoMarkResult<
        ConfigurationBootstrapState
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> MemoMarkResult<
        ConfigurationBootstrapState
    > {

        coordinator
            .loadConfigurationBootstrapState()
    }
}

// Kept for source compatibility with the pre-modernization callers and
// persisted compatibility tests. These aliases do not introduce another
// production path; they resolve to the canonical application transport.
typealias V1ConfigurationSaveRequest = ConfigurationSaveRequest
typealias V1ConfigurationSaveReceipt = ConfigurationSaveReceipt
typealias SaveV1ConfigurationIntent = SaveConfigurationIntent
#endif
