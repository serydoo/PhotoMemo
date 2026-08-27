#if !MEMOMARK_SHARE_EXTENSION
import Foundation

@MainActor
struct MemoMarkServiceContainer {

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
struct MemoMarkRepositoryContainer {

    let settings:
        SettingsRepository

    let queue:
        QueueRepository

    let diagnostics:
        DiagnosticsRepository

    let productionDiagnostics:
        ProductionDiagnosticsRepository

    let photo:
        PhotoRepository

    let photoLibrary:
        PhotoLibraryRepository

    let configuration:
        ConfigurationRepository
}

@MainActor
struct MemoMarkCoordinatorContainer {

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
        MemoMarkServiceContainer

    let repositories:
        MemoMarkRepositoryContainer

    let coordinators:
        MemoMarkCoordinatorContainer

    let batchQueueStore:
        BatchQueueStore

    let externalIntakeCenter:
        ExternalPhotoIntakeCenter

    init(
        defaults: UserDefaults,
        intakeDirectoryURL: URL,
        services: MemoMarkServiceContainer,
        repositories: MemoMarkRepositoryContainer,
        coordinators: MemoMarkCoordinatorContainer,
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
            MemoMarkSharedContainer
            .sharedUserDefaults,
        configurationLibraryBaseDirectoryURL: URL =
            MemoMarkSharedContainer
            .baseDirectoryURL,
        intakeDirectoryURL: URL =
            MemoMarkSharedContainer
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
                fileBaseDirectoryURL:
                    configurationLibraryBaseDirectoryURL,
                legacyDefaults: defaults
            )
        let sharedConfigurationSnapshotService =
            SharedBatchConfigurationSnapshotService(
                defaults: defaults
            )
        let productionDiagnosticsRepository =
            ProductionDiagnosticsRepository()
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
#if os(iOS)
        let automaticallyStartsBatchProcessing = false
#else
        let automaticallyStartsBatchProcessing = true
#endif
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
                    exportCoordinator,
                persistence:
                    BatchQueuePersistence(
                        fileBaseDirectoryURL:
                            configurationLibraryBaseDirectoryURL,
                        legacyDefaults: defaults
                    ),
                productionDiagnostics:
                    productionDiagnosticsRepository,
                automaticallyStartsProcessing:
                    automaticallyStartsBatchProcessing
            )

        let services =
            MemoMarkServiceContainer(
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
            MemoMarkRepositoryContainer(
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
                productionDiagnostics:
                    productionDiagnosticsRepository,
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
            MemoMarkCoordinatorContainer(
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
                        productionDiagnostics:
                            productionDiagnosticsRepository,
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
