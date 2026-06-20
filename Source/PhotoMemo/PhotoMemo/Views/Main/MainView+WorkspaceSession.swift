#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

extension MainView {

    var currentWorkspaceState:
        WorkspaceState {

        WorkspaceState(
            selectedPhoto: selectedPhoto,
            selectedAnchorID: selectedAnchorID,
            presentationState:
                presentationState,
            alertState: alertState,
            saveFeedbackState:
                saveFeedbackState,
            availableAlbums:
                availableAlbums,
            selectedAlbumIdentifier:
                selectedAlbumIdentifier,
            isSavingToAlbum:
                isSavingToAlbum,
            editorSession:
                editorSession
        )
    }

    var currentWorkspaceEnvironment:
        WorkspaceEnvironment {

        WorkspaceEnvironment(
            settings: settings,
            permissionCenter:
                permissionCenter,
            batchQueueStore:
                batchQueueStore,
            templatePresetEngine:
                templatePresetEngine,
            anchorEngine: anchorEngine,
            cardBuildService:
                cardBuildService,
            exportService:
                exportService,
            photoLibraryExportService:
                photoLibraryExportService
        )
    }

    func bootstrapWorkspaceSessionPhaseA() {

        workspaceSession.updateEnvironment(
            currentWorkspaceEnvironment
        )
        workspaceSession.send(
            action: .replaceState(
                currentWorkspaceState
            )
        )
    }
}
#endif
