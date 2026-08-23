#if !PHOTOMEMO_SHARE_EXTENSION
import Combine
import Foundation
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("Share drain migration regression", .serialized)
struct ShareDrainMigrationRegressionTests {

    @MainActor
    @Test("SubmitExternalURLsIntent refreshes configuration and keeps only supported unique image inputs")
    func submitExternalURLsIntentRefreshesConfigurationAndFiltersInputs() async throws {

        let context = try Self.makeContext(
            named:
                "PhotoMemo.ShareDrainMigrationRegressionTests.Submit.\(UUID().uuidString)"
        )
        defer { Self.cleanup(context) }

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneJPEG
            )
        let unsupportedURL =
            context.rootDirectoryURL
            .appendingPathComponent("notes.txt")

        try Data("not-an-image".utf8).write(
            to: unsupportedURL
        )

        let latestSnapshot =
            context.environment.repositories
            .configuration
            .loadDefaultBatchConfigurationSnapshot()
        var staleSnapshot =
            latestSnapshot
        staleSnapshot.selectedAlbumIdentifier =
            "stale-album"
        staleSnapshot.photoDescriptionOverride =
            "stale-description"

        context.environment.externalIntakeCenter
            .updateDefaultConfiguration(
                staleSnapshot
            )

        let importSummary =
            ExternalPhotoImportSummary(
                importedCount: 1,
                skippedCount: 1,
                failedCount: 1
            )
        let result =
            await SubmitExternalURLsIntent(
                urls: [
                    sourceURL,
                    sourceURL,
                    unsupportedURL
                ],
                importSummary:
                    importSummary,
                source: .shareExtension,
                coordinator:
                    context.environment
                    .coordinators.share
            )
            .execute()

        switch result {
        case .success(let receipt):
            #expect(
                receipt.requestedURLCount == 3
            )
            #expect(
                receipt.source == .shareExtension
            )
        case .failure(let error):
            Issue.record(
                "Expected submit intent to succeed, got \(error.message)"
            )
        }

        let drainedResult =
            context.environment.coordinators
            .share
            .drainPendingRequests()

        switch drainedResult {
        case .success(let requests):
            #expect(requests.count == 1)

            let request =
                try #require(
                    requests.first
                )

            #expect(
                request.launchSource
                == .shareExtension
            )
            #expect(
                request.importSummary
                == importSummary
            )
            #expect(
                request.configurationSnapshot
                    .selectedAlbumIdentifier
                == latestSnapshot
                    .selectedAlbumIdentifier
            )
            #expect(
                request.configurationSnapshot
                    .photoDescriptionOverride
                == latestSnapshot
                    .photoDescriptionOverride
            )
            #expect(
                request.configurationSnapshot
                    .selectedAlbumIdentifier
                != staleSnapshot
                    .selectedAlbumIdentifier
            )
            #expect(
                request.configurationSnapshot
                    .photoDescriptionOverride
                != staleSnapshot
                    .photoDescriptionOverride
            )
            #expect(request.urls.count == 1)
            #expect(
                request.items?.count == 1
            )

            let managedURL =
                try #require(
                    request.urls.first
                )

            #expect(
                managedURL.path.hasPrefix(
                    context.intakeDirectoryURL.path
                )
            )
            #expect(
                FileManager.default.fileExists(
                    atPath: managedURL.path
                )
            )
        case .failure(let error):
            Issue.record(
                "Expected drain to succeed, got \(error.message)"
            )
        }
    }

    @MainActor
    @Test("Queue persistence failure keeps the Share request pending")
    func queuePersistenceFailureKeepsShareRequestPending() throws {
        let suiteName =
            "PhotoMemo.ShareDrainMigrationRegressionTests.QueueFailure.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        let rootDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(suiteName, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: rootDirectoryURL)
        }
        let settingsService = SettingsService(
            defaults: defaults,
            configurationLibraryBaseDirectoryURL: rootDirectoryURL
        )
        let queueStore = BatchQueueStore(
            defaults: defaults,
            settingsService: settingsService,
            persistence: BatchQueuePersistence(
                backend: ShareQueueFailingPersistenceBackend()
            )
        )
        let environment = AppEnvironment.live(
            defaults: defaults,
            configurationLibraryBaseDirectoryURL: rootDirectoryURL,
            intakeDirectoryURL: rootDirectoryURL
                .appendingPathComponent("ExternalIntake", isDirectory: true),
            batchQueueStore: queueStore
        )
        let runtime = PhotoMemoAppRuntime(environment: environment)
        let sourceURL = try SyntheticFixtureLibrary.fixtureURL(.iphoneJPEG)

        runtime.handleExternalURLs(
            [sourceURL],
            source: .shareExtension
        )
        runtime.flushExternalRequests()

        #expect(queueStore.jobs.isEmpty)
        #expect(
            !environment.externalIntakeCenter
                .drainPendingRequests()
                .isEmpty
        )
    }

    @MainActor
    @Test("Direct queue preparation cannot reenter foreground processing through revision")
    func directPreparationDoesNotStartProcessingThroughRevision() async throws {
        let suiteName =
            "PhotoMemo.ShareDrainMigrationRegressionTests.Preparation.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        let rootDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(suiteName, isDirectory: true)
        let intakeDirectoryURL = rootDirectoryURL
            .appendingPathComponent("ExternalIntake", isDirectory: true)
        let externalIntakeStore = ExternalPhotoIntakeStore(
            defaults: defaults,
            intakeDirectoryURL: intakeDirectoryURL
        )
        let settingsService = SettingsService(
            defaults: defaults,
            configurationLibraryBaseDirectoryURL: rootDirectoryURL
        )
        let queueStore = BatchQueueStore(
            defaults: defaults,
            settingsService: settingsService,
            externalIntakeStore: externalIntakeStore,
            automaticallyStartsProcessing: false
        )
        let environment = AppEnvironment.live(
            defaults: defaults,
            configurationLibraryBaseDirectoryURL: rootDirectoryURL,
            intakeDirectoryURL: intakeDirectoryURL,
            batchQueueStore: queueStore
        )
        let runtime = PhotoMemoAppRuntime(environment: environment)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: rootDirectoryURL)
        }

        runtime.handleExternalURLs(
            [try SyntheticFixtureLibrary.fixtureURL(.iphoneJPEG)],
            source: .shareExtension
        )
        let revisionObserver = environment.externalIntakeCenter
            .$revision
            .dropFirst()
            .sink { _ in
                runtime.refreshExternalIntakeState()
            }

        let result = runtime.flushExternalRequests()
        try await Task.sleep(for: .milliseconds(200))
        withExtendedLifetime(revisionObserver) {}

        #expect(result == .prepared)
        #expect(queueStore.jobs.first?.tasks.first?.phase == .queued)
        #expect(!queueStore.isProcessing)
    }

    @MainActor
    @Test("Corrupt Share metadata suppresses managed orphan cleanup")
    func corruptShareMetadataSuppressesManagedOrphanCleanup() throws {
        let context = try Self.makeContext(
            named:
                "PhotoMemo.ShareDrainMigrationRegressionTests.CorruptCleanup.\(UUID().uuidString)"
        )
        defer { Self.cleanup(context) }
        let requestDirectoryURL = context.intakeDirectoryURL
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: requestDirectoryURL,
            withIntermediateDirectories: true
        )
        let managedURL = requestDirectoryURL
            .appendingPathComponent("recoverable.jpg")
        try Data("recoverable".utf8).write(to: managedURL)
        context.defaults.set(
            Data("corrupt-request-metadata".utf8),
            forKey: ExternalIntakeRequestStore.storageKey
        )
        let runtime = PhotoMemoAppRuntime(
            environment: context.environment
        )

        runtime.refreshExternalIntakeState()

        #expect(runtime.externalIntakeCenter.intakePersistenceError != nil)
        #expect(
            FileManager.default.fileExists(atPath: managedURL.path)
        )
    }

    @MainActor
    @Test("QueueCoordinator enqueues drained share requests without changing launch source or payload metadata")
    func queueCoordinatorEnqueuesDrainedShareRequestsWithoutChangingSemantics() async throws {

        let context = try Self.makeContext(
            named:
                "PhotoMemo.ShareDrainMigrationRegressionTests.Enqueue.\(UUID().uuidString)"
        )
        defer { Self.cleanup(context) }

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneJPEG
            )
        let importSummary =
            ExternalPhotoImportSummary(
                importedCount: 1,
                skippedCount: 0,
                failedCount: 0
            )

        _ =
            await SubmitExternalURLsIntent(
                urls: [sourceURL],
                importSummary:
                    importSummary,
                source: .shareExtension,
                coordinator:
                    context.environment
                    .coordinators.share
            )
            .execute()

        let request =
            try #require(
                context.environment.coordinators
                .share
                .drainPendingRequests()
                .value?
                .first
            )
        let payload =
            try #require(
                request.intakePayloads.first
            )
        let result =
            context.environment.coordinators
            .queue
            .enqueue(
                payloads:
                    request.intakePayloads,
                configuration:
                    request.configurationSnapshot,
                launchSource:
                    request.launchSource,
                intakeSummary:
                    request.importSummary
            )

        switch result {
        case .success(let job):
            #expect(
                job.launchSource
                == request.launchSource
            )
            #expect(
                job.configuration
                == request.configurationSnapshot
            )
            #expect(
                job.intakeSummary
                == importSummary
            )
            #expect(job.tasks.count == 1)

            let task =
                try #require(
                    job.tasks.first
                )

            #expect(
                task.sourceURL
                == payload.sourceURL
            )
            #expect(
                task.fileName
                == (
                    payload.fileName
                    ?? payload.sourceURL
                        .lastPathComponent
                )
            )
            #expect(
                task.sourceIdentifier
                == payload.sourceIdentifier
            )
            #expect(
                task.contentTypeIdentifier
                == payload.contentTypeIdentifier
            )
            #expect(
                context.environment
                .batchQueueStore.jobs
                .contains {
                    $0.id == job.id
                }
            )
        case .failure(let error):
            Issue.record(
                "Expected queue coordinator to enqueue the drained request, got \(error.message)"
            )
        }
    }

    @MainActor
    @Test("ProcessShareIntent enqueues a drained request without changing request semantics")
    func processShareIntentEnqueuesDrainedRequestWithoutChangingSemantics() async throws {

        let context = try Self.makeContext(
            named:
                "PhotoMemo.ShareDrainMigrationRegressionTests.ProcessIntent.\(UUID().uuidString)"
        )
        defer { Self.cleanup(context) }

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneJPEG
            )
        let receivedAt =
            try #require(
                Calendar(identifier: .gregorian)
                .date(
                    from: DateComponents(
                        year: 2026,
                        month: 6,
                        day: 30,
                        hour: 14,
                        minute: 18
                    )
                )
            )
        let summary =
            ExternalPhotoImportSummary(
                importedCount: 1,
                skippedCount: 0,
                failedCount: 0
            )
        let request =
            ExternalPhotoIntakeRequest(
                launchSource: .shareExtension,
                urls: [sourceURL],
                items: [
                    ExternalPhotoIntakeItem(
                        managedURL: sourceURL,
                        originalFileName:
                            "IMG_9558.HEIC",
                        sourceIdentifier:
                            "asset-local-9558",
                        contentTypeIdentifier:
                            UTType.heic.identifier
                    )
                ],
                configurationSnapshot:
                    context.environment
                    .repositories
                    .configuration
                    .loadDefaultBatchConfigurationSnapshot(),
                importSummary: summary,
                receivedAt: receivedAt
            )

        let result =
            await ProcessShareIntent(
                request: request,
                consumedPayloadKeys: [],
                coordinator:
                    context.environment
                    .coordinators.share
            )
            .execute()

        switch result {
        case .success(let receipt):
            #expect(
                receipt.requestID
                == request.id
            )
            #expect(
                receipt.validPayloadCount
                == 1
            )
            #expect(
                receipt.uniquePayloadCount
                == 1
            )
            #expect(
                receipt.intakeSummary
                == summary
            )

            let job =
                try #require(
                    receipt.job
                )

            #expect(
                job.launchSource
                == request.launchSource
            )
            #expect(
                job.configuration
                == request.configurationSnapshot
            )
            #expect(
                job.intakeSummary
                == summary
            )
            #expect(
                job.title
                == PhotoMemoQueueDisplayFormatter.title(
                    startedAt:
                        receivedAt,
                    photoCount: 1
                )
            )
        case .failure(let error):
            Issue.record(
                "Expected process share intent to succeed, got \(error.message)"
            )
        }
    }

    @MainActor
    @Test("Acknowledgement retry reuses the durable Share job")
    func acknowledgementRetryReusesDurableShareJob() async throws {
        let context = try Self.makeContext(
            named:
                "PhotoMemo.ShareDrainMigrationRegressionTests.IdempotentAdmission.\(UUID().uuidString)"
        )
        defer { Self.cleanup(context) }
        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneJPEG
            )
        let request =
            ExternalPhotoIntakeRequest(
                launchSource: .shareExtension,
                urls: [sourceURL],
                configurationSnapshot:
                    context.environment
                    .repositories
                    .configuration
                    .loadDefaultBatchConfigurationSnapshot()
            )

        let firstReceipt =
            try #require(
                await ProcessShareIntent(
                    request: request,
                    consumedPayloadKeys: [],
                    coordinator:
                        context.environment
                        .coordinators.share
                )
                .execute()
                .value
            )
        let retriedReceipt =
            try #require(
                await ProcessShareIntent(
                    request: request,
                    consumedPayloadKeys: [],
                    coordinator:
                        context.environment
                        .coordinators.share
                )
                .execute()
                .value
            )
        let firstJob = try #require(firstReceipt.job)
        let retriedJob = try #require(retriedReceipt.job)
        let persistedJobs =
            try #require(
                BatchQueuePersistence(
                    defaults: context.defaults
                )
                .loadPersistedJobsResult()
                .value
            )

        #expect(retriedJob.id == firstJob.id)
        #expect(firstJob.intakeRequestID == request.id)
        #expect(
            context.environment.batchQueueStore.jobs.count
            == 1
        )
        #expect(persistedJobs.map(\.id) == [firstJob.id])
        #expect(persistedJobs.first?.intakeRequestID == request.id)
    }

    @MainActor
    @Test("Legacy BatchJob decodes without a Share request identity")
    func legacyBatchJobDecodesWithoutShareRequestIdentity() throws {
        let configuration =
            BatchConfigurationSnapshot(
                template: .classicWhite,
                badge: nil,
                anchor: nil,
                memorySubjectText: "",
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        let encoded = try JSONEncoder().encode(
            BatchJob(
                title: "Legacy",
                configuration: configuration,
                tasks: []
            )
        )
        var object =
            try #require(
                JSONSerialization.jsonObject(
                    with: encoded
                ) as? [String: Any]
            )
        object.removeValue(forKey: "intakeRequestID")
        let legacyData = try JSONSerialization.data(
            withJSONObject: object
        )

        let decoded = try JSONDecoder().decode(
            BatchJob.self,
            from: legacyData
        )

        #expect(decoded.intakeRequestID == nil)
    }

    @MainActor
    @Test("ProcessShareIntent restores canonical memory snapshot stripped by Share Extension transport")
    func processShareIntentRestoresCanonicalMemorySnapshotStrippedByShareExtensionTransport() async throws {
        let context = try Self.makeContext(
            named:
                "PhotoMemo.ShareDrainMigrationRegressionTests.MemorySnapshotRestore.\(UUID().uuidString)"
        )
        defer { Self.cleanup(context) }

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneJPEG
            )
        let canonicalConfiguration =
            context.environment
            .repositories
            .configuration
            .loadDefaultBatchConfigurationSnapshot()
        let transportConfiguration =
            BatchConfigurationSnapshot(
                template:
                    canonicalConfiguration.template,
                badge:
                    canonicalConfiguration.badge,
                anchor: nil,
                memorySubjectText: "小宝",
                locationDisplayConfiguration:
                    canonicalConfiguration
                    .locationDisplayConfiguration,
                shouldWritePhotoDescription:
                    canonicalConfiguration
                    .shouldWritePhotoDescription,
                photoDescriptionOverride:
                    canonicalConfiguration
                    .photoDescriptionOverride,
                selectedAlbumIdentifier:
                    canonicalConfiguration
                    .selectedAlbumIdentifier,
                mediaOutputModeRawValue:
                    canonicalConfiguration
                    .mediaOutputModeRawValue
            )
        let request =
            ExternalPhotoIntakeRequest(
                launchSource: .shareExtension,
                urls: [sourceURL],
                configurationSnapshot:
                    transportConfiguration
            )

        let result =
            await ProcessShareIntent(
                request: request,
                consumedPayloadKeys: [],
                coordinator:
                    context.environment
                    .coordinators.share
            )
            .execute()
        let job =
            try #require(
                result.value?.job
            )

        #expect(
            transportConfiguration
            .canonicalProductionSnapshot == nil
        )
        #expect(
            job.configuration
            .canonicalProductionSnapshot != nil
        )
        #expect(
            job.configuration.template
            == transportConfiguration.template
        )
        #expect(
            job.configuration
            .canonicalProductionSnapshot?
            .memorySubject?
            .resolvedExpressionSubjectText
            == canonicalConfiguration
            .canonicalProductionSnapshot?
            .memorySubject?
            .resolvedExpressionSubjectText
        )
        #expect(
            PhotoMemoShareDiagnostics.loadEvents(
                defaults: context.defaults
            ).contains(where: {
                $0.stage == .configurationCompatibilityRecovery
            })
        )
    }

    @MainActor
    @Test("ProcessShareIntent keeps valid Live Photo bundle directories")
    func processShareIntentKeepsValidLivePhotoBundleDirectories() async throws {

        let context = try Self.makeContext(
            named:
                "PhotoMemo.ShareDrainMigrationRegressionTests.LivePhotoBundle.\(UUID().uuidString)"
        )
        defer { Self.cleanup(context) }

        let livePhotoType =
            try #require(
                UTType("com.apple.live-photo")
            )
        let bundleURL =
            context.rootDirectoryURL
            .appendingPathComponent(
                "SharedLivePhoto.livephoto",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: bundleURL,
            withIntermediateDirectories: true
        )
        try Data("still".utf8).write(
            to:
                bundleURL
                .appendingPathComponent("IMG_6093.HEIC")
        )
        try Data("movie".utf8).write(
            to:
                bundleURL
                .appendingPathComponent("IMG_6093.MOV")
        )
        let request =
            ExternalPhotoIntakeRequest(
                launchSource: .shareExtension,
                urls: [bundleURL],
                items: [
                    ExternalPhotoIntakeItem(
                        managedURL: bundleURL,
                        originalFileName:
                            "SharedLivePhoto.livephoto",
                        contentTypeIdentifier:
                            livePhotoType.identifier
                    )
                ],
                configurationSnapshot:
                    context.environment
                    .repositories
                    .configuration
                    .loadDefaultBatchConfigurationSnapshot()
            )

        let result =
            await ProcessShareIntent(
                request: request,
                consumedPayloadKeys: [],
                coordinator:
                    context.environment
                    .coordinators
                    .share
            )
            .execute()

        let receipt =
            try #require(result.value)
        let task =
            try #require(
                receipt.job?.tasks.first
            )

        #expect(receipt.validPayloadCount == 1)
        #expect(receipt.uniquePayloadCount == 1)
        #expect(receipt.droppedReason == nil)
        #expect(task.sourceURL == bundleURL)
        #expect(task.fileName == "SharedLivePhoto.livephoto")
        #expect(
            task.contentTypeIdentifier
            == livePhotoType.identifier
        )
    }

    @MainActor
    @Test("ProcessShareIntent recovers a unique Live Photo asset identity from a Share static fallback")
    func processShareIntentRecoversUniqueLivePhotoAssetIdentityFromStaticFallback() async throws {

        let context = try Self.makeContext(
            named:
                "PhotoMemo.ShareDrainMigrationRegressionTests.LivePhotoRecovery.\(UUID().uuidString)"
        )
        defer { Self.cleanup(context) }

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneJPEG
            )
        let captureDate =
            try #require(
                Calendar(identifier: .gregorian)
                .date(
                    from: DateComponents(
                        year: 2026,
                        month: 7,
                        day: 11,
                        hour: 9,
                        minute: 18,
                        second: 12
                    )
                )
            )
        let request =
            ExternalPhotoIntakeRequest(
                launchSource: .shareExtension,
                urls: [sourceURL],
                items: [
                    ExternalPhotoIntakeItem(
                        managedURL: sourceURL,
                        originalFileName:
                            "IMG_0935.jpg",
                        sourceIdentifier:
                            "data:not-a-photokit-asset",
                        contentTypeIdentifier:
                            UTType.jpeg.identifier,
                        livePhotoRecoveryHint:
                            LivePhotoStaticFallbackRecoveryHint(
                                originalFileName:
                                    "IMG_0935.jpg",
                                advertisedLivePhotoTypeIdentifier:
                                    "com.apple.live-photo",
                                staticContentTypeIdentifier:
                                    UTType.jpeg.identifier,
                                captureDate:
                                    captureDate,
                                pixelWidth: 4032,
                                pixelHeight: 3024
                            )
                    )
                ],
                configurationSnapshot:
                    context.environment
                    .repositories
                    .configuration
                    .loadDefaultBatchConfigurationSnapshot()
            )
        let coordinator =
            ShareCoordinator(
                externalIntakeCenter:
                    context.environment
                    .externalIntakeCenter,
                externalIntakeStore:
                    context.environment
                    .services
                    .externalIntakeStore,
                configurationRepository:
                    context.environment
                    .repositories
                    .configuration,
                queueRepository:
                    context.environment
                    .repositories
                    .queue,
                livePhotoAssetIdentityResolver:
                    FakeLivePhotoAssetIdentityResolver(
                        resolution:
                            .matched(
                                "live-photo-local-identifier"
                            )
                    )
            )

        let result =
            await ProcessShareIntent(
                request: request,
                consumedPayloadKeys: [],
                coordinator: coordinator
            )
            .execute()

        let receipt =
            try #require(result.value)
        let task =
            try #require(
                receipt.job?.tasks.first
            )

        #expect(
            task.sourceIdentifier
            == "live-photo-local-identifier"
        )
        #expect(
            task.contentTypeIdentifier
            == "com.apple.live-photo"
        )
        #expect(task.fileName == "IMG_0935.jpg")
    }

    @MainActor
    @Test("ProcessShareIntent preserves Live Photo media truth when identity recovery is ambiguous")
    func processShareIntentPreservesLivePhotoTypeWhenRecoveryIsAmbiguous() async throws {

        let context = try Self.makeContext(
            named:
                "PhotoMemo.ShareDrainMigrationRegressionTests.LivePhotoAmbiguous.\(UUID().uuidString)"
        )
        defer { Self.cleanup(context) }

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneJPEG
            )
        let request =
            ExternalPhotoIntakeRequest(
                launchSource: .shareExtension,
                urls: [sourceURL],
                items: [
                    ExternalPhotoIntakeItem(
                        managedURL: sourceURL,
                        originalFileName:
                            "IMG_0935.jpg",
                        sourceIdentifier:
                            "data:not-a-photokit-asset",
                        contentTypeIdentifier:
                            UTType.jpeg.identifier,
                        livePhotoRecoveryHint:
                            LivePhotoStaticFallbackRecoveryHint(
                                originalFileName:
                                    "IMG_0935.jpg",
                                advertisedLivePhotoTypeIdentifier:
                                    "com.apple.live-photo",
                                staticContentTypeIdentifier:
                                    UTType.jpeg.identifier,
                                captureDate: nil,
                                pixelWidth: 4032,
                                pixelHeight: 3024
                            )
                    )
                ],
                configurationSnapshot:
                    context.environment
                    .repositories
                    .configuration
                    .loadDefaultBatchConfigurationSnapshot()
            )
        let coordinator =
            ShareCoordinator(
                externalIntakeCenter:
                    context.environment
                    .externalIntakeCenter,
                externalIntakeStore:
                    context.environment
                    .services
                    .externalIntakeStore,
                configurationRepository:
                    context.environment
                    .repositories
                    .configuration,
                queueRepository:
                    context.environment
                    .repositories
                    .queue,
                livePhotoAssetIdentityResolver:
                    FakeLivePhotoAssetIdentityResolver(
                        resolution:
                            .ambiguous(
                                candidateCount: 2
                            )
                    )
            )

        let result =
            await ProcessShareIntent(
                request: request,
                consumedPayloadKeys: [],
                coordinator: coordinator
            )
            .execute()

        let receipt =
            try #require(result.value)
        let task =
            try #require(
                receipt.job?.tasks.first
            )

        #expect(task.sourceIdentifier == nil)
        #expect(
            task.contentTypeIdentifier
            == "com.apple.live-photo"
        )
    }

    @Test("Live Photo identity matcher only returns a unique high-confidence Live Photo candidate")
    func livePhotoIdentityMatcherRequiresUniqueHighConfidenceLivePhotoCandidate() throws {

        let captureDate =
            try #require(
                Calendar(identifier: .gregorian)
                .date(
                    from: DateComponents(
                        year: 2026,
                        month: 7,
                        day: 11,
                        hour: 9,
                        minute: 18,
                        second: 12
                    )
                )
            )
        let hint =
            LivePhotoStaticFallbackRecoveryHint(
                originalFileName:
                    "IMG_0935.jpg",
                advertisedLivePhotoTypeIdentifier:
                    "com.apple.live-photo",
                staticContentTypeIdentifier:
                    UTType.jpeg.identifier,
                captureDate:
                    captureDate,
                pixelWidth: 4032,
                pixelHeight: 3024
            )
        let exactCandidate =
            LivePhotoAssetIdentityCandidate(
                localIdentifier:
                    "asset-1",
                originalFileNames: [
                    "IMG_0935.HEIC",
                    "IMG_0935.MOV"
                ],
                creationDate:
                    captureDate,
                pixelWidth: 4032,
                pixelHeight: 3024,
                isLivePhoto: true
            )

        #expect(
            LivePhotoAssetIdentityMatcher.resolve(
                hint: hint,
                candidates: [
                    exactCandidate,
                    LivePhotoAssetIdentityCandidate(
                        localIdentifier:
                            "still-1",
                        originalFileNames: [
                            "IMG_0935.HEIC"
                        ],
                        creationDate:
                            captureDate,
                        pixelWidth: 4032,
                        pixelHeight: 3024,
                        isLivePhoto: false
                    )
                ]
            )
            == .matched("asset-1")
        )

        #expect(
            LivePhotoAssetIdentityMatcher.resolve(
                hint: hint,
                candidates: [
                    exactCandidate,
                    LivePhotoAssetIdentityCandidate(
                        localIdentifier:
                            "asset-2",
                        originalFileNames: [
                            "IMG_0935.HEIC"
                        ],
                        creationDate:
                            captureDate,
                        pixelWidth: 4032,
                        pixelHeight: 3024,
                        isLivePhoto: true
                    )
                ]
            )
            == .ambiguous(candidateCount: 2)
        )

        #expect(
            LivePhotoAssetIdentityMatcher.resolve(
                hint: hint,
                candidates: [
                    LivePhotoAssetIdentityCandidate(
                        localIdentifier:
                            "asset-3",
                        originalFileNames: [
                            "IMG_1200.HEIC"
                        ],
                        creationDate:
                            captureDate
                            .addingTimeInterval(600),
                        pixelWidth: 1920,
                        pixelHeight: 1080,
                        isLivePhoto: true
                    )
                ]
            )
            == .notFound
        )
    }

    @Test("Live Photo identity matcher rejects filename and pixel matches without capture-date agreement")
    func livePhotoIdentityMatcherRejectsWeakFilenameAndPixelMatchesWithoutCaptureDateAgreement() throws {

        let captureDate =
            try #require(
                Calendar(identifier: .gregorian)
                .date(
                    from: DateComponents(
                        year: 2026,
                        month: 7,
                        day: 11,
                        hour: 9,
                        minute: 18,
                        second: 12
                    )
                )
            )
        let hint =
            LivePhotoStaticFallbackRecoveryHint(
                originalFileName:
                    "IMG_0935.jpg",
                advertisedLivePhotoTypeIdentifier:
                    "com.apple.live-photo",
                staticContentTypeIdentifier:
                    UTType.jpeg.identifier,
                captureDate:
                    captureDate,
                pixelWidth: 4032,
                pixelHeight: 3024
            )

        #expect(
            LivePhotoAssetIdentityMatcher
                .resolve(
                    hint: hint,
                    candidates: [
                        LivePhotoAssetIdentityCandidate(
                            localIdentifier:
                                "asset-wrong-date",
                            originalFileNames: [
                                "IMG_0935.HEIC",
                                "IMG_0935.MOV"
                            ],
                            creationDate:
                                captureDate
                                .addingTimeInterval(3600),
                            pixelWidth: 4032,
                            pixelHeight: 3024,
                            isLivePhoto: true
                        )
                    ]
                )
            == .notFound
        )

        #expect(
            LivePhotoAssetIdentityMatcher
                .resolve(
                    hint: hint,
                    candidates: [
                        LivePhotoAssetIdentityCandidate(
                            localIdentifier:
                                "asset-missing-date",
                            originalFileNames: [
                                "IMG_0935.HEIC",
                                "IMG_0935.MOV"
                            ],
                            creationDate: nil,
                            pixelWidth: 4032,
                            pixelHeight: 3024,
                            isLivePhoto: true
                        )
                    ]
                )
            == .notFound
        )
    }

    @Test("Live Photo identity matcher recovers a uniquely timed and sized asset when the provider renames the still image")
    func livePhotoIdentityMatcherRecoversRenamedUniqueCandidate() throws {

        let captureDate =
            try #require(
                Calendar(identifier: .gregorian)
                .date(
                    from: DateComponents(
                        year: 2026,
                        month: 7,
                        day: 11,
                        hour: 9,
                        minute: 18,
                        second: 12
                    )
                )
            )
        let hint =
            LivePhotoStaticFallbackRecoveryHint(
                originalFileName:
                    "IMG_0935.jpg",
                advertisedLivePhotoTypeIdentifier:
                    "com.apple.live-photo",
                staticContentTypeIdentifier:
                    UTType.jpeg.identifier,
                captureDate:
                    captureDate,
                pixelWidth: 4032,
                pixelHeight: 3024
            )

        let renamedCandidate =
            LivePhotoAssetIdentityCandidate(
                localIdentifier:
                    "asset-renamed-provider-payload",
                originalFileNames: [
                    "IMG_1200.HEIC",
                    "IMG_1200.MOV"
                ],
                creationDate:
                    captureDate
                    .addingTimeInterval(0.8),
                pixelWidth: 4032,
                pixelHeight: 3024,
                isLivePhoto: true
            )

        #expect(
            LivePhotoAssetIdentityMatcher
                .resolve(
                    hint: hint,
                    candidates: [
                        renamedCandidate
                    ]
                )
            == .matched(
                "asset-renamed-provider-payload"
            )
        )

        #expect(
            LivePhotoAssetIdentityMatcher
                .resolve(
                    hint: hint,
                    candidates: [
                        renamedCandidate,
                        LivePhotoAssetIdentityCandidate(
                            localIdentifier:
                                "asset-equally-plausible",
                            originalFileNames: [
                                "IMG_1201.HEIC",
                                "IMG_1201.MOV"
                            ],
                            creationDate:
                                captureDate
                                .addingTimeInterval(-0.4),
                            pixelWidth: 4032,
                            pixelHeight: 3024,
                            isLivePhoto: true
                        )
                    ]
                )
            == .ambiguous(candidateCount: 2)
        )

        #expect(
            LivePhotoAssetIdentityMatcher
                .resolve(
                    hint: hint,
                    candidates: [
                        LivePhotoAssetIdentityCandidate(
                            localIdentifier:
                                "asset-renamed-but-too-far-away",
                            originalFileNames: [
                                "IMG_1202.HEIC",
                                "IMG_1202.MOV"
                            ],
                            creationDate:
                                captureDate
                                .addingTimeInterval(30),
                            pixelWidth: 4032,
                            pixelHeight: 3024,
                            isLivePhoto: true
                        )
                    ]
                )
            == .notFound
        )
    }

    @Test("Live Photo identity matcher accepts local-time EXIF fallback hints")
    func livePhotoIdentityMatcherAcceptsLocalTimeEXIFFallbackHints() throws {

        let shanghai =
            try #require(
                TimeZone(identifier: "Asia/Shanghai")
            )
        let captureDate =
            try #require(
                LivePhotoStaticFallbackDateParser
                .parse(
                    "2026:07:11 09:18:12",
                    timeZone: shanghai
                )
            )
        let hint =
            LivePhotoStaticFallbackRecoveryHint(
                originalFileName:
                    "IMG_9558.jpg",
                advertisedLivePhotoTypeIdentifier:
                    "com.apple.live-photo",
                staticContentTypeIdentifier:
                    UTType.jpeg.identifier,
                captureDate:
                    captureDate,
                pixelWidth: 4032,
                pixelHeight: 3024
            )
        let candidate =
            LivePhotoAssetIdentityCandidate(
                localIdentifier:
                    "asset-local-shanghai",
                originalFileNames: [
                    "IMG_9558.HEIC",
                    "IMG_9558.MOV"
                ],
                creationDate:
                    captureDate
                    .addingTimeInterval(120),
                pixelWidth: 4032,
                pixelHeight: 3024,
                isLivePhoto: true
            )

        #expect(
            LivePhotoAssetIdentityMatcher
                .resolve(
                    hint: hint,
                    candidates: [
                        candidate
                    ]
                )
            == .matched("asset-local-shanghai")
        )
    }
}

private extension ShareDrainMigrationRegressionTests {

    struct TestContext {

        let suiteName: String

        let defaults: UserDefaults

        let rootDirectoryURL: URL

        let intakeDirectoryURL: URL

        let environment: AppEnvironment
    }

    @MainActor
    static func makeContext(
        named suiteName: String
    ) throws -> TestContext {

        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let rootDirectoryURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )
        let intakeDirectoryURL =
            rootDirectoryURL
            .appendingPathComponent(
                "ExternalIntake",
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: rootDirectoryURL,
            withIntermediateDirectories: true
        )

        let environment =
            AppEnvironment.live(
                defaults: defaults,
                configurationLibraryBaseDirectoryURL:
                    rootDirectoryURL,
                intakeDirectoryURL:
                    intakeDirectoryURL
            )

        return TestContext(
            suiteName: suiteName,
            defaults: defaults,
            rootDirectoryURL:
                rootDirectoryURL,
            intakeDirectoryURL:
                intakeDirectoryURL,
            environment: environment
        )
    }

    static func cleanup(
        _ context: TestContext
    ) {

        try? FileManager.default.removeItem(
            at: context.rootDirectoryURL
        )
        context.defaults.removePersistentDomain(
            forName: context.suiteName
        )
    }
}

private struct ShareQueueFailingPersistenceBackend:
    BatchQueuePersistenceBackend {

    func loadData(forKey key: String) throws -> Data? {
        nil
    }

    func saveData(_ data: Data, forKey key: String) throws {
        throw ShareQueuePersistenceFailure()
    }
}

private struct ShareQueuePersistenceFailure: Error {}

private struct FakeLivePhotoAssetIdentityResolver:
    LivePhotoAssetIdentityResolving {

    let resolution:
        LivePhotoAssetIdentityResolution

    func resolveAssetLocalIdentifier(
        for hint: LivePhotoStaticFallbackRecoveryHint
    ) -> LivePhotoAssetIdentityResolution {

        resolution
    }
}
#endif
