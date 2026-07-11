import Testing
@testable import PhotoMemo

@Suite("RecordCardRenderer routing")
struct RecordCardRendererRoutingTests {

    @Test("Canonical Classic White routes to the latest card renderer")
    func classicWhiteRoutesToLatestCardRenderer() {

        #expect(
            RecordCardRenderer
            .destination(for: .classicWhite)
            == .classicWhite
        )
    }
}
