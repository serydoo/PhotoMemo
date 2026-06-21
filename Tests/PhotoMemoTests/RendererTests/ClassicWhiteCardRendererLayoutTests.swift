import Testing
@testable import PhotoMemo

@Suite("Classic White card renderer layout")
struct ClassicWhiteCardRendererLayoutTests {

    @Test("Classic White converts the fixed grid into stable module widths")
    func classicWhiteConvertsFixedGridIntoStableModuleWidths() {

        let layout =
            ClassicWhiteCardRenderer
            .layoutMetrics(
                forTotalWidth: 960
            )

        #expect(layout.contentWidth == 800)
        #expect(layout.leftModuleWidth == 320)
        #expect(layout.centerModuleWidth == 160)
        #expect(layout.rightModuleWidth == 320)
        #expect(layout.contentHeight == 164)
    }

    @Test("Classic White clamps module widths when the container is narrower than padding")
    func classicWhiteClampsModuleWidthsWhenContainerIsNarrow() {

        let layout =
            ClassicWhiteCardRenderer
            .layoutMetrics(
                forTotalWidth: 120
            )

        #expect(layout.contentWidth == 0)
        #expect(layout.leftModuleWidth == 0)
        #expect(layout.centerModuleWidth == 0)
        #expect(layout.rightModuleWidth == 0)
        #expect(layout.contentHeight == 164)
    }
}
