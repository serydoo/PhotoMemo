#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

@MainActor
struct PhotoMemoServiceContainer {

    let settingsService:
        SettingsService

    let photoImportService:
        PhotoImportService

    let recordCardBuildService:
        RecordCardBuildService

    let recordCardExportService:
        RecordCardExportService

    let photoLibraryExportService:
        PhotoLibraryExportService

    let batchProcessingCoordinator:
        BatchProcessingCoordinator

    let batchNotificationService:
        BatchNotificationService

    let externalIntakeStore:
        ExternalPhotoIntakeStore

    let sharedQueueSnapshotService:
        SharedBatchQueueSnapshotService

    let sharedConfigurationSnapshotService:
        SharedBatchConfigurationSnapshotService
}

@MainActor
struct PhotoMemoRepositoryContainer {

    let settings:
        SettingsRepository

    let queue:
        QueueRepository

    let diagnostics:
        DiagnosticsRepository

    let photo:
        PhotoRepository

    let photoLibrary:
        PhotoLibraryRepository

    let configuration:
        ConfigurationRepository
}

@MainActor
struct PhotoMemoCoordinatorContainer {

    let share:
        ShareCoordinator

    let queue:
        QueueCoordinator

    let preview:
        PreviewCoordinator

    let export:
        ExportCoordinator

    let configuration:
        ConfigurationCoordinator
}

@MainActor
final class AppEnvironment {

    let defaults:
        UserDefaults

    let intakeDirectoryURL: URL

    let services:
        PhotoMemoServiceContainer

    let repositories:
        PhotoMemoRepositoryContainer

    let coordinators:
        PhotoMemoCoordinatorContainer

    let batchQueueStore:
        BatchQueueStore

    let externalIntakeCenter:
        ExternalPhotoIntakeCenter

    init(
        defaults: UserDefaults,
        intakeDirectoryURL: URL,
        services: PhotoMemoServiceContainer,
        repositories: PhotoMemoRepositoryContainer,
        coordinators: PhotoMemoCoordinatorContainer,
        batchQueueStore: BatchQueueStore,
        externalIntakeCenter:
            ExternalPhotoIntakeCenter
    ) {
        self.defaults = defaults
        self.intakeDirectoryURL =
            intakeDirectoryURL
        self.services = services
        self.repositories =
            repositories
        self.coordinators =
            coordinators
        self.batchQueueStore =
            batchQueueStore
        self.externalIntakeCenter =
            externalIntakeCenter
    }

    static func live(
        defaults: UserDefaults =
            PhotoMemoSharedContainer
            .sharedUserDefaults,
        configurationLibraryBaseDirectoryURL: URL =
            PhotoMemoSharedContainer
            .baseDirectoryURL,
        intakeDirectoryURL: URL =
            PhotoMemoSharedContainer
            .externalIntakeDirectoryURL,
        batchQueueStore:
            BatchQueueStore? = nil,
        externalIntakeCenter:
            ExternalPhotoIntakeCenter? = nil
    ) -> AppEnvironment {

        let settingsService =
            SettingsService(
                defaults: defaults,
                configurationLibraryBaseDirectoryURL:
                    configurationLibraryBaseDirectoryURL
            )
        let photoImportService =
            PhotoImportService()
        let recordCardBuildService =
            RecordCardBuildService()
        let recordCardExportService =
            RecordCardExportService()
        let photoLibraryExportService =
            PhotoLibraryExportService()
        let batchNotificationService =
            BatchNotificationService()
        let externalIntakeStore =
            ExternalPhotoIntakeStore(
                defaults: defaults,
                intakeDirectoryURL:
                    intakeDirectoryURL
            )
        let sharedQueueSnapshotService =
            SharedBatchQueueSnapshotService(
                defaults: defaults
            )
        let sharedConfigurationSnapshotService =
            SharedBatchConfigurationSnapshotService(
                defaults: defaults
            )
        let photoRepository =
            PhotoRepository(
                importService:
                    photoImportService,
                photoLibraryExportService:
                    photoLibraryExportService
            )
        let photoLibraryRepository =
            PhotoLibraryRepository(
                photoLibraryExportService:
                    photoLibraryExportService
            )
        let previewCoordinator =
            PreviewCoordinator(
                buildService:
                    recordCardBuildService
            )
        let exportCoordinator =
            ExportCoordinator(
                exportService:
                    recordCardExportService,
                photoLibraryRepository:
                    photoLibraryRepository
            )
        let batchProcessingCoordinator =
            BatchProcessingCoordinator(
                importService:
                    photoImportService,
                cardBuildService:
                    recordCardBuildService,
                exportService:
                    recordCardExportService,
                photoLibraryExportService:
                    photoLibraryExportService
            )
        let resolvedExternalIntakeCenter =
            externalIntakeCenter
            ?? ExternalPhotoIntakeCenter(
                intakeStore:
                    externalIntakeStore,
                settingsService:
                    settingsService
            )
        let resolvedBatchQueueStore =
            batchQueueStore
            ?? BatchQueueStore(
                defaults: defaults,
                settingsService:
                    settingsService,
                executionCoordinator:
                    batchProcessingCoordinator,
                notificationService:
                    batchNotificationService,
                externalIntakeStore:
                    externalIntakeStore,
                photoRepository:
                    photoRepository,
                previewCoordinator:
                    previewCoordinator,
                exportCoordinator:
                    exportCoordinator
            )

        let services =
            PhotoMemoServiceContainer(
                settingsService:
                    settingsService,
                photoImportService:
                    photoImportService,
                recordCardBuildService:
                    recordCardBuildService,
                recordCardExportService:
                    recordCardExportService,
                photoLibraryExportService:
                    photoLibraryExportService,
                batchProcessingCoordinator:
                    batchProcessingCoordinator,
                batchNotificationService:
                    batchNotificationService,
                externalIntakeStore:
                    externalIntakeStore,
                sharedQueueSnapshotService:
                    sharedQueueSnapshotService,
                sharedConfigurationSnapshotService:
                    sharedConfigurationSnapshotService
            )

        let repositories =
            PhotoMemoRepositoryContainer(
                settings:
                    SettingsRepository(
                        settingsService:
                            settingsService
                    ),
                queue:
                    QueueRepository(
                        batchQueueStore:
                            resolvedBatchQueueStore
                    ),
                diagnostics:
                    DiagnosticsRepository(
                        defaults: defaults,
                        sharedQueueSnapshotService:
                            sharedQueueSnapshotService
                    ),
                photo:
                    photoRepository,
                photoLibrary:
                    photoLibraryRepository,
                configuration:
                    ConfigurationRepository(
                        settingsService:
                            settingsService,
                        sharedSnapshotService:
                            sharedConfigurationSnapshotService
                    )
            )

        let coordinators =
            PhotoMemoCoordinatorContainer(
                share:
                    ShareCoordinator(
                        externalIntakeCenter:
                            resolvedExternalIntakeCenter,
                        externalIntakeStore:
                            externalIntakeStore,
                        configurationRepository:
                            repositories
                            .configuration,
                        queueRepository:
                            repositories
                            .queue,
                        diagnosticsDefaults:
                            defaults
                    ),
                queue:
                    QueueCoordinator(
                        queueRepository:
                            repositories
                            .queue
                    ),
                preview:
                    previewCoordinator,
                export:
                    exportCoordinator,
                configuration:
                    ConfigurationCoordinator(
                        settingsRepository:
                            repositories
                            .settings,
                        configurationRepository:
                            repositories
                            .configuration,
                        applyLiveDefaultConfiguration: {
                            snapshot in
                            resolvedBatchQueueStore
                                .updateDefaultConfiguration(
                                    snapshot
                                )
                            resolvedExternalIntakeCenter
                                .updateDefaultConfiguration(
                                    snapshot
                                )
                        }
                    )
            )

        return AppEnvironment(
            defaults: defaults,
            intakeDirectoryURL:
                intakeDirectoryURL,
            services: services,
            repositories:
                repositories,
            coordinators:
                coordinators,
            batchQueueStore:
                resolvedBatchQueueStore,
            externalIntakeCenter:
                resolvedExternalIntakeCenter
        )
    }
}
#endif
