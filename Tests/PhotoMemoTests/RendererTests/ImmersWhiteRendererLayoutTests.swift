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
        let measuredSpec =
            RendererConstants
            .CompactInformationBar
            .portrait
        let rightTextStart =
            1
            - layout.horizontalPaddingRatio
            - layout.rightColumnWidthRatio
        let dividerCenter =
            rightTextStart
            - layout.dividerToTextSpacingRatio
        let logoCenter =
            dividerCenter
            - layout.logoToDividerSpacingRatio
            - (
                measuredSpec.barHeightToWidth
                * layout.logoSizeRatio
                / 2
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
            abs(
                rightTextStart
                - measuredSpec.rightX
            ) < 0.002
        )
        #expect(
            abs(
                dividerCenter
                - measuredSpec.dividerCenterX
            ) < 0.004
        )
        #expect(
            abs(
                logoCenter
                - measuredSpec.logoCenterX
            ) < 0.004
        )
        #expect(
            layout.groupSpacingRatio
            >= 0.095
        )
        #expect(
            layout.primaryYOffsetRatio == 0.019
        )
        #expect(
            layout.secondaryYOffsetRatio == -0.028
        )
        #expect(
            layout.titleFontRatio
            == 0.190
        )
        #expect(
            layout.bottomFontRatio
            == 0.142
        )
    }

    @Test("Landscape layout keeps a tighter centered text cluster")
    func landscapeLayoutKeepsATighterCenteredTextCluster() {

        let layout =
            ImmersWhiteRenderer.layout(
                for: .landscape
            )
        let measuredSpec =
            RendererConstants
            .CompactInformationBar
            .landscape
        let rightTextStart =
            1
            - layout.horizontalPaddingRatio
            - layout.rightColumnWidthRatio
        let dividerCenter =
            rightTextStart
            - layout.dividerToTextSpacingRatio
        let logoCenter =
            dividerCenter
            - layout.logoToDividerSpacingRatio
            - (
                measuredSpec.barHeightToWidth
                * layout.logoSizeRatio
                / 2
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
            abs(
                rightTextStart
                - measuredSpec.rightX
            ) < 0.002
        )
        #expect(
            abs(
                dividerCenter
                - measuredSpec.dividerCenterX
            ) < 0.004
        )
        #expect(
            abs(
                logoCenter
                - measuredSpec.logoCenterX
            ) < 0.004
        )
        #expect(
            layout.groupSpacingRatio
            >= 0.11
        )
        #expect(
            layout.primaryYOffsetRatio == 0.020
        )
        #expect(
            layout.secondaryYOffsetRatio == -0.037
        )
        #expect(
            layout.titleFontRatio
            == 0.190
        )
        #expect(
            layout.bottomFontRatio
            == 0.132
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
            == 6
        )
        #expect(
            ImmersWhiteRenderer.layout(for: .portrait).dividerWidthRatio
            == 0.022
        )
        #expect(
            ImmersWhiteRenderer.layout(for: .landscape).dividerWidthRatio
            == 0.022
        )
    }
}
