#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Combine

@MainActor
final class WorkspaceSessionController:
    ObservableObject {

    @Published private(set) var state =
        WorkspaceState()

    private(set) var environment:
        WorkspaceEnvironment?

    func send(
        action: WorkspaceAction
    ) {

        switch action {

        case let .selectPreviewPhoto(photo):
            state.selectedPhoto = photo

        case let .selectAnchor(anchorID):
            state.selectedAnchorID = anchorID

        case let .selectAlbumIdentifier(identifier):
            state.selectedAlbumIdentifier =
                identifier

        case let .setAvailableAlbums(albums):
            state.availableAlbums = albums

        case let .setSavingToAlbum(isSaving):
            state.isSavingToAlbum = isSaving

        case let .focusComposerField(field):
            state.editorSession.focusedField =
                field

        case let .updateComposerDisplayText(
            slot,
            text
        ):
            state.editorSession
                .displayTexts[slot] = text

        case let .updateComposerSelection(
            slot,
            selection
        ):
            state.editorSession
                .selections[slot] = selection

        case let .updateComposerModuleSpans(
            slot,
            spans
        ):
            state.editorSession
                .moduleSpansBySlot[slot] = spans

        case .openAnchorManager:
            state.presentationState
                .showsAnchorManager = true

        case .closeAnchorManager:
            state.presentationState
                .showsAnchorManager = false

        case .openTemplateRename:
            state.presentationState
                .showsTemplateRenameSheet = true

        case .closeTemplateRename:
            state.presentationState
                .showsTemplateRenameSheet = false

        case .openPermissionSetup:
            state.presentationState
                .showsPermissionSetupSheet = true

        case .closePermissionSetup:
            state.presentationState
                .showsPermissionSetupSheet = false

        case let .openOperationGuide(topic):
            state.presentationState
                .selectedOperationGuideTopic =
                topic
            state.presentationState
                .showsOperationGuideSheet = true

        case .closeOperationGuide:
            state.presentationState
                .showsOperationGuideSheet = false

        case .openWorkspaceRename:
            state.presentationState
                .showsWorkspaceConfigurationRenameSheet = true

        case .closeWorkspaceRename:
            state.presentationState
                .showsWorkspaceConfigurationRenameSheet = false

        case let .switchCompactTab(tab):
            state.presentationState.compactTab =
                tab

        case let .updateWorkspaceNameDraft(
            draft
        ):
            state.presentationState
                .workspaceConfigurationNameDraft =
                draft

        case let .updateTemplateNameDraft(
            draft
        ):
            state.presentationState
                .templateNameDraft = draft

        case let .presentAlert(
            title,
            message
        ):
            state.alertState.title = title
            state.alertState.message = message
            state.alertState.isPresented = true

        case .dismissAlert:
            state.alertState.isPresented = false

        case let .presentSaveFeedback(
            title,
            message
        ):
            state.saveFeedbackState.title =
                title
            state.saveFeedbackState.message =
                message
            state.saveFeedbackState.isPresented =
                true

        case .dismissSaveFeedback:
            state.saveFeedbackState.isPresented =
                false

        case let .replaceState(newState):
            state = newState
        }
    }

    func updateEnvironment(
        _ environment:
            WorkspaceEnvironment
    ) {

        self.environment = environment
    }
}
#endif
