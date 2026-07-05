#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@MainActor
@Suite("Configuration snapshot builder")
struct ConfigurationSnapshotBuilderTests {

    @Test("builds a snapshot from the current session and keeps the selected carrier region")
    func buildsSnapshotFromSession() throws {
        let session = ConfigurationSession()
        session.selectRegion(.slotB)

        let snapshot =
            try #require(
                ConfigurationSnapshotBuilder.build(
                    from: session
                )
            )

        #expect(
            snapshot.subjectID
            == session.state.selectedSubject?.id
        )
        #expect(
            snapshot.memorySubject
            == session.state.selectedSubject
        )
        #expect(
            snapshot.primaryAnchor?.title
            == session.state.selectedSubject?.primaryTimeAnchor?.title
        )
        #expect(
            snapshot.primaryAnchor?.anchorType
            == session.state.selectedSubject?.primaryTimeAnchor?.anchorType
        )
        #expect(
            snapshot.smartModuleCarrierRegion
            == .slotB
        )
        #expect(
            snapshot.expression
            == session.state.selectedSubject?.behavior.memoryExpression
        )
    }
}
#endif
