#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("Live Photo batch queue execution")
struct LivePhotoBatchQueueExecutionTests {

    @MainActor
    @Test("48MP HEIC admission diagnostics expose critical single-lane budget")
    func fortyEightMPHEICAdmissionDiagnosticsExposeCriticalSingleLaneBudget() {
        let task =
            BatchTask(
                sourceURL:
                    URL(fileURLWithPath: "/tmp/IMG_4800.HEIC"),
                fileName: "IMG_4800.HEIC",
                contentTypeIdentifier:
                    UTType.heic.identifier
            )
        let budget =
            MediaMemoryBudget(
                cost:
                    MediaCost(
                        pixelSize:
                            MediaPixelSize(
                                width: 8064,
                                height: 6048
                            ),
                        isRAW: false
                    )
            )

        let message =
            BatchTaskDiagnosticsRecorder
            .admissionDiagnosticMessage(
                for: task,
                budget: budget
            )

        #expect(
            message.contains(
                "fileName=IMG_4800.HEIC"
            )
        )
        #expect(message.contains("isRAW=false"))
        #expect(message.contains("pixelWidth=8064"))
        #expect(message.contains("pixelHeight=6048"))
        #expect(message.contains("pixelCount=48771072"))
        #expect(
            message.contains(
                "estimatedDecodedByteCount=195084288"
            )
        )
        #expect(message.contains("memoryTier=critical"))
        #expect(
            message.contains(
                "requiresExtendedPreviewPreparation=true"
            )
        )
        #expect(message.contains("maxConcurrentDecodes=1"))
        #expect(message.contains("maxConcurrentRenders=1"))
        #expect(message.contains("maxConcurrentExports=1"))
        #expect(message.contains("schedulerMode=singleTaskLoop"))
        #expect(message.contains("admission=queued"))
    }

    @MainActor
    @Test("48MP RAW admission diagnostics expose RAW critical budget")
    func fortyEightMPRawAdmissionDiagnosticsExposeRawCriticalBudget() {
        let task =
            BatchTask(
                sourceURL:
                    URL(fileURLWithPath: "/tmp/IMG_4800.DNG"),
                fileName: "IMG_4800.DNG",
                contentTypeIdentifier:
                    UTType(filenameExtension: "dng")?
                    .identifier
            )
        let budget =
            MediaMemoryBudget(
                cost:
                    MediaCost(
                        pixelSize:
                            MediaPixelSize(
                                width: 8064,
                                height: 6048
                            ),
                        isRAW: true
                    )
            )

        let message =
            BatchTaskDiagnosticsRecorder
            .admissionDiagnosticMessage(
                for: task,
                budget: budget
            )

        #expect(message.contains("isRAW=true"))
        #expect(message.contains("memoryTier=critical"))
        #expect(
            message.contains(
                "requiresExtendedPreviewPreparation=true"
            )
        )
        #expect(message.contains("schedulerMode=singleTaskLoop"))
    }

    @MainActor
    @Test("Route diagnostics distinguish Live Photo identity bundle and static fallback")
    func routeDiagnosticsDistinguishLivePhotoIdentityBundleAndStaticFallback() {
        let livePhotoType =
            UTType("com.apple.live-photo")?
            .identifier
        let identityTask =
            BatchTask(
                sourceURL:
                    URL(fileURLWithPath: "/tmp/IMG_6093.HEIC"),
                fileName: "IMG_6093.HEIC",
                sourceIdentifier:
                    "live-photo-asset",
                contentTypeIdentifier:
                    livePhotoType
            )
        let bundleTask =
            BatchTask(
                sourceURL:
                    URL(fileURLWithPath: "/tmp/SharedLivePhoto.livephoto"),
                fileName: "SharedLivePhoto.livephoto",
                contentTypeIdentifier:
                    livePhotoType
            )
        let staticFallbackTask =
            BatchTask(
                sourceURL:
                    URL(fileURLWithPath: "/tmp/IMG_6093.jpeg"),
                fileName: "IMG_6093.jpeg",
                contentTypeIdentifier:
                    UTType.jpeg.identifier
            )

        let identityMessage =
            BatchTaskDiagnosticsRecorder
            .routeDiagnosticMessage(
                for: identityTask,
                sourceURLIsLivePhotoBundle: false,
                route: "livePhoto"
            )
        let bundleMessage =
            BatchTaskDiagnosticsRecorder
            .routeDiagnosticMessage(
                for: bundleTask,
                sourceURLIsLivePhotoBundle: true,
                route: "livePhoto"
            )
        let staticFallbackMessage =
            BatchTaskDiagnosticsRecorder
            .routeDiagnosticMessage(
                for: staticFallbackTask,
                sourceURLIsLivePhotoBundle: false,
                route: "staticImage"
            )

        #expect(
            identityMessage.contains(
                "taskID=\(identityTask.id.uuidString)"
            )
        )
        #expect(
            identityMessage.contains(
                "hasSourceIdentifier=true"
            )
        )
        #expect(
            identityMessage.contains(
                "sourceURLIsLivePhotoBundle=false"
            )
        )
        #expect(identityMessage.contains("route=livePhoto"))
        #expect(
            bundleMessage.contains(
                "fileName=SharedLivePhoto.livephoto"
            )
        )
        #expect(
            bundleMessage.contains(
                "hasSourceIdentifier=false"
            )
        )
        #expect(
            bundleMessage.contains(
                "sourceURLIsLivePhotoBundle=true"
            )
        )
        #expect(bundleMessage.contains("route=livePhoto"))
        #expect(
            staticFallbackMessage.contains(
                "contentType=public.jpeg"
            )
        )
        #expect(
            staticFallbackMessage.contains(
                "sourceURLIsLivePhotoBundle=false"
            )
        )
        #expect(
            staticFallbackMessage.contains(
                "route=staticImage"
            )
        )
    }

    @Test("Prepared Live Photo bundles resolve still and paired video resources")
    func preparedLivePhotoBundlesResolveStillAndPairedVideoResources() throws {
        let rootURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                "PhotoMemo.PreparedLivePhotoBundle.\(UUID().uuidString)",
                isDirectory: true
            )
        let bundleURL =
            rootURL
            .appendingPathComponent(
                "SharedLivePhoto.livephoto",
                isDirectory: true
            )
        defer {
            try? FileManager.default
                .removeItem(
                    at: rootURL
                )
        }

        try FileManager.default.createDirectory(
            at: bundleURL,
            withIntermediateDirectories: true
        )
        let stillURL =
            bundleURL
            .appendingPathComponent("IMG_6093.HEIC")
        let videoURL =
            bundleURL
            .appendingPathComponent("IMG_6093.MOV")
        try Data("still".utf8).write(
            to: stillURL
        )
        try Data("movie".utf8).write(
            to: videoURL
        )

        let preparedBundle =
            try #require(
                LivePhotoSourceBundleLocator
                    .preparedBundle(
                        at: bundleURL
                    )
            )

        #expect(
            LivePhotoSourceBundleLocator
                .canResolveBundle(
                    at: bundleURL
                )
        )
        #expect(
            preparedBundle.stillPhotoFileURL
            == stillURL.standardizedFileURL
        )
        #expect(
            preparedBundle.pairedVideoFileURL
            == videoURL.standardizedFileURL
        )
        #expect(
            preparedBundle.stillPhotoResource.kind
            == .fullSizePhoto
        )
        #expect(
            preparedBundle.pairedVideoResource.kind
            == .fullSizePairedVideo
        )
        #expect(
            preparedBundle.stillPhotoResource.originalFilename
            == "IMG_6093.HEIC"
        )
        #expect(
            preparedBundle.pairedVideoResource.originalFilename
            == "IMG_6093.MOV"
        )
        #expect(
            preparedBundle.stillPhotoResource.uniformTypeIdentifier
            == UTType.heic.identifier
        )
        #expect(
            preparedBundle.pairedVideoResource.uniformTypeIdentifier
            == UTType.quickTimeMovie.identifier
        )
    }

    @Test("Prepared Live Photo bundles reject incomplete or non-directory sources")
    func preparedLivePhotoBundlesRejectIncompleteOrNonDirectorySources() throws {
        let rootURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                "PhotoMemo.PreparedLivePhotoBundleReject.\(UUID().uuidString)",
                isDirectory: true
            )
        defer {
            try? FileManager.default
                .removeItem(
                    at: rootURL
                )
        }

        try FileManager.default.createDirectory(
            at: rootURL,
            withIntermediateDirectories: true
        )
        let staticFileURL =
            rootURL
            .appendingPathComponent("IMG_0001.HEIC")
        try Data("still".utf8).write(
            to: staticFileURL
        )

        let stillOnlyDirectory =
            rootURL
            .appendingPathComponent(
                "StillOnly.livephoto",
                isDirectory: true
            )
        let movieOnlyDirectory =
            rootURL
            .appendingPathComponent(
                "MovieOnly.livephoto",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: stillOnlyDirectory,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: movieOnlyDirectory,
            withIntermediateDirectories: true
        )
        try Data("still".utf8).write(
            to:
                stillOnlyDirectory
                .appendingPathComponent("IMG_0001.HEIC")
        )
        try Data("movie".utf8).write(
            to:
                movieOnlyDirectory
                .appendingPathComponent("IMG_0001.MOV")
        )

        #expect(
            LivePhotoSourceBundleLocator
                .preparedBundle(
                    at: staticFileURL
                ) == nil
        )
        #expect(
            LivePhotoSourceBundleLocator
                .preparedBundle(
                    at: stillOnlyDirectory
                ) == nil
        )
        #expect(
            LivePhotoSourceBundleLocator
                .preparedBundle(
                    at: movieOnlyDirectory
                ) == nil
        )
    }

    @Test("Prepared Live Photo bundles reject ambiguous or mismatched pairs")
    func preparedLivePhotoBundlesRejectAmbiguousOrMismatchedPairs() throws {
        let rootURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                "PhotoMemo.PreparedLivePhotoBundleAmbiguous.\(UUID().uuidString)",
                isDirectory: true
            )
        defer {
            try? FileManager.default
                .removeItem(
                    at: rootURL
                )
        }

        let mismatchedDirectory =
            rootURL
            .appendingPathComponent(
                "Mismatched.livephoto",
                isDirectory: true
            )
        let multipleStillsDirectory =
            rootURL
            .appendingPathComponent(
                "MultipleStills.livephoto",
                isDirectory: true
            )
        let multipleMoviesDirectory =
            rootURL
            .appendingPathComponent(
                "MultipleMovies.livephoto",
                isDirectory: true
            )
        for directoryURL in [
            mismatchedDirectory,
            multipleStillsDirectory,
            multipleMoviesDirectory
        ] {
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        }

        try Data("still".utf8).write(
            to:
                mismatchedDirectory
                .appendingPathComponent("IMG_1001.HEIC")
        )
        try Data("movie".utf8).write(
            to:
                mismatchedDirectory
                .appendingPathComponent("IMG_2002.MOV")
        )
        try Data("still".utf8).write(
            to:
                multipleStillsDirectory
                .appendingPathComponent("IMG_3003.HEIC")
        )
        try Data("still".utf8).write(
            to:
                multipleStillsDirectory
                .appendingPathComponent("IMG_3003.JPG")
        )
        try Data("movie".utf8).write(
            to:
                multipleStillsDirectory
                .appendingPathComponent("IMG_3003.MOV")
        )
        try Data("still".utf8).write(
            to:
                multipleMoviesDirectory
                .appendingPathComponent("IMG_4004.HEIC")
        )
        try Data("movie".utf8).write(
            to:
                multipleMoviesDirectory
                .appendingPathComponent("IMG_4004.MOV")
        )
        try Data("movie".utf8).write(
            to:
                multipleMoviesDirectory
                .appendingPathComponent("IMG_4004-ALT.MOV")
        )

        #expect(
            LivePhotoSourceBundleLocator
                .preparedBundle(
                    at: mismatchedDirectory
                ) == nil
        )
        #expect(
            LivePhotoSourceBundleLocator
                .preparedBundle(
                    at: multipleStillsDirectory
                ) == nil
        )
        #expect(
            LivePhotoSourceBundleLocator
                .preparedBundle(
                    at: multipleMoviesDirectory
                ) == nil
        )
    }

    @Test("Adjusted Live Photo resources keep the source task filename")
    func adjustedLivePhotoResourcesKeepSourceTaskFilename() {
        let task =
            BatchTask(
                sourceURL:
                    URL(fileURLWithPath: "/tmp/IMG_1164.jpg"),
                fileName: "IMG_1164.jpg",
                contentTypeIdentifier:
                    UTType("com.apple.live-photo")?
                    .identifier
            )
        let preparedBundle =
            LivePhotoPreparedAssetBundle(
                assetLocalIdentifier:
                    "/tmp/SharedLivePhoto.livephoto",
                stillPhotoResource:
                    LivePhotoAssetResourceDescriptor(
                        id: "shared-still",
                        kind: .fullSizePhoto,
                        originalFilename:
                            "FullSizeRender.jpeg",
                        uniformTypeIdentifier:
                            UTType.jpeg.identifier
                    ),
                pairedVideoResource:
                    LivePhotoAssetResourceDescriptor(
                        id: "shared-movie",
                        kind: .fullSizePairedVideo,
                        originalFilename:
                            "FullSizeRender.mov",
                        uniformTypeIdentifier:
                            UTType.quickTimeMovie.identifier
                    ),
                stillPhotoFileURL:
                    URL(fileURLWithPath: "/tmp/IMG_6093.HEIC"),
                pairedVideoFileURL:
                    URL(fileURLWithPath: "/tmp/IMG_6093.MOV")
            )

        #expect(
            LivePhotoBatchTaskProcessor
                .sourceOriginalFilename(
                    task: task,
                    preparedBundle:
                        preparedBundle
                )
            == "IMG_1164.jpg"
        )
    }

    @MainActor
    @Test("Live Photo payloads are handled by the internal Live Photo processor")
    func livePhotoPayloadsUseInternalLivePhotoProcessor() async throws {
        let suiteName =
            "PhotoMemo.LivePhotoBatchQueueExecutionTests.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let intakeDirectoryURL =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )
        defer {
            try? FileManager.default.removeItem(
                at: intakeDirectoryURL
            )
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let livePhotoType =
            try #require(
                UTType("com.apple.live-photo")
            )
        let processor =
            RecordingLivePhotoBatchTaskProcessor()
        let store =
            BatchQueueStore(
                defaults: defaults,
                settingsService:
                    SettingsService(
                        defaults: defaults
                    ),
                externalIntakeStore:
                    ExternalPhotoIntakeStore(
                        defaults: defaults,
                        intakeDirectoryURL:
                            intakeDirectoryURL
                    ),
                livePhotoProcessor:
                    processor
            )
        let configuration =
            makeConfiguration(
                outputMode:
                    .originalFormat
            )

        _ = store.enqueue(
            payloads: [
                BatchTaskIntakePayload(
                    sourceURL:
                        URL(
                            fileURLWithPath:
                                "/tmp/IMG_6093.HEIC"
                        ),
                    sourceIdentifier:
                        "live-photo-local-identifier",
                    fileName: "IMG_6093.HEIC",
                    contentTypeIdentifier:
                        livePhotoType.identifier
                )
            ],
            configuration:
                configuration,
            launchSource:
                .quickAction
        )

        let didFinish =
            await waitForQueueToFinish(
                store
            )

        #expect(didFinish)
        #expect(
            processor.requests.map(\.task.sourceIdentifier)
            == [
                "live-photo-local-identifier"
            ]
        )
        #expect(
            processor.requests.first?.configuration
                .v1MediaOutputMode
            == .originalFormat
        )
        #expect(
            store.jobs.first?.tasks.first?.phase
            == .completed
        )
        #expect(
            store.jobs.first?.tasks.first?
                .savedAssetIdentifier
            == "rendered-live-photo-asset"
        )
    }

    @MainActor
    @Test("Live Photo content type without asset identity falls back to still processing")
    func livePhotoPayloadWithoutAssetIdentityDoesNotUseInternalLivePhotoProcessor() async throws {
        let suiteName =
            "PhotoMemo.LivePhotoBatchQueueExecutionTests.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let intakeDirectoryURL =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )
        defer {
            try? FileManager.default.removeItem(
                at: intakeDirectoryURL
            )
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let livePhotoType =
            try #require(
                UTType("com.apple.live-photo")
            )
        let processor =
            RecordingLivePhotoBatchTaskProcessor()
        let store =
            BatchQueueStore(
                defaults: defaults,
                settingsService:
                    SettingsService(
                        defaults: defaults
                    ),
                externalIntakeStore:
                    ExternalPhotoIntakeStore(
                        defaults: defaults,
                        intakeDirectoryURL:
                            intakeDirectoryURL
                    ),
                livePhotoProcessor:
                    processor
            )
        let configuration =
            makeConfiguration(
                outputMode:
                    .originalFormat
            )
        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .portraitJPEG
            )

        _ = store.enqueue(
            payloads: [
                BatchTaskIntakePayload(
                    sourceURL: sourceURL,
                    sourceIdentifier: nil,
                    fileName: "IMG_6093.jpeg",
                    contentTypeIdentifier:
                        livePhotoType.identifier
                )
            ],
            configuration:
                configuration,
            launchSource:
                .shareExtension
        )

        let didFinish =
            await waitForQueueToFinish(
                store
            )

        #expect(didFinish)
        #expect(processor.requests.isEmpty)
        #expect(
            store.jobs.first?.tasks.first?.phase
            == .completed
        )
    }

    @MainActor
    @Test("Live Photo bundle payloads use the internal Live Photo processor without asset identity")
    func livePhotoBundlePayloadsUseInternalLivePhotoProcessorWithoutAssetIdentity() async throws {
        let suiteName =
            "PhotoMemo.LivePhotoBatchQueueExecutionTests.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let intakeDirectoryURL =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )
        defer {
            try? FileManager.default.removeItem(
                at: intakeDirectoryURL
            )
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let livePhotoType =
            try #require(
                UTType("com.apple.live-photo")
            )
        let bundleURL =
            intakeDirectoryURL
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

        let processor =
            RecordingLivePhotoBatchTaskProcessor()
        let store =
            BatchQueueStore(
                defaults: defaults,
                settingsService:
                    SettingsService(
                        defaults: defaults
                    ),
                externalIntakeStore:
                    ExternalPhotoIntakeStore(
                        defaults: defaults,
                        intakeDirectoryURL:
                            intakeDirectoryURL
                    ),
                livePhotoProcessor:
                    processor
            )
        let configuration =
            makeConfiguration(
                outputMode:
                    .originalFormat
            )

        _ = store.enqueue(
            payloads: [
                BatchTaskIntakePayload(
                    sourceURL: bundleURL,
                    sourceIdentifier: nil,
                    fileName: "SharedLivePhoto.livephoto",
                    contentTypeIdentifier:
                        livePhotoType.identifier
                )
            ],
            configuration:
                configuration,
            launchSource:
                .shareExtension
        )

        let didFinish =
            await waitForQueueToFinish(
                store
            )

        #expect(didFinish)
        #expect(processor.requests.count == 1)
        #expect(
            processor.requests.first?.task.sourceURL
            == bundleURL
        )
        #expect(
            processor.requests.first?.task.sourceIdentifier == nil
        )
    }

    @MainActor
    @Test("Mixed still and Live Photo batches route each task independently")
    func mixedStillAndLivePhotoBatchesRouteEachTaskIndependently() async throws {
        let suiteName =
            "PhotoMemo.LivePhotoBatchQueueExecutionTests.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let intakeDirectoryURL =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )
        defer {
            try? FileManager.default.removeItem(
                at: intakeDirectoryURL
            )
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let stillURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .portraitJPEG
            )
        let livePhotoType =
            try #require(
                UTType("com.apple.live-photo")
            )
        let bundleURL =
            intakeDirectoryURL
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

        let processor =
            RecordingLivePhotoBatchTaskProcessor()
        let store =
            BatchQueueStore(
                defaults: defaults,
                settingsService:
                    SettingsService(
                        defaults: defaults
                    ),
                externalIntakeStore:
                    ExternalPhotoIntakeStore(
                        defaults: defaults,
                        intakeDirectoryURL:
                            intakeDirectoryURL
                    ),
                livePhotoProcessor:
                    processor
            )
        let configuration =
            makeConfiguration(
                outputMode:
                    .originalFormat
            )

        _ = store.enqueue(
            payloads: [
                BatchTaskIntakePayload(
                    sourceURL: stillURL,
                    sourceIdentifier: nil,
                    fileName: "IMG_STATIC.jpeg",
                    contentTypeIdentifier:
                        UTType.jpeg.identifier
                ),
                BatchTaskIntakePayload(
                    sourceURL: bundleURL,
                    sourceIdentifier: nil,
                    fileName: "SharedLivePhoto.livephoto",
                    contentTypeIdentifier:
                        livePhotoType.identifier
                ),
                BatchTaskIntakePayload(
                    sourceURL:
                        URL(
                            fileURLWithPath:
                                "/tmp/IMG_IDENTITY.HEIC"
                        ),
                    sourceIdentifier:
                        "live-photo-local-identifier",
                    fileName: "IMG_IDENTITY.HEIC",
                    contentTypeIdentifier:
                        livePhotoType.identifier
                )
            ],
            configuration:
                configuration,
            launchSource:
                .shareExtension
        )

        let didFinish =
            await waitForAllQueueTasksToFinish(
                store
            )

        #expect(didFinish)
        #expect(
            processor.requests.map(\.task.fileName)
            == [
                "SharedLivePhoto.livephoto",
                "IMG_IDENTITY.HEIC"
            ]
        )
        #expect(
            processor.requests.map(\.task.sourceIdentifier)
            == [
                nil,
                "live-photo-local-identifier"
            ]
        )
        #expect(
            store.jobs.first?.tasks.map(\.phase)
            == [
                .completed,
                .completed,
                .completed
            ]
        )
    }

    @MainActor
    @Test("Real Live Photo processor uses source bundle resources without PhotoKit loading")
    func realLivePhotoProcessorUsesSourceBundleResourcesWithoutPhotoKitLoading() async throws {
        let rootURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                "PhotoMemo.RealLivePhotoSourceBundle.\(UUID().uuidString)",
                isDirectory: true
            )
        let bundleURL =
            rootURL
            .appendingPathComponent(
                "SharedLivePhoto.livephoto",
                isDirectory: true
            )
        let temporaryRootURL =
            rootURL
            .appendingPathComponent(
                "Work",
                isDirectory: true
            )
        defer {
            try? FileManager.default.removeItem(
                at: rootURL
            )
        }

        try FileManager.default.createDirectory(
            at: bundleURL,
            withIntermediateDirectories: true
        )
        let sourceStillURL =
            bundleURL
            .appendingPathComponent("IMG_6093.HEIC")
        let sourceVideoURL =
            bundleURL
            .appendingPathComponent("IMG_6093.MOV")
        try FileManager.default.copyItem(
            at:
                SyntheticFixtureLibrary
                .fixtureURL(
                    .portraitJPEG
                ),
            to: sourceStillURL
        )
        try Data("movie".utf8).write(
            to: sourceVideoURL
        )

        let loader =
            RecordingLivePhotoAssetLoader()
        let composer =
            RecordingLivePhotoPairComposer()
        let writer =
            RecordingLivePhotoAssetWriter()
        let suiteName =
            "PhotoMemo.RealLivePhotoSourceBundle.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        let processor =
            LivePhotoBatchTaskProcessor(
                assetLoader: loader,
                pairComposer: composer,
                assetWriter: writer,
                diagnosticsDefaults: defaults,
                outputFilenameSequenceStore:
                    LivePhotoOutputFilenameSequenceStore(
                        storageURL:
                            rootURL.appendingPathComponent(
                                "LivePhotoOutputFilenameSequence.json"
                            )
                    ),
                temporaryRootURL:
                    temporaryRootURL
            )
        let task =
            BatchTask(
                sourceURL: bundleURL,
                fileName:
                    "SharedLivePhoto.livephoto",
                sourceIdentifier: nil,
                contentTypeIdentifier:
                    UTType("com.apple.live-photo")?
                    .identifier
            )

        _ = try await processor.process(
            task: task,
            configuration:
                makeConfiguration(
                    outputMode:
                        .originalFormat
                )
        )

        #expect(loader.bundleCalls.isEmpty)
        #expect(loader.exportResourceCalls.isEmpty)
        #expect(
            composer.requests.first?.sourceStillURL
            == sourceStillURL.standardizedFileURL
        )
        #expect(
            composer.requests.first?.sourceVideoURL
            == sourceVideoURL.standardizedFileURL
        )
        let saveRequest =
            try #require(
                writer.requests.first
            )
        #expect(
            saveRequest.stillPhotoOriginalFilename
            == "IMG_6093(1).heic"
        )
        #expect(
            saveRequest.pairedVideoOriginalFilename
            == "IMG_6093(1).mov"
        )
    }
}

private extension LivePhotoBatchQueueExecutionTests {

    @MainActor
    func makeConfiguration(
        outputMode: V1MediaOutputMode
    ) -> BatchConfigurationSnapshot {
        BatchConfigurationSnapshot(
            template:
                .classicWhite
                .normalizedForEditing,
            badge: nil,
            anchor: nil,
            shouldWritePhotoDescription:
                true,
            photoDescriptionOverride:
                "",
            selectedAlbumIdentifier: "",
            mediaOutputModeRawValue:
                outputMode.rawValue
        )
    }

    @MainActor
    func waitForQueueToFinish(
        _ store: BatchQueueStore
    ) async -> Bool {
        for _ in 0..<50 {
            if store.jobs.first?.tasks.first?.phase
                .isTerminal == true {
                return true
            }

            try? await Task.sleep(
                nanoseconds: 20_000_000
            )
        }

        return store.jobs.first?.tasks.first?.phase
            .isTerminal == true
    }

    @MainActor
    func waitForAllQueueTasksToFinish(
        _ store: BatchQueueStore
    ) async -> Bool {
        for _ in 0..<100 {
            let tasks =
                store.jobs.first?.tasks ?? []
            if !tasks.isEmpty,
               tasks.allSatisfy({
                   $0.phase.isTerminal
               }) {
                return true
            }

            try? await Task.sleep(
                nanoseconds: 20_000_000
            )
        }

        let tasks =
            store.jobs.first?.tasks ?? []
        return !tasks.isEmpty
            && tasks.allSatisfy {
                $0.phase.isTerminal
            }
    }
}

@MainActor
private final class RecordingLivePhotoBatchTaskProcessor:
    LivePhotoBatchTaskProcessing {

    struct Request {
        let task: BatchTask
        let configuration: BatchConfigurationSnapshot
    }

    private(set) var requests: [Request] = []

    func process(
        task: BatchTask,
        configuration: BatchConfigurationSnapshot
    ) async throws -> LivePhotoBatchTaskResult {
        requests.append(
            Request(
                task: task,
                configuration: configuration
            )
        )

        return LivePhotoBatchTaskResult(
            saveResult:
                PhotoLibrarySaveResult(
                    albumTitle: "MemoMark",
                    assetLocalIdentifier:
                        "rendered-live-photo-asset"
                ),
            notificationSourceURL: nil,
            temporaryFileURLs: []
        )
    }
}

@MainActor
private final class RecordingLivePhotoAssetLoader:
    LivePhotoAssetLoading {

    private(set) var bundleCalls: [String] = []
    private(set) var exportResourceCalls: [LivePhotoAssetBundle] = []

    func bundle(
        for assetLocalIdentifier: String
    ) async throws -> LivePhotoAssetBundle {
        bundleCalls.append(
            assetLocalIdentifier
        )
        throw LivePhotoAssetLoadingError
            .assetNotFound
    }

    func exportResources(
        for bundle: LivePhotoAssetBundle,
        to folderURL: URL
    ) async throws -> LivePhotoPreparedAssetBundle {
        exportResourceCalls.append(
            bundle
        )
        throw LivePhotoAssetLoadingError
            .assetNotFound
    }
}

@MainActor
private final class RecordingLivePhotoPairComposer:
    LivePhotoPairComposing {

    struct Request {
        let sourceStillURL: URL
        let sourceVideoURL: URL
        let outputStillURL: URL
        let outputVideoURL: URL
        let outputStillType: UTType
    }

    private(set) var requests: [Request] = []

    func composePair(
        sourceStillURL: URL,
        sourceVideoURL: URL,
        overlay: FixedFooterOverlayDescriptor,
        outputStillURL: URL,
        outputVideoURL: URL,
        outputStillType: UTType,
        outputDescription: String?
    ) async throws -> LivePhotoComposedPair {
        requests.append(
            Request(
                sourceStillURL:
                    sourceStillURL,
                sourceVideoURL:
                    sourceVideoURL,
                outputStillURL:
                    outputStillURL,
                outputVideoURL:
                    outputVideoURL,
                outputStillType:
                    outputStillType
            )
        )
        try FileManager.default.copyItem(
            at: sourceStillURL,
            to: outputStillURL
        )
        try Data("composed-movie".utf8).write(
            to: outputVideoURL
        )

        return LivePhotoComposedPair(
            stillPhotoURL:
                outputStillURL,
            pairedVideoURL:
                outputVideoURL,
            pairingIdentityPlan:
                LivePhotoPairingIdentityPlan(
                    pairingIdentifier:
                        UUID().uuidString
                )
        )
    }
}

@MainActor
private final class RecordingLivePhotoAssetWriter:
    LivePhotoAssetWriting {

    private(set) var requests: [LivePhotoSaveRequest] = []

    func saveAsset(
        _ request: LivePhotoSaveRequest
    ) async throws -> PhotoLibrarySaveResult {
        requests.append(
            request
        )

        return PhotoLibrarySaveResult(
            albumTitle: "MemoMark",
            assetLocalIdentifier:
                "saved-live-photo"
        )
    }
}
#endif
