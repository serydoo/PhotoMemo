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
                .importPhotoOffMainThread(
                    from: url,
                    sourceInfo: sourceInfo
                )
            )
        } catch {
            let importError = error as? PhotoImportError
            return .failure(
                PhotoMemoError(
                    code: .importFailed,
                    message:
                        "Unable to import the selected photo.",
                    underlyingDescription:
                        String(describing: error),
                    diagnosticCode:
                        importError?.diagnosticCode
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
            let importError = error as? PhotoImportError
            return .failure(
                PhotoMemoError(
                    code: .importFailed,
                    message:
                        "Unable to import the selected photo data.",
                    underlyingDescription:
                        String(describing: error),
                    diagnosticCode:
                        importError?.diagnosticCode
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
