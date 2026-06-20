#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct WorkspaceState {

    var selectedPhoto: SelectedPhoto?

    var selectedAnchorID: Anchor.ID?

    var presentationState =
        MainPresentationState()

    var alertState =
        MainAlertState()

    var saveFeedbackState =
        MainSaveFeedbackState()

    var availableAlbums:
        [PhotoAlbumOption] = []

    var selectedAlbumIdentifier =
        PhotoAlbumOption
        .automaticIdentifier

    var isSavingToAlbum = false

    var editorSession =
        MainEditorSessionState()
}
#endif
