#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import UniformTypeIdentifiers

final class PhotoRepository {

    private let importService:
        PhotoImportService

    private let photoLibraryExportService:
        PhotoLibraryExportService

    init(
        importService: PhotoImportService,
        photoLibraryExportService:
            PhotoLibraryExportService
    ) {
        self.importService =
            importService
        self.photoLibraryExportService =
            photoLibraryExportService
    }

    func importPhoto(
        from url: URL,
        sourceInfo: PhotoSourceInfo? = nil
    ) async -> PhotoMemoResult<
        SelectedPhoto
    > {

        do {
            return .success(
                try await importService
                .importPhoto(
                    from: url,
                    sourceInfo: sourceInfo
                )
            )
        } catch {
            return .failure(
                .wrapped(
                    error,
                    code: .importFailed,
                    message:
                        "Unable to import the selected photo."
                )
            )
        }
    }

    func importPhoto(
        from data: Data,
        suggestedFileName: String?,
        contentType: UTType?,
        assetLocalIdentifier: String? = nil
    ) async -> PhotoMemoResult<
        SelectedPhoto
    > {

        do {
            return .success(
                try await importService
                .importPhoto(
                    from: data,
                    suggestedFileName:
                        suggestedFileName,
                    contentType:
                        contentType,
                    assetLocalIdentifier:
                        assetLocalIdentifier
                )
            )
        } catch {
            return .failure(
                .wrapped(
                    error,
                    code: .importFailed,
                    message:
                        "Unable to import the selected photo data."
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

        do {
            return .success(
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
}
#endif
