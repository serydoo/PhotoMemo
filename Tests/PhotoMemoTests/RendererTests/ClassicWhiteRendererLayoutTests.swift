import Testing
@testable import PhotoMemo

@Suite("ClassicWhiteRenderer Layout")
struct ClassicWhiteRendererLayoutTests {

    @Test("Portrait layout keeps a tighter centered text cluster")
    func portraitLayoutKeepsATighterCenteredTextCluster() {

        let layout =
            ClassicWhiteRenderer.layout(
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
            < layout.titleFontRatio
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
            layout.metadataFontRatio
            == 0.154
        )
        #expect(
            layout.bottomFontRatio
            == 0.142
        )
        #expect(
            layout.dividerHeightRatio
            == 0.465
        )
        #expect(
            layout.customLogoScaleRatio
            == 1.36
        )
    }

    @Test("Landscape layout keeps a tighter centered text cluster")
    func landscapeLayoutKeepsATighterCenteredTextCluster() {

        let layout =
            ClassicWhiteRenderer.layout(
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
        #expect(
            layout.customLogoScaleRatio
            == 1.00
        )
        #expect(
            layout.logoSizeRatio
            == layout.dividerHeightRatio
        )
    }

    @Test("Classic White text can slightly compress before truncating and divider stays visibly present")
    func classicWhiteTextCanSlightlyCompressBeforeTruncatingAndDividerStaysVisiblyPresent() {

        #expect(
            ClassicWhiteRenderer.primaryMinimumScaleFactor
            >= 0.82
        )
        #expect(
            ClassicWhiteRenderer.secondaryMinimumScaleFactor
            >= 0.84
        )
        #expect(
            ClassicWhiteRenderer.dividerWidth
            == 6
        )
        #expect(
            ClassicWhiteRenderer.layout(for: .portrait).dividerWidthRatio
            == 0.022
        )
        #expect(
            ClassicWhiteRenderer.layout(for: .landscape).dividerWidthRatio
            == 0.022
        )
    }
}
