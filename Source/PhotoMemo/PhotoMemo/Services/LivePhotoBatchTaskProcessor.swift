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

@MainActor
final class LivePhotoBatchTaskProcessor:
    LivePhotoBatchTaskProcessing {

    private let planner:
        MediaProcessingPlanner
    private let assetLoader:
        any LivePhotoAssetLoading
    private let pairComposer:
        LivePhotoPairCompositionService
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
            LivePhotoPairCompositionService? = nil,
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

private extension LivePhotoBatchTaskProcessor {

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
        guard
            let assetLocalIdentifier =
                task.sourceIdentifier?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
            !assetLocalIdentifier.isEmpty
        else {
            throw LivePhotoBatchTaskProcessingError
                .assetLocalIdentifierMissing
        }

        let workDirectoryURL =
            try makeWorkDirectory()
        var temporaryFileURLs: [URL] = [
            workDirectoryURL
        ]

        do {
            let bundle =
                try await assetLoader.bundle(
                    for: assetLocalIdentifier
                )
            let preparedBundle =
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
                            task.fileName,
                        pairedVideoOriginalFilename:
                            preparedBundle
                            .pairedVideoResource
                            .originalFilename
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
        let footerHeight: CGFloat =
            switch card.template.preset.renderLayout {
            case .classicWhite:
                ClassicWhiteRenderer
                    .theme
                    .bottomBar
                    .height
            case .immersWhite:
                renderedHeight
                    - renderedHeight
                    / (
                        1
                        + ImmersWhiteRenderer
                            .layout(
                                for:
                                    ImmersWhiteRenderer
                                    .orientation(
                                        for:
                                            card.metadata
                                    )
                            )
                            .borderToImageHeightRatio
                    )
            }

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
