import Foundation
import Testing
@testable import MemoMark

@Suite("MemoMarkAlbumSelection")
struct MemoMarkAlbumSelectionTests {

    @Test("Uses branded album title for automatic output")
    func usesBrandedAlbumTitleForAutomaticOutput() {

        #expect(
            MemoMarkAlbumSelection.defaultAlbumTitle
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
            MemoMarkAlbumSelection
            .normalizedIdentifier("") == ""
        )

        #expect(
            MemoMarkAlbumSelection
            .normalizedIdentifier(
                MemoMarkAlbumSelection
                    .automaticIdentifier
            ) == ""
        )

        #expect(
            MemoMarkAlbumSelection
            .normalizedIdentifier(
                MemoMarkAlbumSelection
                    .systemLibraryIdentifier
            )
            == MemoMarkAlbumSelection
                .systemLibraryIdentifier
        )
    }
}
