#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@MainActor
private final class StubPhotoLibraryExportService:
    PhotoLibraryExporting {

    var albumOptionsToReturn:
        [PhotoAlbumOption] = []

    var ensuredAlbumToReturn =
        PhotoAlbumOption(
            id: "ensured-album",
            title: "photomemo",
            localIdentifier: "ensured-album"
        )

    var fetchAlbumOptionsCallCount = 0

    var ensureAlbumCallCount = 0

    var lastEnsuredAlbumTitle: String?

    func fetchAlbumOptions()
    async throws -> [PhotoAlbumOption] {

        fetchAlbumOptionsCallCount += 1
        return albumOptionsToReturn
    }

    func ensureAlbum(
        named title: String
    ) async throws -> PhotoAlbumOption {

        ensureAlbumCallCount += 1
        lastEnsuredAlbumTitle = title
        return ensuredAlbumToReturn
    }

    func saveImageResult(
        at fileURL: URL,
        metadata: PhotoMetadata,
        preferredAlbumIdentifier: String?
    ) async throws -> PhotoLibrarySaveResult {

        PhotoLibrarySaveResult(
            albumTitle:
                ensuredAlbumToReturn.title,
            assetLocalIdentifier:
                "saved-asset"
        )
    }
}

@Suite("Export migration", .serialized)
struct ExportMigrationTests {

    @Test("LoadPhotoLibraryAlbumsTransaction reads through the narrow album port")
    func loadPhotoLibraryAlbumsTransactionReadsThroughNarrowAlbumPort() async {

        let stubService =
            StubPhotoLibraryExportService()
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

        let result =
            await LoadPhotoLibraryAlbumsTransaction(
                albumAccess: stubService
            )
            .execute()

        switch result {
        case .loaded(let albums):
            #expect(stubService.fetchAlbumOptionsCallCount == 1)
            #expect(albums == stubService.albumOptionsToReturn)
        case .failed(let error):
            Issue.record(
                "Expected album-options intent to succeed, got \(error.message)"
            )
        }
    }

    @Test("EnsureExportAlbumIntent prepares destination album through ExportCoordinator")
    func ensureExportAlbumIntentPreparesDestinationAlbumThroughCoordinator() async {

        let stubService =
            StubPhotoLibraryExportService()
        stubService.ensuredAlbumToReturn =
            PhotoAlbumOption(
                id: "album-created",
                title: "photomemo",
                localIdentifier:
                    "album-created"
            )

        let coordinator =
            ExportCoordinator(
                exportService:
                    RecordCardExportService(),
                photoLibraryRepository:
                    PhotoLibraryRepository(
                        photoLibraryExportService:
                            stubService
                    )
            )

        let result =
            await EnsureExportAlbumIntent(
                title: "photomemo",
                coordinator: coordinator
            )
            .execute()

        switch result {
        case .success(let album):
            #expect(stubService.ensureAlbumCallCount == 1)
            #expect(
                stubService.lastEnsuredAlbumTitle
                == "photomemo"
            )
            #expect(
                album
                == stubService.ensuredAlbumToReturn
            )
        case .failure(let error):
            Issue.record(
                "Expected ensure-album intent to succeed, got \(error.message)"
            )
        }
    }

    @Test("ResolveV1OutputAlbumSelectionIntent keeps an existing album selection and falls back to automatic when missing")
    func resolveV1OutputAlbumSelectionIntentKeepsExistingAlbumSelectionAndFallsBackToAutomaticWhenMissing() async {

        let selectedAlbum =
            PhotoAlbumOption(
                id: "album-b",
                title: "Travel",
                localIdentifier:
                    "local-travel"
            )

        let selectedResult =
            await ResolveV1OutputAlbumSelectionIntent(
                request:
                    V1OutputAlbumSelectionRequest(
                        outputTarget:
                            .existingAlbum,
                        availableAlbums: [
                            PhotoAlbumOption(
                                id: "album-a",
                                title: "Family",
                                localIdentifier:
                                    "local-family"
                            ),
                            selectedAlbum
                        ],
                        selectedExistingAlbumIdentifier:
                            "album-b",
                        newAlbumName:
                            "ignored"
                    ),
                coordinator: nil
            )
            .execute()

        switch selectedResult {
        case .success(let selection):
            #expect(
                selection.identifier
                == "local-travel"
            )
            #expect(
                selection.title
                == "Travel"
            )
            #expect(
                selection.pickerSelectionIdentifier
                == "album-b"
            )
        case .failure(let error):
            Issue.record(
                "Expected existing-album resolution to succeed, got \(error.message)"
            )
        }

        let fallbackResult =
            await ResolveV1OutputAlbumSelectionIntent(
                request:
                    V1OutputAlbumSelectionRequest(
                        outputTarget:
                            .existingAlbum,
                        availableAlbums: [],
                        selectedExistingAlbumIdentifier:
                            "",
                        newAlbumName:
                            "ignored"
                    ),
                coordinator: nil
            )
            .execute()

        switch fallbackResult {
        case .success(let selection):
            #expect(
                selection.identifier
                == MemoMarkAlbumSelection
                .automaticIdentifier
            )
            #expect(
                selection.title
                == MemoMarkAlbumSelection
                .defaultAlbumTitle
            )
            #expect(
                selection.pickerSelectionIdentifier
                == nil
            )
        case .failure(let error):
            Issue.record(
                "Expected missing existing-album selection to fall back to automatic, got \(error.message)"
            )
        }
    }

    @Test("ResolveV1OutputAlbumSelectionIntent ensures a new album through ExportCoordinator")
    func resolveV1OutputAlbumSelectionIntentEnsuresNewAlbumThroughExportCoordinator() async {

        let stubService =
            StubPhotoLibraryExportService()
        stubService.ensuredAlbumToReturn =
            PhotoAlbumOption(
                id: "album-created",
                title: "photomemo",
                localIdentifier:
                    "local-created"
            )
        let coordinator =
            ExportCoordinator(
                exportService:
                    RecordCardExportService(),
                photoLibraryRepository:
                    PhotoLibraryRepository(
                        photoLibraryExportService:
                            stubService
                    )
            )

        let result =
            await ResolveV1OutputAlbumSelectionIntent(
                request:
                    V1OutputAlbumSelectionRequest(
                        outputTarget:
                            .newAlbum,
                        availableAlbums: [],
                        selectedExistingAlbumIdentifier:
                            "",
                        newAlbumName:
                            "photomemo"
                    ),
                coordinator: coordinator
            )
            .execute()

        switch result {
        case .success(let selection):
            #expect(
                stubService.ensureAlbumCallCount
                == 1
            )
            #expect(
                stubService.lastEnsuredAlbumTitle
                == "photomemo"
            )
            #expect(
                selection.identifier
                == "local-created"
            )
            #expect(
                selection.title
                == "photomemo"
            )
            #expect(
                selection.pickerSelectionIdentifier
                == "album-created"
            )
        case .failure(let error):
            Issue.record(
                "Expected new-album resolution to succeed, got \(error.message)"
            )
        }
    }

    @Test("new album resolution fails when the composed export coordinator is unavailable")
    func resolveOutputAlbumSelectionRequiresExportCoordinatorForNewAlbum() async {

        let result =
            await ResolveOutputAlbumSelectionIntent(
                request:
                    OutputAlbumSelectionRequest(
                        outputTarget: .newAlbum,
                        availableAlbums: [],
                        selectedExistingAlbumIdentifier: "",
                        newAlbumName: "MemoMark"
                    ),
                coordinator: nil
            )
            .execute()

        switch result {
        case .success:
            Issue.record(
                "A detached save transaction must not start a PhotoKit album operation."
            )
        case .failure(let error):
            #expect(error.code == .configurationUnavailable)
        }
    }
}
#endif
