#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("V1 output album load identity")
struct V1OutputAlbumLoadIdentityTests {

    @Test("album results are bound to the subject and configuration that requested them")
    func albumResultsAreBoundToTheRequestingIdentity() {
        let subjectID = UUID()
        let configurationID = UUID()
        let context = OutputAlbumLoadContext(
            subjectID: subjectID,
            configurationID: configurationID,
            outputTarget: .existingAlbum,
            selectedExistingAlbumIdentifier: "album-1"
        )

        #expect(
            context == OutputAlbumLoadContext(
                subjectID: subjectID,
                configurationID: configurationID,
                outputTarget: .existingAlbum,
                selectedExistingAlbumIdentifier: "album-1"
            )
        )
        #expect(
            context != OutputAlbumLoadContext(
                subjectID: UUID(),
                configurationID: configurationID,
                outputTarget: .existingAlbum,
                selectedExistingAlbumIdentifier: "album-1"
            )
        )
        #expect(
            context != OutputAlbumLoadContext(
                subjectID: subjectID,
                configurationID: UUID(),
                outputTarget: .existingAlbum,
                selectedExistingAlbumIdentifier: "album-1"
            )
        )
        #expect(
            context != OutputAlbumLoadContext(
                subjectID: subjectID,
                configurationID: configurationID,
                outputTarget: .automatic,
                selectedExistingAlbumIdentifier: "album-1"
            )
        )
        #expect(
            context != OutputAlbumLoadContext(
                subjectID: subjectID,
                configurationID: configurationID,
                outputTarget: .existingAlbum,
                selectedExistingAlbumIdentifier: "album-2"
            )
        )
    }
}
#endif
