import Foundation
import SwiftUI

struct MainView: View {

    @EnvironmentObject
    var batchQueueStore:
        BatchQueueStore

    @Environment(\.scenePhase)
    var scenePhase

    @StateObject
    var settings = SettingsService()

    @StateObject
    var permissionCenter =
        PermissionCenter()

    @StateObject
    var workspaceSession =
        WorkspaceSessionController()

    @State
    var selectedPhoto: SelectedPhoto?

    @State
    var selectedAnchorID: Anchor.ID?

    @State
    var presentationState =
        MainPresentationState()

    @State
    var alertState = MainAlertState()

    @State
    var saveFeedbackState =
        MainSaveFeedbackState()

    @State
    var availableAlbums: [PhotoAlbumOption] = []

    @State
    var selectedAlbumIdentifier =
        PhotoAlbumOption.automaticIdentifier

    @State
    var isSavingToAlbum = false

    @State
    var editorSession =
        MainEditorSessionState()

    let templatePresetEngine =
        TemplatePresetEngine()

    let anchorEngine =
        AnchorEngine()

    let cardBuildService =
        RecordCardBuildService()

    let exportService =
        RecordCardExportService()

    let photoLibraryExportService =
        PhotoLibraryExportService()

    var body: some View {
        mainScene
            .onAppear(
                perform:
                    bootstrapWorkspaceSessionPhaseA
            )
    }

}
