#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1ConfigurationSaveRequest:
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
    let template: Template

    let badge: Badge?

    let shouldWritePhotoDescription: Bool

    let photoDescriptionOverride: String

    let timeAnchor: TimeAnchor

    let albumSelection: AlbumSelection

    init(
        subject: MemorySubject? = nil,
        subjects: [MemorySubject] = [],
        selectedSubjectID: MemorySubject.ID? = nil,
        shouldSaveSubjectLibrary: Bool = true,
        template: Template,
        badge: Badge?,
        shouldWritePhotoDescription: Bool,
        photoDescriptionOverride: String,
        timeAnchor: TimeAnchor,
        albumSelection: AlbumSelection
    ) {
        self.subject = subject
        self.subjects = subjects
        self.selectedSubjectID =
            selectedSubjectID
        self.shouldSaveSubjectLibrary =
            shouldSaveSubjectLibrary
        self.template = template
        self.badge = badge
        self.shouldWritePhotoDescription =
            shouldWritePhotoDescription
        self.photoDescriptionOverride =
            photoDescriptionOverride
        self.timeAnchor = timeAnchor
        self.albumSelection = albumSelection
    }
}

struct V1ConfigurationSaveReceipt:
    Hashable {

    let anchor: Anchor
}

struct V1ConfigurationBootstrapState:
    Hashable {

    let subjects: [MemorySubject]?
    let selectedSubjectID: MemorySubject.ID?
    let selectedSubject: MemorySubject?
    let subjectLibraryReadFailure:
        PhotoMemoSharedDefaultsReadFailure?
    let customLogoBadge:
        Badge?

    let logoMode:
        V1LogoMode

    let outputTarget:
        V1IOSOutputTarget

    let selectedExistingAlbumIdentifier:
        String

    let suggestedNewAlbumName:
        String?

    init(
        subjects: [MemorySubject]? = nil,
        selectedSubjectID: MemorySubject.ID? = nil,
        selectedSubject: MemorySubject? = nil,
        subjectLibraryReadFailure:
            PhotoMemoSharedDefaultsReadFailure? = nil,
        customLogoBadge: Badge?,
        logoMode: V1LogoMode,
        outputTarget: V1IOSOutputTarget,
        selectedExistingAlbumIdentifier: String,
        suggestedNewAlbumName: String?
    ) {
        self.subjects = subjects
        self.selectedSubjectID =
            selectedSubjectID
        self.selectedSubject = selectedSubject
        self.subjectLibraryReadFailure =
            subjectLibraryReadFailure
        self.customLogoBadge = customLogoBadge
        self.logoMode = logoMode
        self.outputTarget = outputTarget
        self.selectedExistingAlbumIdentifier =
            selectedExistingAlbumIdentifier
        self.suggestedNewAlbumName =
            suggestedNewAlbumName
    }
}

struct SaveV1ConfigurationIntent:
    PhotoMemoIntent {

    let request:
        V1ConfigurationSaveRequest

    let coordinator:
        ConfigurationCoordinator

    func execute()
    async -> PhotoMemoResult<
        V1ConfigurationSaveReceipt
    > {

        coordinator
            .saveV1Configuration(
                request
            )
    }
}

struct LoadV1ConfigurationBootstrapIntent:
    PhotoMemoIntent {

    let coordinator:
        ConfigurationCoordinator

    func execute()
    async -> PhotoMemoResult<
        V1ConfigurationBootstrapState
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> PhotoMemoResult<
        V1ConfigurationBootstrapState
    > {

        coordinator
            .loadV1ConfigurationBootstrapState()
    }
}
#endif
