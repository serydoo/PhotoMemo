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
        let request = V1OutputAlbumLoadRequest(
            generation: 3,
            subjectID: subjectID,
            configurationID: configurationID,
            outputTarget: .existingAlbum,
            selectedExistingAlbumIdentifier: "album-1"
        )

        #expect(
            request.matches(
                subjectID: subjectID,
                configurationID: configurationID
            )
        )
        #expect(
            !request.matches(
                subjectID: UUID(),
                configurationID: configurationID
            )
        )
        #expect(
            !request.matches(
                subjectID: subjectID,
                configurationID: UUID()
            )
        )
        #expect(
            request.matches(
                generation: 3,
                subjectID: subjectID,
                configurationID: configurationID,
                outputTarget: .existingAlbum,
                selectedExistingAlbumIdentifier: "album-1"
            )
        )
        #expect(
            !request.matches(
                generation: 2,
                subjectID: subjectID,
                configurationID: configurationID,
                outputTarget: .existingAlbum,
                selectedExistingAlbumIdentifier: "album-1"
            )
        )
        #expect(
            !request.matches(
                generation: 3,
                subjectID: subjectID,
                configurationID: configurationID,
                outputTarget: .automatic,
                selectedExistingAlbumIdentifier: "album-1"
            )
        )
    }
}
#endif
