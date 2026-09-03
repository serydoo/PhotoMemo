#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@MainActor
private final class PresenterStubPhotoLibraryExportService:
    PhotoLibraryExporting {

    var albumOptionsToReturn:
        [PhotoAlbumOption] = []

    var fetchAlbumOptionsCallCount = 0

    func fetchAlbumOptions()
    async throws -> [PhotoAlbumOption] {

        fetchAlbumOptionsCallCount += 1
        return albumOptionsToReturn
    }

    func ensureAlbum(
        named title: String
    ) async throws -> PhotoAlbumOption {

        PhotoAlbumOption(
            id: title,
            title: title,
            localIdentifier: title
        )
    }

    func saveImageResult(
        at fileURL: URL,
        metadata: PhotoMetadata,
        preferredAlbumIdentifier: String?
    ) async throws -> PhotoLibrarySaveResult {

        PhotoLibrarySaveResult(
            albumTitle: "photomemo",
            assetLocalIdentifier: "saved-asset"
        )
    }
}

@Suite("Export album presenter", .serialized)
struct ExportAlbumPresenterTests {

    @Test("load projection reads album options through the application transaction and auto-selects the first album when the picker has no selection")
    func loadProjectionReadsAlbumOptionsThroughTransactionAndAutoSelectsFirstAlbum() async {

        let stubService =
            PresenterStubPhotoLibraryExportService()
        stubService.albumOptionsToReturn = [
            PhotoAlbumOption(
                id: "album-a",
                title: "Family",
                localIdentifier: "album-a"
            ),
            PhotoAlbumOption(
                id: "album-b",
                title: "Travel",
                localIdentifier: "album-b"
            )
        ]

        let transaction =
            LoadPhotoLibraryAlbumsTransaction(
                albumAccess: stubService
            )

        let projection =
            await ExportAlbumLoadingPresenter
            .loadProjection(
                currentAvailableAlbums: [],
                selectedExistingAlbumIdentifier:
                    "",
                transaction: transaction
            )

        #expect(
            stubService.fetchAlbumOptionsCallCount
            == 1
        )
        #expect(
            projection.availableAlbums
            == stubService.albumOptionsToReturn
        )
        #expect(
            projection
            .selectedExistingAlbumIdentifier
            == "album-a"
        )
        #expect(
            projection.albumStatusMessage
            .isEmpty
        )
    }

    @Test("projection keeps an existing picker selection instead of replacing it with the first loaded album")
    func projectionKeepsExistingPickerSelection() {

        let projection =
            ExportAlbumLoadingPresenter
            .projectedState(
                from: .loaded([
                    PhotoAlbumOption(
                        id: "album-a",
                        title: "Family",
                        localIdentifier:
                            "album-a"
                    ),
                    PhotoAlbumOption(
                        id: "album-b",
                        title: "Travel",
                        localIdentifier:
                            "album-b"
                    )
                ]),
                currentAvailableAlbums: [],
                selectedExistingAlbumIdentifier:
                    "album-b"
            )

        #expect(
            projection
            .selectedExistingAlbumIdentifier
            == "album-b"
        )
        #expect(
            projection.availableAlbums.count
            == 2
        )
        #expect(
            projection.albumStatusMessage
            .isEmpty
        )
    }

    @Test("projection surfaces the empty-album status message when loading succeeds without any user albums")
    func projectionSurfacesEmptyAlbumStatusMessage() {

        let projection =
            ExportAlbumLoadingPresenter
            .projectedState(
                from: .loaded([]),
                currentAvailableAlbums: [],
                selectedExistingAlbumIdentifier:
                    ""
            )

        #expect(
            projection.availableAlbums
            .isEmpty
        )
        #expect(
            projection
            .selectedExistingAlbumIdentifier
            .isEmpty
        )
        #expect(
            projection.albumStatusMessage
            == "没有找到可选择的自建相册。"
        )
    }

    @Test("projection preserves the current albums and picker selection when album loading fails")
    func projectionPreservesCurrentStateWhenAlbumLoadingFails() {

        let currentAlbums = [
            PhotoAlbumOption(
                id: "album-a",
                title: "Family",
                localIdentifier: "album-a"
            )
        ]

        let projection =
            ExportAlbumLoadingPresenter
            .projectedState(
                from: .failed(
                    PhotoLibraryAlbumLoadFailure(
                        message:
                            "Unable to load system photo albums.",
                        underlyingDescription:
                            "fixture failure",
                        diagnosticCode: nil
                    )
                ),
                currentAvailableAlbums:
                    currentAlbums,
                selectedExistingAlbumIdentifier:
                    "album-a"
            )

        #expect(
            projection.availableAlbums
            == currentAlbums
        )
        #expect(
            projection
            .selectedExistingAlbumIdentifier
            == "album-a"
        )
        #expect(
            projection.albumStatusMessage
            == "Unable to load system photo albums."
        )
    }
}
#endif
