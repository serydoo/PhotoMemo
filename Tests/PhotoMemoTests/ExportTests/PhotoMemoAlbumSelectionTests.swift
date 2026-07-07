import Foundation
import Testing
@testable import PhotoMemo

@Suite("PhotoMemoAlbumSelection")
struct PhotoMemoAlbumSelectionTests {

    @Test("Uses branded album title for automatic output")
    func usesBrandedAlbumTitleForAutomaticOutput() {

        #expect(
            PhotoMemoAlbumSelection.defaultAlbumTitle
            == "时光记"
        )

        #expect(
            PhotoAlbumOption.automatic.title
            == "自动存入时光记"
        )
    }

    @Test("Normalizes automatic album identifiers to default album behavior")
    func normalizesAutomaticAlbumIdentifiersToDefaultAlbumBehavior() {

        #expect(
            PhotoMemoAlbumSelection
            .normalizedIdentifier("") == ""
        )

        #expect(
            PhotoMemoAlbumSelection
            .normalizedIdentifier(
                PhotoMemoAlbumSelection
                    .automaticIdentifier
            ) == ""
        )

        #expect(
            PhotoMemoAlbumSelection
            .normalizedIdentifier(
                PhotoMemoAlbumSelection
                    .systemLibraryIdentifier
            )
            == PhotoMemoAlbumSelection
                .systemLibraryIdentifier
        )
    }
}
