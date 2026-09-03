#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct OutputAlbumLoadProjection:
    Hashable {

    let availableAlbums:
        [PhotoAlbumOption]

    let selectedExistingAlbumIdentifier:
        String

    let albumStatusMessage:
        String
}

enum OutputAlbumRuntimeUpdate: Equatable {
    case loadingStarted
    case loadingEnded
    case completed(OutputAlbumLoadProjection)
}

/// Owns album-load request identity and stale-completion suppression without
/// owning the output draft, PhotoKit access, or durable configuration truth.
@MainActor
final class OutputAlbumRuntimeCoordinator {

    private var activeRequestID: UUID?

    func load(
        context: OutputAlbumLoadContext,
        performLoad: () async -> OutputAlbumLoadProjection,
        currentContext: () -> OutputAlbumLoadContext,
        apply: (OutputAlbumRuntimeUpdate) -> Void
    ) async {
        let requestID = UUID()
        activeRequestID = requestID
        apply(.loadingStarted)

        let projection = await performLoad()
        let shouldApply =
            !Task.isCancelled
            && activeRequestID == requestID
            && currentContext() == context

        guard shouldApply else {
            finishRejectedRequest(
                requestID,
                apply: apply
            )
            return
        }

        activeRequestID = nil
        apply(.completed(projection))
    }

    private func finishRejectedRequest(
        _ requestID: UUID,
        apply: (OutputAlbumRuntimeUpdate) -> Void
    ) {
        guard activeRequestID == requestID else {
            return
        }
        activeRequestID = nil
        apply(.loadingEnded)
    }
}

@MainActor
enum ExportAlbumLoadingPresenter {

    static func loadProjection(
        currentAvailableAlbums:
            [PhotoAlbumOption],
        selectedExistingAlbumIdentifier:
            String,
        transaction:
            LoadPhotoLibraryAlbumsTransaction
    ) async -> OutputAlbumLoadProjection {

        let result =
            await transaction.execute()

        return projectedState(
            from: result,
            currentAvailableAlbums:
                currentAvailableAlbums,
            selectedExistingAlbumIdentifier:
                selectedExistingAlbumIdentifier
        )
    }

    static func projectedState(
        from result:
            LoadPhotoLibraryAlbumsResult,
        currentAvailableAlbums:
            [PhotoAlbumOption],
        selectedExistingAlbumIdentifier:
            String
    ) -> OutputAlbumLoadProjection {

        switch result {
        case .loaded(let albums):
            return OutputAlbumLoadProjection(
                availableAlbums: albums,
                selectedExistingAlbumIdentifier:
                    resolvedSelectionIdentifier(
                        from: albums,
                        selectedExistingAlbumIdentifier:
                            selectedExistingAlbumIdentifier
                    ),
                albumStatusMessage:
                    albums.isEmpty
                    ? "没有找到可选择的自建相册。"
                    : ""
            )

        case .failed(let error):
            return OutputAlbumLoadProjection(
                availableAlbums:
                    currentAvailableAlbums,
                selectedExistingAlbumIdentifier:
                    selectedExistingAlbumIdentifier,
                albumStatusMessage:
                    error.message
            )
        }
    }
}

private extension ExportAlbumLoadingPresenter {

    static func resolvedSelectionIdentifier(
        from albums: [PhotoAlbumOption],
        selectedExistingAlbumIdentifier:
            String
    ) -> String {

        guard
            selectedExistingAlbumIdentifier
            .isEmpty,
            let firstAlbum = albums.first
        else {
            return selectedExistingAlbumIdentifier
        }

        return firstAlbum.id
    }
}
#endif
