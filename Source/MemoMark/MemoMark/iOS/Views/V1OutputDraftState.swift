#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct OutputAlbumLoadContext: Equatable {
    let subjectID: UUID?
    let configurationID: UUID?
    let outputTarget: ConfigurationOutputTarget
    let selectedExistingAlbumIdentifier: String

    init(
        subjectID: UUID?,
        configurationID: UUID?,
        outputTarget: ConfigurationOutputTarget = .automatic,
        selectedExistingAlbumIdentifier: String = ""
    ) {
        self.subjectID = subjectID
        self.configurationID = configurationID
        self.outputTarget = outputTarget
        self.selectedExistingAlbumIdentifier =
            selectedExistingAlbumIdentifier
    }
}

#if os(iOS)
/// Owns the current output draft and album-resource presentation state.
///
/// This is a live UI projection only. The durable configuration aggregate and
/// ConfigurationSession remain the owners of saved output truth.
struct OutputDraftState {
    var outputTarget: ConfigurationOutputTarget = .automatic
    var mediaOutputMode: MediaOutputMode = .originalFormat
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
}
#endif
#endif
