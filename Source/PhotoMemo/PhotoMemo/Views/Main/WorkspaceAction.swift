#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum WorkspaceAction {

    case selectPreviewPhoto(
        SelectedPhoto?
    )

    case selectAnchor(
        Anchor.ID?
    )

    case selectAlbumIdentifier(
        String
    )

    case setAvailableAlbums(
        [PhotoAlbumOption]
    )

    case setSavingToAlbum(
        Bool
    )

    case focusComposerField(
        MainFieldSlot?
    )

    case updateComposerDisplayText(
        slot: MainFieldSlot,
        text: String
    )

    case updateComposerSelection(
        slot: MainFieldSlot,
        selection: NSRange
    )

    case updateComposerModuleSpans(
        slot: MainFieldSlot,
        spans: [TemplateEditorModuleSpan]
    )

    case openAnchorManager

    case closeAnchorManager

    case openTemplateRename

    case closeTemplateRename

    case openPermissionSetup

    case closePermissionSetup

    case openOperationGuide(
        MainOperationGuideTopic
    )

    case closeOperationGuide

    case openWorkspaceRename

    case closeWorkspaceRename

    case switchCompactTab(
        MainPresentationState
        .CompactTab
    )

    case updateWorkspaceNameDraft(
        String
    )

    case updateTemplateNameDraft(
        String
    )

    case presentAlert(
        title: String,
        message: String
    )

    case dismissAlert

    case presentSaveFeedback(
        title: String,
        message: String
    )

    case dismissSaveFeedback

    case replaceState(
        WorkspaceState
    )
}
#endif
