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

    @Test("Immers text can slightly compress before truncating and divider stays visibly present")
    func immersTextCanSlightlyCompressBeforeTruncatingAndDividerStaysVisiblyPresent() {

        #expect(
            ImmersWhiteRenderer.primaryMinimumScaleFactor
            >= 0.82
        )
        #expect(
            ImmersWhiteRenderer.secondaryMinimumScaleFactor
            >= 0.84
        )
        #expect(
            ImmersWhiteRenderer.dividerWidth
            == 2
        )
    }
}
