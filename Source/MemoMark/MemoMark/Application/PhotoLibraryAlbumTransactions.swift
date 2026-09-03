#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Narrow application port for reading the user's Photo Library albums.
/// Saving assets and creating albums remain separate capabilities.
protocol PhotoLibraryAlbumAccessing {

    func fetchAlbumOptions() async throws -> [PhotoAlbumOption]
}

struct PhotoLibraryAlbumLoadFailure: Error, Equatable {

    let message: String

    let underlyingDescription: String

    let diagnosticCode: String?
}

enum LoadPhotoLibraryAlbumsResult: Equatable {

    case loaded([PhotoAlbumOption])

    case failed(PhotoLibraryAlbumLoadFailure)
}

/// Read-only application transaction used by presentation to obtain the
/// current Photo Library album choices without depending on an export facade.
struct LoadPhotoLibraryAlbumsTransaction {

    private let albumAccess:
        any PhotoLibraryAlbumAccessing

    init(
        albumAccess:
            any PhotoLibraryAlbumAccessing
    ) {
        self.albumAccess = albumAccess
    }

    func execute()
    async -> LoadPhotoLibraryAlbumsResult {

        do {
            return .loaded(
                try await albumAccess
                    .fetchAlbumOptions()
            )
        } catch {
            return .failed(
                PhotoLibraryAlbumLoadFailure(
                    message:
                        "Unable to load system photo albums.",
                    underlyingDescription:
                        String(describing: error),
                    diagnosticCode:
                        (error as? PhotoLibraryExportError)?
                        .diagnosticCode
                )
            )
        }
    }
}
#endif
