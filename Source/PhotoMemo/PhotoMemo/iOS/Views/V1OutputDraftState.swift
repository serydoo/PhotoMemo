#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1OutputAlbumLoadRequest: Equatable {
    let id: UUID
    let subjectID: UUID?
    let configurationID: UUID?

    init(
        id: UUID = UUID(),
        subjectID: UUID?,
        configurationID: UUID?
    ) {
        self.id = id
        self.subjectID = subjectID
        self.configurationID = configurationID
    }

    func matches(
        subjectID: UUID?,
        configurationID: UUID?
    ) -> Bool {
        self.subjectID == subjectID
            && self.configurationID == configurationID
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
    var newAlbumName = PhotoMemoAlbumSelection.defaultAlbumTitle
    var isLoadingAlbums = false
    var albumStatusMessage = ""
    var activeAlbumLoadRequest: V1OutputAlbumLoadRequest?
}
#endif
#endif
