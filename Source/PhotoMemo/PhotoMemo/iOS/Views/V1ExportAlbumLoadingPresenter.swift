#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1ExportAlbumLoadProjection:
    Hashable {

    let availableAlbums:
        [PhotoAlbumOption]

    let selectedExistingAlbumIdentifier:
        String

    let albumStatusMessage:
        String
}

@MainActor
enum V1ExportAlbumLoadingPresenter {

    static func loadProjection(
        currentAvailableAlbums:
            [PhotoAlbumOption],
        selectedExistingAlbumIdentifier:
            String,
        coordinator:
            ExportCoordinator?
    ) async -> V1ExportAlbumLoadProjection {

        let result =
            await LoadV1ExportAlbumOptionsIntent(
                coordinator: coordinator
            )
            .execute()

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
            PhotoMemoResult<
                [PhotoAlbumOption]
            >,
        currentAvailableAlbums:
            [PhotoAlbumOption],
        selectedExistingAlbumIdentifier:
            String
    ) -> V1ExportAlbumLoadProjection {

        switch result {
        case .success(let albums):
            return V1ExportAlbumLoadProjection(
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

        case .failure(let error):
            return V1ExportAlbumLoadProjection(
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

private extension V1ExportAlbumLoadingPresenter {

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
