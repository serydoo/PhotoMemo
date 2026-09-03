#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Core architecture dependency contracts")
struct CoreArchitectureDependencyContractTests {

    @Test("batch task executor does not depend on the queue presentation facade")
    func batchTaskExecutorDoesNotDependOnQueuePresentationFacade() throws {
        let sourceURL = Self.repositoryRoot
            .appendingPathComponent(
                "Source/MemoMark/MemoMark/Services/BatchTaskProcessor.swift"
            )
        let source = try String(
            contentsOf: sourceURL,
            encoding: .utf8
        )

        #expect(!source.contains("BatchQueueStore"))
        #expect(source.contains("BatchTaskExecutionRuntime"))
        #expect(source.contains("runtime.accept("))
    }

    @Test("resource cleanup does not pull the legacy processing coordinator into production")
    func resourceCleanupDoesNotDependOnLegacyProcessingCoordinator() throws {
        let lifecycleSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/BatchTaskResourceLifecycle.swift"
        )
        let executionSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/BatchQueueExecution.swift"
        )
        let environmentSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Architecture/AppEnvironment.swift"
        )

        #expect(!lifecycleSource.contains("BatchProcessingCoordinator"))
        #expect(!executionSource.contains("coordinator: BatchProcessingCoordinator"))
        #expect(!environmentSource.contains("batchProcessingCoordinator:"))
    }

    @Test("macOS file-open intake is routed through the composed app runtime")
    func macOSFileOpenIntakeDoesNotUseGlobalCenter() throws {
        let appDelegateSource = try Self.source(
            at: "Source/MemoMark/MemoMark/App/MemoMarkAppDelegate.swift"
        )
        let appSource = try Self.source(
            at: "Source/MemoMark/MemoMark/App/MemoMarkApp.swift"
        )

        #expect(!appDelegateSource.contains("ExternalPhotoIntakeCenter.shared"))
        #expect(appDelegateSource.contains("openURLsHandler"))
        #expect(appSource.contains("appDelegate.install"))
        #expect(appSource.contains("runtime.handleExternalURLs"))
    }

    @Test("file-open intake captures configuration through the share admission boundary")
    func fileOpenIntakeUsesShareAdmissionBoundary() throws {
        let runtimeSource = try Self.source(
            at: "Source/MemoMark/MemoMark/App/MemoMarkAppRuntime.swift"
        )

        #expect(
            runtimeSource.contains(
                "environment\n            .coordinators\n            .share\n            .submit("
            )
        )
        #expect(!runtimeSource.contains("externalIntakeCenter.submit("))
    }

    @Test("external intake has no dormant global production entry point")
    func externalIntakeDoesNotRetainGlobalCenter() throws {
        let intakeCenterSource = try Self.source(
            at: "Source/MemoMark/MemoMark/App/ExternalPhotoIntakeCenter.swift"
        )

        #expect(!intakeCenterSource.contains("static let shared"))
        #expect(!intakeCenterSource.contains("init()"))
        #expect(intakeCenterSource.contains("init("))
    }

    @Test("iOS configuration root requires the composed external intake center")
    func iOSConfigurationRootRequiresComposedExternalIntakeCenter() throws {
        let rootSource = try Self.source(
            at: "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView.swift"
        )
        let dependenciesSource = try Self.source(
            at: "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterDependencies.swift"
        )

        #expect(!rootSource.contains("ExternalPhotoIntakeCenter.shared"))
        #expect(!rootSource.contains("?? .shared"))
        #expect(rootSource.contains("let externalIntakeCenter:\n        ExternalPhotoIntakeCenter"))
        #expect(dependenciesSource.contains("let externalIntakeCenter:\n        ExternalPhotoIntakeCenter"))
        #expect(dependenciesSource.contains("externalIntakeCenter = runtime.environment.externalIntakeCenter"))
    }

    @Test("configuration live defaults enter the queue through its repository boundary")
    func configurationLiveDefaultsUseQueueRepositoryBoundary() throws {
        let environmentSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Architecture/AppEnvironment.swift"
        )

        #expect(
            environmentSource.contains(
                "repositories\n                            .queue\n                                .updateDefaultConfiguration("
            )
        )
        #expect(
            !environmentSource.contains(
                "resolvedBatchQueueStore\n                                .updateDefaultConfiguration("
            )
        )
    }

    @Test("external intake drain has one focused application owner")
    func externalIntakeDrainUsesFocusedCoordinator() throws {
        let appRuntimeSource = try Self.source(
            at: "Source/MemoMark/MemoMark/App/MemoMarkAppRuntime.swift"
        )
        let coordinatorSource = try Self.source(
            at: "Source/MemoMark/MemoMark/App/ExternalIntakeDrainCoordinator.swift"
        )
        let queueProjectionSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Application/ExternalIntakeQueueProjection.swift"
        )

        #expect(
            coordinatorSource.contains(
                "final class ExternalIntakeDrainCoordinator"
            )
        )
        #expect(coordinatorSource.contains("func drain()"))
        #expect(coordinatorSource.contains("ProcessShareIntent"))
        #expect(
            queueProjectionSource.contains(
                "protocol ExternalIntakeQueueProjection"
            )
        )
        #expect(
            queueProjectionSource.contains(
                "extension BatchQueueStore: ExternalIntakeQueueProjection"
            )
        )
        #expect(
            appRuntimeSource.contains(
                "externalIntakeDrainCoordinator"
            )
        )
        #expect(!appRuntimeSource.contains("ProcessShareIntent"))
        #expect(
            !appRuntimeSource.contains(
                "isFlushingExternalRequests"
            )
        )
    }

    @Test("queue bootstrap receipt reconciliation is isolated from the presentation facade")
    func queueBootstrapReceiptReconciliationHasDedicatedOwner() throws {
        let storeSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/BatchQueueStore.swift"
        )
        let reconcilerSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/BatchQueueBootstrapReceiptReconciler.swift"
        )

        #expect(
            reconcilerSource.contains(
                "struct BatchQueueBootstrapReceiptReconciler"
            )
        )
        #expect(
            reconcilerSource.contains(
                "func reconcileCommittedReceipts"
            )
        )
        #expect(reconcilerSource.contains("func pruneReceipts"))
        #expect(
            !storeSource.contains(
                "func reconcileCommittedPhotoLibraryReceiptsDuringBootstrap"
            )
        )
        #expect(
            !storeSource.contains(
                "func reconcileSaveReceiptsWithPersistedJobsDuringBootstrap"
            )
        )
    }

    @Test("queue bootstrap resume normalization is isolated from the presentation facade")
    func queueBootstrapResumeNormalizationHasDedicatedOwner() throws {
        let storeSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/BatchQueueStore.swift"
        )
        let normalizerSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/BatchQueueBootstrapRecoveryNormalizer.swift"
        )

        #expect(
            normalizerSource.contains(
                "struct BatchQueueBootstrapRecoveryNormalizer"
            )
        )
        #expect(normalizerSource.contains("func normalize"))
        #expect(
            !storeSource.contains(
                "func unresolvedPhotoLibrarySaveTaskIDsDuringBootstrap"
            )
        )
        #expect(!storeSource.contains("persistence.normalizeJobsForResume("))
    }

    @Test("queue recovery diagnostics have one reporting owner")
    func queueRecoveryDiagnosticsHaveOneReportingOwner() throws {
        let storeSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/BatchQueueStore.swift"
        )
        let reporterSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/BatchQueueRecoveryDiagnosticsReporter.swift"
        )

        #expect(
            reporterSource.contains(
                "enum BatchQueueRecoveryDiagnosticsReporter"
            )
        )
        #expect(reporterSource.contains("processing.recovery."))
        #expect(!storeSource.contains("processing.recovery."))
    }

    @Test("queue notifications depend on a narrow runtime port, not the presentation facade")
    func queueNotificationsUseDedicatedRuntimePort() throws {
        let notificationsSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/BatchQueueNotifications.swift"
        )
        let runtimeSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Application/BatchQueueNotificationRuntime.swift"
        )

        #expect(
            runtimeSource.contains(
                "protocol BatchQueueNotificationRuntime"
            )
        )
        #expect(
            notificationsSource.contains(
                "any BatchQueueNotificationRuntime"
            )
        )
        #expect(!notificationsSource.contains("BatchQueueStore"))
        #expect(runtimeSource.contains("notificationJob"))
        #expect(runtimeSource.contains("markStartNotificationSent"))
        #expect(runtimeSource.contains("markFinalNotificationSent"))
        #expect(
            runtimeSource.contains(
                "releaseNotificationAttachmentsIfCovered"
            )
        )
    }

    @Test("queue execution coordination depends on a processing runtime port")
    func queueExecutionCoordinationUsesDedicatedRuntimePort() throws {
        let executionSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/BatchQueueExecution.swift"
        )
        let coordinatorSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/BatchQueueCoordinator.swift"
        )
        let runtimeSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Application/BatchQueueProcessingRuntime.swift"
        )

        #expect(
            runtimeSource.contains(
                "protocol BatchQueueProcessingRuntime"
            )
        )
        #expect(runtimeSource.contains("nextPendingTaskReference"))
        #expect(runtimeSource.contains("processingConfiguration"))
        #expect(runtimeSource.contains("processingLoopDidFinish"))
        #expect(
            executionSource.contains(
                "any BatchQueueProcessingRuntime"
            )
        )
        #expect(
            coordinatorSource.contains(
                "any BatchQueueProcessingRuntime"
            )
        )
        #expect(!executionSource.contains("BatchQueueStore"))
        #expect(!coordinatorSource.contains("BatchQueueStore"))
    }

    @Test("background queue execution uses a narrow runtime port")
    func backgroundQueueExecutionUsesDedicatedRuntimePort() throws {
        let workerSource = try Self.source(
            at: "Source/MemoMark/MemoMark/iOS/App/BackgroundBatchQueueWorker.swift"
        )
        let coordinatorSource = try Self.source(
            at: "Source/MemoMark/MemoMark/iOS/App/MemoMarkBackgroundTaskCoordinator.swift"
        )
        let runtimeSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Application/BackgroundQueueRuntime.swift"
        )

        #expect(runtimeSource.contains("protocol BackgroundQueueRuntime"))
        #expect(runtimeSource.contains("startProcessingIfNeeded"))
        #expect(runtimeSource.contains("stopProcessingForBackgroundExpiration"))
        #expect(workerSource.contains("any BackgroundQueueRuntime"))
        #expect(!workerSource.contains("BatchQueueStore"))
        #expect(!coordinatorSource.contains("BatchQueueStore"))
    }

    @Test("production card building does not depend on preview presentation")
    func productionCardBuildingDoesNotDependOnPreviewPresentation() throws {
        let processorSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/BatchTaskProcessor.swift"
        )

        #expect(!processorSource.contains("BuildPreviewIntent("))
        #expect(!processorSource.contains("PreviewCoordinator"))
        #expect(
            processorSource.contains(
                "BuildRecordCardTransaction"
            )
        )

        let transactionSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Application/BuildRecordCardTransaction.swift"
        )
        #expect(
            transactionSource.contains(
                "RecordCardBuildService"
            )
        )
        #expect(!transactionSource.contains("PreviewCoordinator"))
        #expect(!transactionSource.contains("BuildPreviewIntent"))
        #expect(!transactionSource.contains("@MainActor"))
        #expect(
            processorSource.contains(
                "buildRecordCard.buildCardOffMainThread"
            )
        )
    }

    @Test("Live Photo production shares the application card-build transaction")
    func livePhotoProductionSharesCardBuildTransaction() throws {
        let processorSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/LivePhotoBatchTaskProcessor.swift"
        )
        let queueSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/BatchQueueExecution.swift"
        )

        #expect(processorSource.contains("private let buildRecordCard"))
        #expect(processorSource.contains("BuildRecordCardTransaction? = nil"))
        #expect(!processorSource.contains("private let cardBuildService"))
        #expect(!processorSource.contains("cardBuildService.buildCard"))
        #expect(processorSource.contains("buildRecordCard.buildCardOffMainThread"))
        #expect(queueSource.contains("buildRecordCard:\n                resolvedBuildRecordCard"))
        #expect(!queueSource.contains("BatchProcessingCoordinator"))
    }

    @Test("static and Live Photo queue routes share the composed Photo Library exporter")
    func queueProductionRoutesSharePhotoLibraryExporter() throws {
        let executionSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/BatchQueueExecution.swift"
        )
        let storeSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/BatchQueueStore.swift"
        )
        let environmentSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Architecture/AppEnvironment.swift"
        )

        #expect(executionSource.contains("photoLibraryExportService:"))
        #expect(executionSource.contains("resolvedPhotoLibraryExportService"))
        #expect(
            executionSource.contains(
                "photoLibraryExportService:\n                resolvedPhotoLibraryExportService"
            )
        )
        #expect(storeSource.contains("photoLibraryExportService:"))
        #expect(
            environmentSource.contains(
                "photoLibraryExportService:\n                    photoLibraryExportService"
            )
        )
    }

    @Test("Configuration Center receives its save transaction from composition")
    func configurationSaveTransactionIsComposedOutsideTheView() throws {
        let environmentSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Architecture/AppEnvironment.swift"
        )
        let rootSource = try Self.source(
            at: "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView.swift"
        )
        let dependenciesSource = try Self.source(
            at: "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterDependencies.swift"
        )

        #expect(
            environmentSource.contains(
                "saveConfiguration:\n        SaveConfigurationTransaction"
            )
        )
        #expect(
            environmentSource.contains(
                "loadProductionConfigurationSnapshot:\n        LoadProductionConfigurationSnapshotTransaction"
            )
        )
        #expect(rootSource.contains("let saveConfiguration: SaveConfigurationTransaction"))
        #expect(rootSource.contains("SaveConfigurationTransaction"))
        #expect(rootSource.contains("loadProductionConfigurationSnapshot"))
        #expect(
            rootSource.contains(
                "LoadProductionConfigurationSnapshotTransaction"
            )
        )
        #expect(dependenciesSource.contains("saveConfiguration = runtime.environment.transactions.saveConfiguration"))
        #expect(!rootSource.contains("SettingsService()"))
        #expect(
            !rootSource.contains(
                "SaveConfigurationTransaction(\n            configurationCoordinator:"
            )
        )
    }

    @Test("new output album resolution never constructs a detached PhotoKit exporter")
    func newOutputAlbumResolutionRequiresComposedExportCoordinator() throws {
        let intentSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Intent/ExportAlbumIntents.swift"
        )

        #expect(!intentSource.contains("PhotoLibraryExportService()"))
        #expect(
            intentSource.contains(
                "without an active export coordinator"
            )
        )
    }

    @Test("root lifecycle coordinators use responsibility-based names")
    func rootLifecycleCoordinatorsUseStableNames() throws {
        let rootSource = try Self.source(
            at: "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView.swift"
        )
        let runtimeCompositionSource = try Self.source(
            at: "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView+RuntimeComposition.swift"
        )
        let composedSources = rootSource + runtimeCompositionSource

        for typeName in [
            "PhotoIntakeRuntimeCoordinator",
            "LogoAssetRuntimeCoordinator",
            "OutputAlbumRuntimeCoordinator",
            "DiagnosticsRefreshCoordinator",
            "PreviewSyncCoordinator",
            "DraftRuntimeCoordinator"
        ] {
            #expect(composedSources.contains(typeName))
        }
        #expect(!composedSources.contains("V1PhotoIntakeRuntimeCoordinator"))
        #expect(!composedSources.contains("V1LogoAssetRuntimeCoordinator"))
        #expect(!composedSources.contains("V1OutputAlbumRuntimeCoordinator"))
        #expect(!composedSources.contains("V1DiagnosticsRefreshCoordinator"))
        #expect(!composedSources.contains("V1PreviewSyncCoordinator"))
        #expect(!composedSources.contains("V1DraftRuntimeCoordinator"))

        let draftRuntimeSource = try Self.source(
            at: "Source/MemoMark/MemoMark/iOS/Views/V1DraftRuntimeCoordinator.swift"
        )
        #expect(draftRuntimeSource.contains("DraftOrchestrationCoordinator"))
        #expect(!draftRuntimeSource.contains("V1DraftOrchestrationCoordinator"))
    }

    @Test("configuration editor buffers have one root state owner")
    func configurationEditorBuffersUseSingleStateOwner() throws {
        let rootSource = try Self.source(
            at: "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView.swift"
        )

        #expect(rootSource.contains("editorDraftState = ConfigurationEditorDraftState()"))
        #expect(!rootSource.contains("private var regionDrafts: [CardRegion: MemoryCardEditorDraft] = [:]"))
        #expect(
            !rootSource.contains(
                "@State\n    private var regionDraftsByPresentationStyle:"
            )
        )
        #expect(rootSource.contains("editorDraftState.replace("))
    }

    @Test("configuration application transport uses stable responsibility names")
    func configurationTransportUsesStableNames() throws {
        let transactionSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Application/SaveConfigurationTransaction.swift"
        )
        #expect(transactionSource.contains("ConfigurationSaveRequest"))
        #expect(transactionSource.contains("ConfigurationSaveReceipt"))
        #expect(transactionSource.contains("OutputAlbumSelectionRequest"))
        #expect(!transactionSource.contains("V1ConfigurationSaveRequest"))
        #expect(!transactionSource.contains("V1ConfigurationSaveReceipt"))
        #expect(!transactionSource.contains("V1OutputAlbumSelectionRequest"))
        #expect(!transactionSource.contains("ResolveV1OutputAlbumSelectionIntent"))
        #expect(!transactionSource.contains("SaveV1ConfigurationIntent"))

        let saveIntentSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Intent/ConfigurationSaveIntents.swift"
        )
        #expect(saveIntentSource.contains("struct ConfigurationSaveRequest"))
        #expect(saveIntentSource.contains("struct SaveConfigurationIntent"))
        #expect(saveIntentSource.contains(".saveConfiguration("))
    }

    @Test("configuration bootstrap reads use stable responsibility names")
    func configurationBootstrapReadsUseStableNames() throws {
        let serviceSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/SettingsService.swift"
        )
        let repositorySource = try Self.source(
            at: "Source/MemoMark/MemoMark/Repositories/SettingsRepository.swift"
        )

        #expect(serviceSource.contains("struct ConfigurationBootstrapReadState"))
        #expect(serviceSource.contains("func loadConfigurationBootstrapReadState()"))
        #expect(serviceSource.contains("func loadSelectedSubjectResult()"))
        #expect(serviceSource.contains("func loadSubjectLibraryResult()"))
        #expect(serviceSource.contains("func reloadBootstrapState()"))
        #expect(serviceSource.contains("let mediaOutputMode: MediaOutputMode"))
        #expect(repositorySource.contains(".loadConfigurationBootstrapReadState()"))
        #expect(!repositorySource.contains(".loadV1BootstrapReadState()"))
    }

    @Test("configuration bootstrap transport has no inactive stage-era source adapter")
    func configurationBootstrapTransportHasNoInactiveStageEraAdapter() throws {
        let serviceSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/SettingsService.swift"
        )

        #expect(serviceSource.contains("struct ConfigurationBootstrapReadState"))
        #expect(
            !serviceSource.contains(
                "typealias V1ConfigurationBootstrapReadState"
            )
        )
        #expect(!serviceSource.contains("func loadV1BootstrapReadState()"))
    }

    @Test("shared batch readiness reads use stable responsibility names")
    func sharedBatchReadinessUsesStableNames() throws {
        let providerSource = try Self.source(
            at: "Source/MemoMark/MemoMark/App/BatchConfigurationSnapshotProvider.swift"
        )
        let sharedServiceSource = try Self.source(
            at: "Source/MemoMark/MemoMark/App/SharedBatchConfigurationSnapshotService.swift"
        )
        let shareExtensionSource = try Self.source(
            at: "Source/MemoMark/MemoMark/iOS/ShareExtension/MemoMarkShareExtensionViewController.swift"
        )

        #expect(providerSource.contains("struct SavedConfigurationReadiness"))
        #expect(providerSource.contains("func loadConfigurationReadiness()"))
        #expect(sharedServiceSource.contains("func loadConfigurationReadiness()"))
        #expect(sharedServiceSource.contains(".loadConfigurationReadiness()"))
        #expect(shareExtensionSource.contains(".loadConfigurationReadiness()"))
        #expect(!shareExtensionSource.contains(".loadV1ConfigurationReadiness()"))
    }

    @Test("domain processing remains independent from persistence infrastructure")
    func domainProcessingDoesNotOwnPersistenceInfrastructure() throws {
        let domainURL = Self.repositoryRoot
            .appendingPathComponent(
                "Source/MemoMark/MemoMark/Domain/Processing"
            )
        let sourceFiles = try FileManager.default
            .contentsOfDirectory(
                at: domainURL,
                includingPropertiesForKeys: nil
            )
            .filter { $0.pathExtension == "swift" }
        let combinedSource = try sourceFiles
            .map {
                try String(
                    contentsOf: $0,
                    encoding: .utf8
                )
            }
            .joined(separator: "\n")

        #expect(!combinedSource.contains("BatchQueuePersistence"))
        #expect(!combinedSource.contains("PhotoLibrarySaveReceiptStore"))
        #expect(!combinedSource.contains("UserDefaults"))
    }

    @Test("production queue mutations have one actor-owned durable path")
    func productionQueueMutationsHaveOneActorOwnedDurablePath() throws {
        let storeSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/BatchQueueStore.swift"
        )
        let runtimeSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Application/BatchTaskExecutionRuntime.swift"
        )
        let processorSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/BatchTaskProcessor.swift"
        )

        #expect(storeSource.contains("BatchQueueDurableLedger"))
        #expect(storeSource.contains("private func persistJobsDuringBootstrap"))
        #expect(
            storeSource.components(
                separatedBy: "persistence.persistJobs"
            ).count == 2
        )
        #expect(!runtimeSource.contains("persist: Bool"))
        #expect(!processorSource.contains("persist: false"))
        #expect(
            !storeSource.contains(
                "_ = persistJobsDuringBootstrap"
            )
        )
    }

    @Test("notification thumbnails leave the UI actor before ImageIO work")
    func notificationThumbnailGenerationUsesOffMainThreadBoundary() throws {
        let processorSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/BatchTaskProcessor.swift"
        )
        let lifecycleSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/BatchTaskResourceLifecycle.swift"
        )

        #expect(
            processorSource.contains(
                "makeNotificationAttachmentOffMainThreadIfNeeded"
            )
        )
        #expect(
            lifecycleSource.contains(
                "Task.detached(priority: .utility)"
            )
        )
        #expect(
            lifecycleSource.contains(
                "generateNotificationAttachment"
            )
        )
    }

    @Test("Photo Library writers use the actor receipt ledger")
    func photoLibraryWritersUseActorReceiptLedger() throws {
        let exportSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/PhotoLibraryExportService.swift"
        )
        let livePhotoSource = try Self.source(
            at: "Source/MemoMark/MemoMark/MediaPipelineVNext/PhotoKitLivePhotoAssetWriter.swift"
        )
        let ledgerSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Infrastructure/Persistence/PhotoLibrarySaveReceiptLedger.swift"
        )

        for writerSource in [exportSource, livePhotoSource] {
            #expect(
                writerSource.contains(
                    "PhotoLibrarySaveReceiptLedger"
                )
            )
            #expect(
                writerSource.contains(
                    "placeholderIntentWriter.record("
                )
            )
            for forbiddenCall in [
                "receiptStore.recordIntent(",
                "receiptStore.remove",
                "receiptStore.assetIdentifier(",
                "receiptStore.pendingAssetIdentifier(",
                "receiptStore.record(",
                "receiptStore.markCommitted(",
                "receiptStore.ensureCommitted(",
                "receiptStore.materializePendingIntent("
            ] {
                #expect(!writerSource.contains(forbiddenCall))
            }
        }

        #expect(
            ledgerSource.contains(
                "actor PhotoLibrarySaveReceiptLedger"
            )
        )
        #expect(
            ledgerSource.contains(
                "PhotoLibraryPendingIntentPlaceholderWriter"
            )
        )
    }

    @Test("PhotoKit receipt visibility lookup does not own persistence")
    func photoKitReceiptVisibilityLookupDoesNotOwnPersistence() throws {
        let receiptSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/PhotoLibrarySaveReceiptStore.swift"
        )
        let locatorRange = try #require(
            receiptSource.range(
                of: "struct PhotoLibrarySaveReceiptAssetLocator:"
            )
        )
        let storeRange = try #require(
            receiptSource.range(
                of: "nonisolated final class PhotoLibrarySaveReceiptStore:",
                range: locatorRange.upperBound..<receiptSource.endIndex
            )
        )
        let locatorSource = receiptSource[
            locatorRange.lowerBound..<storeRange.lowerBound
        ]

        #expect(
            locatorSource.contains(
                "recordedAssetIdentifier: String?"
            )
        )
        #expect(
            locatorSource.contains(
                "pendingAssetIdentifier: String?"
            )
        )
        #expect(
            !locatorSource.contains(
                "PhotoLibrarySaveReceiptStore"
            )
        )
    }

    @Test("static and Live Photo writers share the PhotoKit transaction gateway")
    func photoLibraryWritersShareTransactionGateway() throws {
        let exportSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/PhotoLibraryExportService.swift"
        )
        let livePhotoSource = try Self.source(
            at: "Source/MemoMark/MemoMark/MediaPipelineVNext/PhotoKitLivePhotoAssetWriter.swift"
        )
        let gatewaySource = try Self.source(
            at: "Source/MemoMark/MemoMark/Infrastructure/PhotoLibrary/PhotoLibraryTransactionGateway.swift"
        )

        for writerSource in [exportSource, livePhotoSource] {
            #expect(
                writerSource.contains(
                    "PhotoLibraryTransactionGateway"
                )
            )
            #expect(
                !writerSource.contains(
                    "PHPhotoLibrary.shared().performChanges"
                )
            )
            #expect(
                !writerSource.contains(
                    "PHAsset.fetchAssets("
                )
            )
            #expect(
                !writerSource.contains(
                    "PHAssetCollection.fetchAssetCollections("
                )
            )
        }

        #expect(
            gatewaySource.contains(
                "final class PhotoLibraryTransactionGateway"
            )
        )
        #expect(
            gatewaySource.contains(
                "PHPhotoLibrary.shared().performChanges"
            )
        )
    }

    @Test("static output metadata readback uses the shared PhotoKit gateway")
    func staticOutputMetadataReadbackUsesSharedPhotoKitGateway() throws {
        let exportSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/PhotoLibraryExportService.swift"
        )
        let gatewaySource = try Self.source(
            at: "Source/MemoMark/MemoMark/Infrastructure/PhotoLibrary/PhotoLibraryTransactionGateway.swift"
        )

        #expect(
            exportSource.contains(
                "photoLibraryGateway\n                .exportPhotoResourceToTemporaryFile("
            )
        )
        #expect(!exportSource.contains("PHAssetResource.assetResources"))
        #expect(
            gatewaySource.contains(
                "func exportPhotoResourceToTemporaryFile("
            )
        )
        #expect(gatewaySource.contains("PHAssetResource.assetResources"))
        #expect(gatewaySource.contains("PHAssetResourceManager.default()"))
    }

    @Test("album preparation shares the PhotoKit save gate")
    func albumPreparationSharesPhotoLibrarySaveGate() throws {
        let exportSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Services/PhotoLibraryExportService.swift"
        )
        let ensureAlbumStart = try #require(
            exportSource.range(of: "func ensureAlbum(\n        named title: String")
        )
        let ensureAlbumEnd = exportSource.range(
            of: "\n    func saveImage(",
            range: ensureAlbumStart.upperBound..<exportSource.endIndex
        )?.lowerBound ?? exportSource.endIndex
        let ensureAlbumSource = exportSource[
            ensureAlbumStart.lowerBound..<ensureAlbumEnd
        ]

        #expect(
            ensureAlbumSource.contains(
                "PhotoLibrarySaveGate.shared.run"
            )
        )
    }

    @Test("configuration output target uses a responsibility-based declaration")
    func configurationOutputTargetUsesResponsibilityBasedDeclaration() throws {
        let source = try Self.source(
            at: "Source/MemoMark/MemoMark/Intent/ExportAlbumIntents.swift"
        )
        let transportSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Application/ConfigurationTransportTypes.swift"
        )

        #expect(source.contains("enum ConfigurationOutputTarget:"))
        #expect(!source.contains("enum V1IOSOutputTarget:"))
        #expect(source.contains("case automatic"))
        #expect(source.contains("case applePhotos"))
        #expect(source.contains("case existingAlbum"))
        #expect(source.contains("case newAlbum"))
        #expect(!transportSource.contains("ConfigurationOutputTarget ="))
    }

    @Test("configuration output target preserves persisted raw values")
    func configurationOutputTargetPreservesPersistedRawValues() {
        #expect(ConfigurationOutputTarget.automatic.rawValue == "automatic")
        #expect(ConfigurationOutputTarget.applePhotos.rawValue == "applePhotos")
        #expect(
            ConfigurationOutputTarget.existingAlbum.rawValue
            == "existingAlbum"
        )
        #expect(ConfigurationOutputTarget.newAlbum.rawValue == "newAlbum")
    }

    @Test("media output mode uses a responsibility-based declaration")
    func mediaOutputModeUsesResponsibilityBasedDeclaration() throws {
        let source = try Self.source(
            at: "Source/MemoMark/MemoMark/Intent/ExportAlbumIntents.swift"
        )
        let transportSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Application/ConfigurationTransportTypes.swift"
        )

        #expect(source.contains("enum MediaOutputMode:"))
        #expect(!source.contains("enum V1MediaOutputMode:"))
        #expect(source.contains("case originalFormat"))
        #expect(source.contains("case staticImage"))
        #expect(!transportSource.contains("MediaOutputMode ="))
    }

    @Test("media output mode preserves persisted raw values")
    func mediaOutputModePreservesPersistedRawValues() {
        #expect(MediaOutputMode.originalFormat.rawValue == "originalFormat")
        #expect(MediaOutputMode.staticImage.rawValue == "staticImage")
    }

    @Test("configuration logo mode uses a responsibility-based declaration")
    func configurationLogoModeUsesResponsibilityBasedDeclaration() throws {
        let source = try Self.source(
            at: "Source/MemoMark/MemoMark/iOS/Views/V1LogoMode.swift"
        )
        let transportSource = try Self.source(
            at: "Source/MemoMark/MemoMark/Application/ConfigurationTransportTypes.swift"
        )

        #expect(source.contains("enum ConfigurationLogoMode:"))
        #expect(!source.contains("enum V1LogoMode:"))
        #expect(source.contains("case appleMini"))
        #expect(source.contains("case customUpload"))
        #expect(source.contains("case subjectAvatar"))
        #expect(!transportSource.contains("ConfigurationLogoMode ="))
    }

    @Test("configuration logo mode preserves persisted raw values")
    func configurationLogoModePreservesPersistedRawValues() {
        #expect(ConfigurationLogoMode.appleMini.rawValue == "appleMini")
        #expect(ConfigurationLogoMode.customUpload.rawValue == "customUpload")
        #expect(
            ConfigurationLogoMode.subjectAvatar.rawValue
            == "subjectAvatar"
        )
    }

    @Test("root state owners do not retain stage-labelled compatibility aliases")
    func rootStateOwnersDoNotRetainStageLabelledCompatibilityAliases() throws {
        let presentation = try Self.source(
            at: "Source/MemoMark/MemoMark/iOS/Views/RootPresentationState.swift"
        )
        let lifecycle = try Self.source(
            at: "Source/MemoMark/MemoMark/iOS/Views/RootLifecycleState.swift"
        )
        let configuration = try Self.source(
            at: "Source/MemoMark/MemoMark/iOS/Views/RootConfigurationProjectionState.swift"
        )

        #expect(presentation.contains("struct RootPresentationState"))
        #expect(lifecycle.contains("struct RootLifecycleState"))
        #expect(configuration.contains("struct RootConfigurationProjectionState"))
        #expect(!presentation.contains("typealias V1RootPresentationState"))
        #expect(!lifecycle.contains("typealias V1RootLifecycleState"))
        #expect(
            !configuration.contains(
                "typealias V1RootConfigurationProjectionState"
            )
        )
    }

    private static func source(
        at repositoryRelativePath: String
    ) throws -> String {
        try String(
            contentsOf:
                repositoryRoot
                .appendingPathComponent(
                    repositoryRelativePath
                ),
            encoding: .utf8
        )
    }

    private static var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
#endif
