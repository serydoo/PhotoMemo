import Testing
@testable import MemoMark

@Suite("RecordCardRenderer routing")
struct RecordCardRendererRoutingTests {

    @Test("Canonical Classic White routes to the latest card renderer")
    func classicWhiteRoutesToLatestCardRenderer() {

        #expect(
            RecordCardRenderer
            .destination(for: TemplatePreset.classicWhite)
            == .classicWhite
        )
    }

    @Test("Minimal presentation route selects the Minimal renderer")
    func minimalRouteSelectsMinimalRenderer() {
        #expect(
            RecordCardRenderer.destination(for: .minimal)
            == .minimal
        )
    }

    @Test("FilmMark presentation route selects the FM renderer")
    func filmMarkRouteSelectsFilmMarkRenderer() {
        #expect(
            RecordCardRenderer.destination(for: .filmMark)
            == .filmMark
        )
    }
}
