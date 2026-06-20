#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct WorkspaceEnvironment {

    let settings: SettingsService

    let permissionCenter:
        PermissionCenter

    let batchQueueStore:
        BatchQueueStore

    let templatePresetEngine:
        TemplatePresetEngine

    let anchorEngine:
        AnchorEngine

    let cardBuildService:
        RecordCardBuildService

    let exportService:
        RecordCardExportService

    let photoLibraryExportService:
        PhotoLibraryExportService
}
#endif
