import Testing
@testable import PhotoMemo

@Suite("ImmersWhiteRenderer Layout")
struct ImmersWhiteRendererLayoutTests {

    @Test("Portrait layout keeps the right column left aligned and matches top font sizing")
    func portraitLayoutKeepsRightColumnLeftAlignedAndMatchesTopFontSizing() {

        let layout =
            ImmersWhiteRenderer.layout(
                for: .portrait
            )

        #expect(
            layout.rightColumnAlignment
            == .leading
        )
        #expect(
            layout.metadataFontRatio
            == layout.titleFontRatio
        )
        #expect(
            layout.dividerToTextSpacingRatio
            < layout.logoToDividerSpacingRatio
        )
    }

    @Test("Landscape layout keeps the right column left aligned and matches top font sizing")
    func landscapeLayoutKeepsRightColumnLeftAlignedAndMatchesTopFontSizing() {

        let layout =
            ImmersWhiteRenderer.layout(
                for: .landscape
            )

        #expect(
            layout.rightColumnAlignment
            == .leading
        )
        #expect(
            layout.metadataFontRatio
            == layout.titleFontRatio
        )
        #expect(
            layout.dividerToTextSpacingRatio
            < layout.logoToDividerSpacingRatio
        )
    }
}
