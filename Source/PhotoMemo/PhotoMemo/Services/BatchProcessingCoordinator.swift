import Foundation

@MainActor
final class BatchProcessingCoordinator {

    private let importService:
        PhotoImportService

    private let cardBuildService:
        RecordCardBuildService

    private let exportService:
        RecordCardExportService

    private let photoLibraryExportService:
        PhotoLibraryExportService

    init() {
        self.importService =
            PhotoImportService()
        self.cardBuildService =
            RecordCardBuildService()
        self.exportService =
            RecordCardExportService()
        self.photoLibraryExportService =
            PhotoLibraryExportService()
    }

    init(
        importService:
            PhotoImportService,
        cardBuildService:
            RecordCardBuildService,
        exportService:
            RecordCardExportService,
        photoLibraryExportService:
            PhotoLibraryExportService
    ) {
        self.importService =
            importService
        self.cardBuildService =
            cardBuildService
        self.exportService =
            exportService
        self.photoLibraryExportService =
            photoLibraryExportService
    }

    func importPhoto(
        for task: BatchTask
    ) async throws -> SelectedPhoto {

        try await importService
            .importPhotoOffMainThread(
                from: task.sourceURL,
                sourceInfo:
                    PhotoSourceInfo(
                        originalFileName:
                            task.fileName,
                        assetLocalIdentifier:
                            task.sourceIdentifier,
                        contentTypeIdentifier:
                            task.contentTypeIdentifier
                    )
            )
    }

    func buildCard(
        from photo: SelectedPhoto,
        configuration: BatchConfigurationSnapshot
    ) -> RecordCard {

        cardBuildService.buildCard(
            from: photo,
            configuration: configuration
        )
    }

    func exportCard(
        photo: SelectedPhoto,
        card: RecordCard
    ) throws -> URL {

        try exportService.exportToTemporaryFile(
            photo: photo,
            card: card
        )
    }

    func saveRenderedPhoto(
        at fileURL: URL,
        metadata: PhotoMetadata,
        preferredAlbumIdentifier: String
    ) async throws -> PhotoLibrarySaveResult {

        try await photoLibraryExportService
            .saveImageResult(
                at: fileURL,
                metadata: metadata,
                preferredAlbumIdentifier:
                    preferredAlbumIdentifier
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty
                    ? nil
                    : preferredAlbumIdentifier
            )
    }

    func cleanupTemporaryFile(
        at fileURL: URL?
    ) {

        guard let fileURL else {
            return
        }

        try? FileManager.default.removeItem(
            at: fileURL
        )
    }
}
