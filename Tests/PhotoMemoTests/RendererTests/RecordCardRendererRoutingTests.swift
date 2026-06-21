import Testing
@testable import PhotoMemo

@Suite("RecordCardRenderer routing")
struct RecordCardRendererRoutingTests {

    @Test("Classic White presets route to the Classic White card renderer")
    func classicWhitePresetsRouteToClassicWhiteCardRenderer() {

        #expect(
            RecordCardRenderer
            .destination(for: .template2)
            == .classicWhite
        )
        #expect(
            RecordCardRenderer
            .destination(for: .template3)
            == .classicWhite
        )
    }

    @Test("Immers presets route to the Immers card renderer")
    func immersPresetsRouteToImmersCardRenderer() {

        #expect(
            RecordCardRenderer
            .destination(for: .template1)
            == .immersWhite
        )
        #expect(
            RecordCardRenderer
            .destination(for: .immersWhite)
            == .immersWhite
        )
    }
}
