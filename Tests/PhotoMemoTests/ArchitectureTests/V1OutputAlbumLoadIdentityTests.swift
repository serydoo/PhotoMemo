#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 output album load identity")
struct V1OutputAlbumLoadIdentityTests {

    @Test("album results are bound to the subject and configuration that requested them")
    func albumResultsAreBoundToTheRequestingIdentity() {
        let subjectID = UUID()
        let configurationID = UUID()
        let request = V1OutputAlbumLoadRequest(
            subjectID: subjectID,
            configurationID: configurationID
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
    }
}
#endif
