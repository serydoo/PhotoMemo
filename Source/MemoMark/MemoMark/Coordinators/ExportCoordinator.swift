#if !MEMOMARK_SHARE_EXTENSION
import Foundation

@MainActor
final class ExportCoordinator {

    private let exportService:
        RecordCardExportService

    private let photoLibraryRepository:
        PhotoLibraryRepository

    init(
        exportService:
            RecordCardExportService,
        photoLibraryRepository:
            PhotoLibraryRepository
    ) {
        self.exportService =
            exportService
        self.photoLibraryRepository =
            photoLibraryRepository
    }

    func exportCard(
        photo: SelectedPhoto,
        card: RecordCard
    ) async -> MemoMarkResult<URL> {

        do {
            return .success(
                try await exportService
                .exportToTemporaryFile(
                    photo: photo,
                    card: card
                )
            )
        } catch {
            return .failure(
                .wrapped(
                    error,
                    code: .exportFailed,
                    message:
                        "Unable to export the rendered memory card."
                )
            )
        }
    }

    func saveRenderedPhoto(
        at fileURL: URL,
        metadata: PhotoMetadata,
        preferredAlbumIdentifier: String
    ) async -> MemoMarkResult<
        PhotoLibrarySaveResult
    > {

        await photoLibraryRepository
            .saveRenderedPhoto(
                at: fileURL,
                metadata: metadata,
                preferredAlbumIdentifier:
                    preferredAlbumIdentifier
            )
    }

    func saveRenderedPhoto(
        at fileURL: URL,
        metadata: PhotoMetadata,
        preferredAlbumIdentifier: String,
        idempotencyKey: String
    ) async -> MemoMarkResult<PhotoLibrarySaveResult> {

        await photoLibraryRepository
            .saveRenderedPhoto(
                at: fileURL,
                metadata: metadata,
                preferredAlbumIdentifier:
                    preferredAlbumIdentifier,
                idempotencyKey: idempotencyKey
            )
    }

    func fetchAlbumOptions()
    async -> MemoMarkResult<
        [PhotoAlbumOption]
    > {

        await photoLibraryRepository
            .fetchAlbumOptions()
    }

    func ensureAlbum(
        named title: String
    ) async -> MemoMarkResult<
        PhotoAlbumOption
    > {

        await photoLibraryRepository
            .ensureAlbum(
                named: title
            )
    }
}
#endif
