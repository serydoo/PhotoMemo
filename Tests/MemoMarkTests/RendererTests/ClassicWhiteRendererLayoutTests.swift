import CoreGraphics
import Foundation
import SwiftUI
import Testing
@testable import MemoMark

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

    @MainActor
    @Test("Classic White exposes a complete footer artifact for still and motion output")
    func exposesCompleteFooterArtifactForStillAndMotionOutput() throws {
        let metadata = PhotoMetadata(
            imageWidth: 400,
            imageHeight: 300
        )
        let card = RecordCard(
            template: .classicWhite,
            presentationStyle: .classicWhite,
            metadata: metadata,
            context: MetadataContext(),
            badge: .appleClassic,
            title: "底栏内容"
        )
        let outputSize = ClassicWhiteRenderer.outputPixelSize(
            for: metadata,
            fallbackSize: CGSize(width: 400, height: 300)
        )
        let artifact = try RecordCardPresentationPlanner()
            .artifact(
                for: card,
                canvasSize: outputSize
            )

        #expect(artifact.placement == .footer)
        #expect(artifact.canvasBackground == .opaqueWhite)
        #expect(artifact.canvasSize == outputSize)
        #expect(artifact.photoFrame.height == 300)
        #expect(artifact.footerFrame.height == outputSize.height - 300)
        #expect(artifact.footerFrame.maxY == artifact.photoFrame.minY)
        #expect(artifact.layers.count == 1)
        #expect(artifact.layers[0].frame == artifact.footerFrame)
        #expect(artifact.layers[0].image.width == Int(outputSize.width))
        #expect(
            artifact.layers[0].image.height
            == Int(artifact.footerFrame.height)
        )
    }
}
