#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

final class PhotoLibraryRepository {

    private let photoLibraryExportService:
        PhotoLibraryExporting

    init(
        photoLibraryExportService:
            PhotoLibraryExporting
    ) {
        self.photoLibraryExportService =
            photoLibraryExportService
    }

    func fetchAlbumOptions()
    async -> PhotoMemoResult<
        [PhotoAlbumOption]
    > {

        do {
            return .success(
                try await photoLibraryExportService
                .fetchAlbumOptions()
            )
        } catch {
            return .failure(
                .wrapped(
                    error,
                    code: .photoLibrarySaveFailed,
                    message:
                        "Unable to load system photo albums."
                )
            )
        }
    }

    func ensureAlbum(
        named title: String
    ) async -> PhotoMemoResult<
        PhotoAlbumOption
    > {

        do {
            return .success(
                try await photoLibraryExportService
                .ensureAlbum(
                    named: title
                )
            )
        } catch {
            return .failure(
                .wrapped(
                    error,
                    code: .photoLibrarySaveFailed,
                    message:
                        "Unable to prepare the destination album."
                )
            )
        }
    }

    func saveRenderedPhoto(
        at fileURL: URL,
        metadata: PhotoMetadata,
        preferredAlbumIdentifier: String?
    ) async -> PhotoMemoResult<
        PhotoLibrarySaveResult
    > {

        do {
            return .success(
                try await photoLibraryExportService
                .saveImageResult(
                    at: fileURL,
                    metadata: metadata,
                    preferredAlbumIdentifier:
                        normalizedAlbumIdentifier(
                            preferredAlbumIdentifier
                        )
                )
            )
        } catch {
            return .failure(
                .wrapped(
                    error,
                    code: .photoLibrarySaveFailed,
                    message:
                        "Unable to save the rendered photo to the system photo library."
                )
            )
        }
    }

    func saveRenderedPhoto(
        at fileURL: URL,
        metadata: PhotoMetadata,
        preferredAlbumIdentifier: String?,
        idempotencyKey: String
    ) async -> PhotoMemoResult<PhotoLibrarySaveResult> {

        do {
            return .success(
                try await photoLibraryExportService
                    .saveImageResult(
                        at: fileURL,
                        metadata: metadata,
                        preferredAlbumIdentifier:
                            normalizedAlbumIdentifier(
                                preferredAlbumIdentifier
                            ),
                        idempotencyKey: idempotencyKey
                    )
            )
        } catch {
            return .failure(
                .wrapped(
                    error,
                    code: .photoLibrarySaveFailed,
                    message:
                        "Unable to save the rendered photo to the system photo library."
                )
            )
        }
    }

    func saveRenderedPhoto(
        at fileURL: URL,
        metadata: PhotoMetadata,
        preferredAlbumIdentifier: String
    ) async -> PhotoMemoResult<
        PhotoLibrarySaveResult
    > {

        await saveRenderedPhoto(
            at: fileURL,
            metadata: metadata,
            preferredAlbumIdentifier:
                Optional(
                    preferredAlbumIdentifier
                )
        )
    }
}

private extension PhotoLibraryRepository {

    func normalizedAlbumIdentifier(
        _ preferredAlbumIdentifier: String?
    ) -> String? {

        guard
            let trimmedIdentifier =
                preferredAlbumIdentifier?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
            !trimmedIdentifier.isEmpty
        else {
            return nil
        }

        return trimmedIdentifier
    }
}
#endif
