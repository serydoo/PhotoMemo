import Foundation
import Testing
@testable import PhotoMemo

@Suite("PhotoMemoAlbumSelection")
struct PhotoMemoAlbumSelectionTests {

    @Test("Uses lowercase photomemo as the automatic album title")
    func usesLowercasePhotomemoAsAutomaticAlbumTitle() {

        #expect(
            PhotoMemoAlbumSelection.defaultAlbumTitle
            == "photomemo"
        )

        #expect(
            PhotoAlbumOption.automatic.title
            == "自动存入 photomemo"
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
