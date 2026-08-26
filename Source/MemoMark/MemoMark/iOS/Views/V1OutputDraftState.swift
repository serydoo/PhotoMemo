#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct V1OutputAlbumLoadRequest: Equatable {
    let id: UUID
    let generation: Int
    let subjectID: UUID?
    let configurationID: UUID?
    let outputTarget: V1IOSOutputTarget
    let selectedExistingAlbumIdentifier: String

    init(
        id: UUID = UUID(),
        generation: Int = 0,
        subjectID: UUID?,
        configurationID: UUID?,
        outputTarget: V1IOSOutputTarget = .automatic,
        selectedExistingAlbumIdentifier: String = ""
    ) {
        self.id = id
        self.generation = generation
        self.subjectID = subjectID
        self.configurationID = configurationID
        self.outputTarget = outputTarget
        self.selectedExistingAlbumIdentifier =
            selectedExistingAlbumIdentifier
    }

    func matches(
        subjectID: UUID?,
        configurationID: UUID?
    ) -> Bool {
        self.subjectID == subjectID
            && self.configurationID == configurationID
    }

    func matches(
        generation: Int,
        subjectID: UUID?,
        configurationID: UUID?,
        outputTarget: V1IOSOutputTarget,
        selectedExistingAlbumIdentifier: String
    ) -> Bool {
        self.generation == generation
            && self.matches(
                subjectID: subjectID,
                configurationID: configurationID
            )
            && self.outputTarget == outputTarget
            && self.selectedExistingAlbumIdentifier
                == selectedExistingAlbumIdentifier
    }
}

#if os(iOS)
/// Owns the current output draft and album-resource presentation state.
///
/// This is a live UI projection only. The durable configuration aggregate and
/// ConfigurationSession remain the owners of saved output truth.
struct V1OutputDraftState {
    var outputTarget: V1IOSOutputTarget = .automatic
    var mediaOutputMode: V1MediaOutputMode = .originalFormat
    var shouldWritePhotosDescription = true
    var photosDescriptionOverride = ""
    var configurationAlbumTitle = ""
    var livePhotoPolicy:
        MemoryConfigurationRecord.Output.LivePhotoPolicy =
        .preserveMotion
    var availableAlbums: [PhotoAlbumOption] = []
    var selectedExistingAlbumIdentifier = ""
    var newAlbumName = MemoMarkAlbumSelection.defaultAlbumTitle
    var isLoadingAlbums = false
    var albumStatusMessage = ""
    var activeAlbumLoadRequest: V1OutputAlbumLoadRequest?
    var albumLoadGeneration = 0
}
#endif
#endif
