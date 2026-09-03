#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import Foundation

/// The process-scoped capabilities required to compose the Configuration
/// Center. This is intentionally an ephemeral composition input: it owns no
/// SwiftUI state, persistence, or product behavior.
@MainActor
struct MemoMarkConfigurationCenterDependencies {

    let runtimeEnvironment:
        MemoMarkRuntimeEnvironment

    let backgroundStatusService:
        MemoMarkBackgroundStatusService

    let commerceStore:
        MemoMarkCommerceStore

    let refreshExternalIntake:
        () -> Void

    let previewCoordinator:
        PreviewCoordinator?

    let exportCoordinator:
        ExportCoordinator?

    let loadPhotoLibraryAlbums:
        LoadPhotoLibraryAlbumsTransaction

    let loadConfigurationBootstrap:
        LoadConfigurationBootstrapTransaction

    let saveConfiguration:
        SaveConfigurationTransaction

    let loadProductionConfigurationSnapshot:
        LoadProductionConfigurationSnapshotTransaction

    let queueCoordinator:
        QueueCoordinator?

    let configurationCoordinator:
        ConfigurationCoordinator?

    let externalIntakeCenter:
        ExternalPhotoIntakeCenter

    let diagnosticsRepository:
        DiagnosticsRepository?

    let productionDiagnosticsRepository:
        ProductionDiagnosticsRepository?

    let notificationDeepLink:
        MemoMarkDeepLink?

    let onNotificationDeepLinkHandled:
        () -> Void

    init(
        runtime: MemoMarkAppRuntime,
        refreshExternalIntake:
            @escaping () -> Void = {},
        notificationDeepLink: MemoMarkDeepLink? = nil,
        onNotificationDeepLinkHandled:
            @escaping () -> Void = {}
    ) {
        runtimeEnvironment = runtime.runtimeEnvironment
        backgroundStatusService = runtime.backgroundStatusService
        commerceStore = runtime.commerceStore
        self.refreshExternalIntake = refreshExternalIntake
        previewCoordinator = runtime.environment.coordinators.preview
        exportCoordinator = runtime.environment.coordinators.export
        loadPhotoLibraryAlbums =
            runtime.environment.transactions.loadPhotoLibraryAlbums
        loadConfigurationBootstrap =
            runtime.environment.transactions.loadConfigurationBootstrap
        saveConfiguration = runtime.environment.transactions.saveConfiguration
        loadProductionConfigurationSnapshot =
            runtime.environment.transactions
            .loadProductionConfigurationSnapshot
        queueCoordinator = runtime.environment.coordinators.queue
        configurationCoordinator =
            runtime.environment.coordinators.configuration
        externalIntakeCenter = runtime.environment.externalIntakeCenter
        diagnosticsRepository = runtime.environment.repositories.diagnostics
        productionDiagnosticsRepository =
            runtime.environment.repositories.productionDiagnostics
        self.notificationDeepLink = notificationDeepLink
        self.onNotificationDeepLinkHandled = onNotificationDeepLinkHandled
    }
}
#endif
