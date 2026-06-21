import Testing
@testable import PhotoMemo

@Suite("ImmersWhiteRenderer Layout")
struct ImmersWhiteRendererLayoutTests {

    @Test("Portrait layout keeps a tighter centered text cluster")
    func portraitLayoutKeepsATighterCenteredTextCluster() {

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
        #expect(
            layout.groupSpacingRatio
            >= 0.095
        )
        #expect(
            layout.titleFontRatio
            <= 0.225
        )
    }

    @Test("Landscape layout keeps a tighter centered text cluster")
    func landscapeLayoutKeepsATighterCenteredTextCluster() {

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
        #expect(
            layout.groupSpacingRatio
            >= 0.11
        )
        #expect(
            layout.titleFontRatio
            <= 0.22
        )
    }

    @Test("Immers primary text keeps near-full scale and divider stays visibly present")
    func immersPrimaryTextKeepsNearFullScaleAndDividerStaysVisiblyPresent() {

        #expect(
            ImmersWhiteRenderer.primaryMinimumScaleFactor
            >= 0.94
        )
        #expect(
            ImmersWhiteRenderer.secondaryMinimumScaleFactor
            >= 0.88
        )
        #expect(
            ImmersWhiteRenderer.dividerWidth
            == 2
        )
    }
}
