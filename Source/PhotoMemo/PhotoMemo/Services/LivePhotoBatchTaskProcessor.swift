#if !PHOTOMEMO_SHARE_EXTENSION
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

@MainActor
protocol LivePhotoBatchTaskProcessing {

    func process(
        task: BatchTask,
        configuration: BatchConfigurationSnapshot
    ) async throws -> LivePhotoBatchTaskResult
}

struct LivePhotoBatchTaskResult {

    let saveResult:
        PhotoLibrarySaveResult

    let notificationSourceURL:
        URL?

    let temporaryFileURLs:
        [URL]
}

enum LivePhotoBatchTaskProcessingError:
    LocalizedError,
    Equatable {

    case assetLocalIdentifierMissing
    case renderedOutputUnreadable
    case sourcePixelSizeMissing
    case unsupportedOutputPlan

    var errorDescription: String? {
        switch self {
        case .assetLocalIdentifierMissing:
            return "Unable to locate the original Live Photo asset."
        case .renderedOutputUnreadable:
            return "Unable to read the rendered MemoMark still image."
        case .sourcePixelSizeMissing:
            return "Unable to read the Live Photo still-image size."
        case .unsupportedOutputPlan:
            return "The planned Live Photo output is not supported by the current runtime."
        }
    }
}

nonisolated enum LivePhotoSourceBundleLocator {

    static func canResolveBundle(
        at sourceURL: URL,
        fileManager: FileManager = .default
    ) -> Bool {

        preparedBundle(
            at: sourceURL,
            fileManager:
                fileManager
        ) != nil
    }

    static func preparedBundle(
        at sourceURL: URL,
        fileManager: FileManager = .default
    ) -> LivePhotoPreparedAssetBundle? {

        let standardizedURL =
            sourceURL.standardizedFileURL
        var isDirectory:
            ObjCBool = false

        guard fileManager.fileExists(
            atPath: standardizedURL.path,
            isDirectory: &isDirectory
        ),
              isDirectory.boolValue else {
            return nil
        }

        guard let enumerator =
            fileManager.enumerator(
                at: standardizedURL,
                includingPropertiesForKeys: [
                    .isRegularFileKey
                ],
                options: [
                    .skipsHiddenFiles,
                    .skipsPackageDescendants
                ]
            ) else {
            return nil
        }

        let fileURLs =
            enumerator
            .compactMap {
                $0 as? URL
            }
            .filter { url in
                (
                    try? url
                        .resourceValues(
                            forKeys: [
                                .isRegularFileKey
                            ]
                        )
                        .isRegularFile
                ) == true
            }

        let stillURLs =
            fileURLs.filter(
                isSupportedStillPhotoURL
            )
        let videoURLs =
            fileURLs.filter(
                isSupportedPairedVideoURL
            )

        guard stillURLs.count == 1,
              videoURLs.count == 1,
              let stillURL = stillURLs.first,
              let videoURL = videoURLs.first,
              resourceBasename(stillURL)
              == resourceBasename(videoURL)
        else {
            return nil
        }

        let stillResource =
            LivePhotoAssetResourceDescriptor(
                id: "shared-still",
                kind: .fullSizePhoto,
                originalFilename:
                    stillURL.lastPathComponent,
                uniformTypeIdentifier:
                    UTType(
                        filenameExtension:
                            stillURL
                            .pathExtension
                            .lowercased()
                    )?
                    .identifier
            )
        let videoResource =
            LivePhotoAssetResourceDescriptor(
                id: "shared-paired-video",
                kind: .fullSizePairedVideo,
                originalFilename:
                    videoURL.lastPathComponent,
                uniformTypeIdentifier:
                    UTType(
                        filenameExtension:
                            videoURL
                            .pathExtension
                            .lowercased()
                    )?
                    .identifier
            )

        return LivePhotoPreparedAssetBundle(
            assetLocalIdentifier:
                standardizedURL.path,
            stillPhotoResource:
                stillResource,
            pairedVideoResource:
                videoResource,
            stillPhotoFileURL:
                stillURL.standardizedFileURL,
            pairedVideoFileURL:
                videoURL.standardizedFileURL
        )
    }

    private nonisolated static func isSupportedStillPhotoURL(
        _ url: URL
    ) -> Bool {

        guard let type =
            UTType(
                filenameExtension:
                    url
                    .pathExtension
                    .lowercased()
            )
        else {
            return false
        }

        return type.conforms(to: .image)
            && !type.conforms(to: .movie)
    }

    private nonisolated static func isSupportedPairedVideoURL(
        _ url: URL
    ) -> Bool {

        guard let type =
            UTType(
                filenameExtension:
                    url
                    .pathExtension
                    .lowercased()
            )
        else {
            return false
        }

        return type.conforms(to: .movie)
    }

    private nonisolated static func resourceBasename(
        _ url: URL
    ) -> String {

        url
            .deletingPathExtension()
            .lastPathComponent
            .lowercased()
    }
}

@MainActor
final class LivePhotoBatchTaskProcessor:
    LivePhotoBatchTaskProcessing {

    private let planner:
        MediaProcessingPlanner
    private let assetLoader:
        any LivePhotoAssetLoading
    private let pairComposer:
        any LivePhotoPairComposing
    private let assetWriter:
        any LivePhotoAssetWriting
    private let importService:
        PhotoImportService
    private let cardBuildService:
        RecordCardBuildService
    private let exportService:
        RecordCardExportService
    private let photoLibraryExportService:
        PhotoLibraryExportService
    private let fileManager:
        FileManager
    private let temporaryRootURL:
        URL
    private let diagnosticsDefaults:
        UserDefaults
    private let outputFilenameSequenceStore:
        LivePhotoOutputFilenameSequenceStore

    init(
        runtimeGate:
            MediaPipelineRuntimeGate =
                .validationCandidate(
                    allowedRoutes: [.livePhoto],
                    exposesUserVisibleOutputControls: true,
                    permitsPhotoLibraryWrites: true
                ),
        planner:
            MediaProcessingPlanner? = nil,
        assetLoader:
            (any LivePhotoAssetLoading)? = nil,
        pairComposer:
            (any LivePhotoPairComposing)? = nil,
        assetWriter:
            (any LivePhotoAssetWriting)? = nil,
        importService:
            PhotoImportService? = nil,
        cardBuildService:
            RecordCardBuildService? = nil,
        exportService:
            RecordCardExportService? = nil,
        photoLibraryExportService:
            PhotoLibraryExportService? = nil,
        diagnosticsDefaults:
            UserDefaults = PhotoMemoSharedContainer
            .sharedUserDefaults,
        outputFilenameSequenceStore:
            LivePhotoOutputFilenameSequenceStore? = nil,
        fileManager: FileManager = .default,
        temporaryRootURL:
            URL =
                FileManager.default.temporaryDirectory
                .appendingPathComponent(
                    "MemoMarkLivePhotoProcessing",
                    isDirectory: true
                )
    ) {
        self.planner =
            planner
            ?? MediaProcessingPlanner(
                runtimeGate:
                    runtimeGate
            )
        self.assetLoader =
            assetLoader
            ?? PhotoKitLivePhotoAssetLoader()
        self.pairComposer =
            pairComposer
            ?? LivePhotoPairCompositionService()
        self.assetWriter =
            assetWriter
            ?? PhotoKitLivePhotoAssetWriter(
                runtimeGate:
                    runtimeGate
            )
        self.importService =
            importService
            ?? PhotoImportService(
                inputPolicy:
                    PhotoProcessingInputPolicy(
                        allowsLivePhoto: true
                    )
            )
        self.cardBuildService =
            cardBuildService
            ?? RecordCardBuildService()
        self.exportService =
            exportService
            ?? RecordCardExportService()
        self.photoLibraryExportService =
            photoLibraryExportService
            ?? PhotoLibraryExportService()
        self.fileManager =
            fileManager
        self.temporaryRootURL =
            temporaryRootURL
        self.diagnosticsDefaults =
            diagnosticsDefaults
        self.outputFilenameSequenceStore =
            outputFilenameSequenceStore
            ?? LivePhotoOutputFilenameSequenceStore()
    }

    func process(
        task: BatchTask,
        configuration: BatchConfigurationSnapshot
    ) async throws -> LivePhotoBatchTaskResult {
        let plan =
            try planner.plan(
                for:
                    descriptor(
                        for: task
                    ),
                intent:
                    configuration
                    .v1MediaOutputMode
                    .mediaProcessingIntent
            )

        switch plan.outputPlan {
        case .stillImage:
            return try await processStaticStillImage(
                task: task,
                configuration: configuration
            )

        case let .livePhotoPair(
            stillImageType,
            pairedVideoType
        ):
            guard pairedVideoType.conforms(to: .movie)
                    || pairedVideoType.identifier
                    == "com.apple.quicktime-movie" else {
                throw LivePhotoBatchTaskProcessingError
                    .unsupportedOutputPlan
            }

            return try await processMotionPreservingLivePhoto(
                task: task,
                configuration: configuration,
                outputStillType: stillImageType
            )
        }
    }
}

extension LivePhotoBatchTaskProcessor {

    static func sourceOriginalFilename(
        task: BatchTask,
        preparedBundle: LivePhotoPreparedAssetBundle
    ) -> String? {
        let taskFileName =
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                task.fileName
            )
        let taskExtension = taskFileName.map {
            URL(fileURLWithPath: $0)
                .pathExtension
                .lowercased()
        }

        if taskExtension != "livephoto",
            let taskFileName {
            return taskFileName
        }

        let preparedFileName =
            preparedBundle
            .stillPhotoResource
            .originalFilename
        guard !PhotoFileNameResolver
            .isPhotoKitInternalResourceFileName(
                preparedFileName
            ) else {
            return nil
        }
        return PhotoFileNameResolver
            .sanitizedOriginalFileName(
                preparedFileName
            )
    }
}

private extension LivePhotoBatchTaskProcessor {

    func validateRenderHealth(
        card: RecordCard,
        configuration: BatchConfigurationSnapshot,
        task: BatchTask
    ) throws {
        do {
            _ = try ProductionRenderHealthCheck.validate(
                card: card,
                configuration: configuration
            )
            _ = PhotoMemoShareDiagnostics.recordResult(
                stage: .renderHealthCheckPassed,
                message:
                    "taskID=\(task.id.uuidString) source=livePhoto configurationID=\(configuration.configurationID?.uuidString ?? "nil") revision=\(configuration.configurationRevision.map(String.init) ?? "nil")",
                defaults: diagnosticsDefaults
            )
        } catch {
            _ = PhotoMemoShareDiagnostics.recordResult(
                stage: .renderHealthCheckFailed,
                message:
                    "taskID=\(task.id.uuidString) source=livePhoto configurationID=\(configuration.configurationID?.uuidString ?? "nil") revision=\(configuration.configurationRevision.map(String.init) ?? "nil") reason=\(String(describing: error))",
                defaults: diagnosticsDefaults
            )
            throw error
        }
    }

    func processStaticStillImage(
        task: BatchTask,
        configuration: BatchConfigurationSnapshot
    ) async throws -> LivePhotoBatchTaskResult {
        let importedPhoto =
            try await importLivePhotoStill(
                from: task.sourceURL,
                task: task
            )
        let card =
            cardBuildService.buildCard(
                from: importedPhoto,
                configuration: configuration
            )
        try validateRenderHealth(
            card: card,
            configuration: configuration,
            task: task
        )
        let renderedFileURL =
            try exportService.exportToTemporaryFile(
                photo: importedPhoto,
                card: card
            )
        let saveResult =
            try await photoLibraryExportService
            .saveImageResult(
                at: renderedFileURL,
                metadata: importedPhoto.metadata,
                preferredAlbumIdentifier:
                    preferredAlbumIdentifier(
                        from: configuration
                    )
            )

        return LivePhotoBatchTaskResult(
            saveResult: saveResult,
            notificationSourceURL:
                renderedFileURL,
            temporaryFileURLs: [
                renderedFileURL
            ]
        )
    }

    func processMotionPreservingLivePhoto(
        task: BatchTask,
        configuration: BatchConfigurationSnapshot,
        outputStillType: UTType
    ) async throws -> LivePhotoBatchTaskResult {
        let workDirectoryURL =
            try makeWorkDirectory()
        var temporaryFileURLs: [URL] = [
            workDirectoryURL
        ]

        do {
            let preparedBundle:
                LivePhotoPreparedAssetBundle

            if let assetLocalIdentifier =
                task.sourceIdentifier?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
               !assetLocalIdentifier.isEmpty {
                let bundle =
                    try await assetLoader.bundle(
                        for: assetLocalIdentifier
                    )
                preparedBundle =
                    try await assetLoader
                .exportResources(
                    for: bundle,
                    to:
                        workDirectoryURL
                        .appendingPathComponent(
                            "Source",
                            isDirectory: true
                        )
                )
            } else if let sourceBundle =
                LivePhotoSourceBundleLocator
                .preparedBundle(
                    at: task.sourceURL,
                    fileManager:
                        fileManager
                ) {
                preparedBundle = sourceBundle
            } else {
                throw LivePhotoBatchTaskProcessingError
                    .assetLocalIdentifierMissing
            }
            let importedPhoto =
                try await importLivePhotoStill(
                    from:
                        preparedBundle
                        .stillPhotoFileURL,
                    task: task,
                    originalFileName:
                        preparedBundle
                        .stillPhotoResource
                        .originalFilename,
                    contentTypeIdentifier:
                        preparedBundle
                        .stillPhotoResource
                        .uniformTypeIdentifier
                        ?? task
                        .contentTypeIdentifier
                )
            let card =
                cardBuildService.buildCard(
                    from: importedPhoto,
                    configuration:
                        configuration
                )
            try validateRenderHealth(
                card: card,
                configuration: configuration,
                task: task
            )
            let renderedFileURL =
                try exportService.exportToTemporaryFile(
                    photo: importedPhoto,
                    card: card
                )
            let outputDescription =
                CardVariableProvider
                .exportDescription(
                    from: card
                )
            temporaryFileURLs.append(
                renderedFileURL
            )
            let renderedImage =
                try renderedCGImage(
                    at: renderedFileURL
                )
            let overlay =
                try LivePhotoRenderOutputGeometry
                .overlayDescriptor(
                    renderedOutputImage:
                        renderedImage,
                    footerHeight:
                        rendererFooterHeight(
                            renderedImage:
                                renderedImage,
                            card: card
                        )
                )
            let outputStillURL =
                workDirectoryURL
                .appendingPathComponent(
                    "MemoMark-LivePhoto"
                )
                .appendingPathExtension(
                    outputStillType
                    .preferredFilenameExtension
                    ?? "heic"
                )
            let outputVideoURL =
                workDirectoryURL
                .appendingPathComponent(
                    "MemoMark-LivePhoto"
                )
                .appendingPathExtension("mov")
            let composedPair =
                try await pairComposer.composePair(
                    sourceStillURL:
                        preparedBundle
                        .stillPhotoFileURL,
                    sourceVideoURL:
                        preparedBundle
                        .pairedVideoFileURL,
                    overlay: overlay,
                    outputStillURL:
                        outputStillURL,
                    outputVideoURL:
                        outputVideoURL,
                    outputStillType:
                        outputStillType,
                    outputDescription:
                        outputDescription
                )
            let sourceOriginalFilename =
                Self.sourceOriginalFilename(
                    task: task,
                    preparedBundle: preparedBundle
                )
            let outputBaseName: String
            do {
                outputBaseName = try outputFilenameSequenceStore
                    .nextOutputBaseName(
                        preferredOriginalFileName:
                            sourceOriginalFilename,
                        assetOriginalFileName:
                            preparedBundle
                            .stillPhotoResource
                            .originalFilename,
                        captureDate:
                            importedPhoto
                            .metadata
                            .captureDate,
                        timeZone:
                            importedPhoto
                            .metadata
                            .captureTimeZone
                    )
            } catch {
                _ = PhotoMemoShareDiagnostics.recordResult(
                    stage: .livePhotoOutputFilenameFailed,
                    message:
                        "taskID=\(task.id.uuidString) reason=\(String(describing: error))",
                    defaults: diagnosticsDefaults
                )
                throw error
            }
            let stillPhotoOriginalFilename =
                Self.outputOriginalFilename(
                    baseName: outputBaseName,
                    fileURL: composedPair.stillPhotoURL,
                    fallbackExtension: "heic"
                )
            let pairedVideoOriginalFilename =
                Self.outputOriginalFilename(
                    baseName: outputBaseName,
                    fileURL: composedPair.pairedVideoURL,
                    fallbackExtension: "mov"
                )
            let diagnosticSourceFileName =
                sourceOriginalFilename ?? "nil"
            _ = PhotoMemoShareDiagnostics.recordResult(
                stage: .livePhotoOutputFilenameResolved,
                message:
                    "taskID=\(task.id.uuidString) source=\(diagnosticSourceFileName) still=\(stillPhotoOriginalFilename) pairedVideo=\(pairedVideoOriginalFilename)",
                defaults: diagnosticsDefaults
            )
            let saveResult =
                try await assetWriter.saveAsset(
                    LivePhotoSaveRequest(
                        stillPhotoFileURL:
                            composedPair
                            .stillPhotoURL,
                        pairedVideoFileURL:
                            composedPair
                            .pairedVideoURL,
                        captureDate:
                            importedPhoto
                            .metadata
                            .captureDate,
                        preferredAlbumIdentifier:
                            preferredAlbumIdentifier(
                                from: configuration
                        ),
                        stillPhotoOriginalFilename:
                            stillPhotoOriginalFilename,
                        pairedVideoOriginalFilename:
                            pairedVideoOriginalFilename
                    )
                )

            return LivePhotoBatchTaskResult(
                saveResult: saveResult,
                notificationSourceURL:
                    composedPair
                    .stillPhotoURL,
                temporaryFileURLs:
                    temporaryFileURLs
            )
        } catch {
            cleanupTemporaryFiles(
                temporaryFileURLs
            )
            throw error
        }
    }

    func importLivePhotoStill(
        from fileURL: URL,
        task: BatchTask,
        originalFileName: String? = nil,
        contentTypeIdentifier: String? = nil
    ) async throws -> SelectedPhoto {
        try await importService
            .importPhotoOffMainThread(
                from: fileURL,
                sourceInfo:
                    PhotoSourceInfo(
                        originalFileName:
                            originalFileName
                            ?? task.fileName,
                        assetLocalIdentifier:
                            task.sourceIdentifier,
                        contentTypeIdentifier:
                            contentTypeIdentifier
                            ?? task
                            .contentTypeIdentifier
                    )
            )
    }

    static func outputOriginalFilename(
        baseName: String,
        fileURL: URL,
        fallbackExtension: String
    ) -> String {
        let pathExtension = fileURL.pathExtension
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()
        return baseName + "." + (
            pathExtension.isEmpty
            ? fallbackExtension
            : pathExtension
        )
    }

    func descriptor(
        for task: BatchTask
    ) -> MediaProcessingInputDescriptor {
        let pixelSize =
            MediaPixelSize(
                fileURL: task.sourceURL
            )

        return MediaProcessingInputDescriptor(
            contentType:
                task
                .contentTypeIdentifier
                .flatMap(UTType.init),
            fileURL:
                task.sourceURL,
            pixelWidth:
                pixelSize?.width,
            pixelHeight:
                pixelSize?.height,
            isLivePhotoAsset: true
        )
    }

    func renderedCGImage(
        at fileURL: URL
    ) throws -> CGImage {
        guard
            let source =
                CGImageSourceCreateWithURL(
                    fileURL as CFURL,
                    [
                        kCGImageSourceShouldCache:
                            false
                    ] as CFDictionary
                ),
            let image =
                CGImageSourceCreateImageAtIndex(
                    source,
                    0,
                    nil
                )
        else {
            throw LivePhotoBatchTaskProcessingError
                .renderedOutputUnreadable
        }

        return image
    }

    func rendererFooterHeight(
        renderedImage: CGImage,
        card: RecordCard
    ) -> CGFloat {
        let renderedHeight =
            CGFloat(
                renderedImage.height
            )
        let footerHeight =
            renderedHeight
            - renderedHeight
            / (
                1
                + ClassicWhiteRenderer
                    .layout(
                        for:
                            ClassicWhiteRenderer
                            .orientation(
                                for:
                                    card.metadata
                            )
                    )
                    .borderToImageHeightRatio
            )

        return min(
            max(
                footerHeight,
                1
            ),
            max(
                renderedHeight - 1,
                1
            )
        )
    }

    func makeWorkDirectory() throws -> URL {
        let directoryURL =
            temporaryRootURL
            .appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )

        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        return directoryURL
    }

    func preferredAlbumIdentifier(
        from configuration:
            BatchConfigurationSnapshot
    ) -> String? {
        let trimmed =
            configuration
            .selectedAlbumIdentifier
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty
            ? nil
            : trimmed
    }

    func cleanupTemporaryFiles(
        _ urls: [URL]
    ) {
        for url in urls {
            try? fileManager.removeItem(
                at: url
            )
        }
    }
}
#endif
