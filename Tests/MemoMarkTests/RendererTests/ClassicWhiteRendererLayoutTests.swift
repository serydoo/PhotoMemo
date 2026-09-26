import CoreGraphics
import Foundation
import SwiftUI
import Testing
@testable import MemoMark

@Suite("ClassicWhiteRenderer Layout")
struct ClassicWhiteRendererLayoutTests {

    @Test("Portrait adaptive layout keeps the historical balanced state for full-width groups")
    func portraitAdaptiveLayoutKeepsTheHistoricalBalancedState() {
        let geometry = ClassicWhitePortraitLayoutSpecification.resolve(
            leftRowWidths: [0.28, 0.20],
            rightRowWidths: [0.406, 0.31],
            dividerWidthRatio: 0.006
        )

        #expect(abs(geometry.leftTextOriginX - 0.045) < 0.000_001)
        #expect(abs(geometry.rightTextOriginX - 0.549) < 0.000_001)
        #expect(abs(geometry.rightTextWidth - 0.406) < 0.000_001)
        #expect(abs(geometry.dividerCenterX - 0.520) < 0.000_001)
        #expect(abs(geometry.logoSlotOriginX - 0.402) < 0.000_001)
        #expect(geometry.leftToRightGroupGap >= 0.014)
    }

    @Test("Portrait right cluster contracts from the left while remaining right anchored")
    func portraitRightClusterContractsFromTheLeft() {
        let geometry = ClassicWhitePortraitLayoutSpecification.resolve(
            leftRowWidths: [0.19, 0.12],
            rightRowWidths: [0.18, 0.10],
            dividerWidthRatio: 0.006
        )

        #expect(abs(geometry.leftTextOriginX - 0.045) < 0.000_001)
        #expect(abs(geometry.rightTextOriginX + geometry.rightTextWidth - 0.955) < 0.000_001)
        #expect(geometry.logoSlotOriginX > 0.39)
        #expect(geometry.dividerCenterX > 0.50)
        #expect(geometry.leftToRightGroupGap >= 0.014)
    }

    @Test("Portrait adaptive layout bounds both groups without changing logo or group spacing")
    func portraitAdaptiveLayoutBoundsLongAsymmetricGroups() {
        let geometry = ClassicWhitePortraitLayoutSpecification.resolve(
            leftRowWidths: [0.58, 0.14],
            rightRowWidths: [0.61, 0.22],
            dividerWidthRatio: 0.006
        )

        #expect(geometry.leftTextWidth <= 0.364)
        #expect(geometry.rightTextWidth <= 0.406)
        #expect(geometry.didConstrainLeftText)
        #expect(geometry.didConstrainRightText)
        #expect(geometry.leftToRightGroupGap >= 0.014)
        #expect(geometry.logoSlotOriginX.isFinite)
        #expect(geometry.dividerCenterX.isFinite)
    }

    @Test("Portrait text measurement supports mixed Chinese and English rows")
    func portraitTextMeasurementSupportsMixedScripts() {
        let chinese = ClassicWhitePortraitLayoutSpecification.measureTextWidth(
            "陪你走过每一个重要时刻",
            fontSize: 18,
            tracking: -0.12
        )
        let mixed = ClassicWhitePortraitLayoutSpecification.measureTextWidth(
            "Our first Mid-Autumn Festival 中秋",
            fontSize: 18,
            tracking: -0.12
        )

        #expect(chinese > 0)
        #expect(mixed > 0)
        #expect(chinese.isFinite)
        #expect(mixed.isFinite)
    }

    @Test("Measured short, asymmetric, and maximum mixed-script content stays within both outer bounds")
    func portraitMeasuredContentMatrixKeepsBothGroupsWithinBounds() {
        let cases: [([String], [String])] = [
            (["家", "今天"], ["上海", "周末"]),
            (["The first day we met", "2026年中秋"], ["上海 · 徐汇区", "Together since 2021"]),
            (["陪你走过每一个值得纪念的日子", "五周年快乐"], ["Mid-Autumn Festival · Shanghai", "第 1826 天"]),
            ([String(repeating: "回忆与时光", count: 8), "Mixed 中英文纪念内容"], [
                String(repeating: "A meaningful moment ", count: 8),
                "这是一条较长的右侧纪念信息"
            ])
        ]

        for (leftRows, rightRows) in cases {
            let geometry = ClassicWhitePortraitLayoutSpecification.resolve(
                leftRowWidths: leftRows.map {
                    ClassicWhitePortraitLayoutSpecification.measureTextWidth(
                        $0,
                        fontSize: 18,
                        tracking: -0.12
                    ) / 360
                },
                rightRowWidths: rightRows.map {
                    ClassicWhitePortraitLayoutSpecification.measureTextWidth(
                        $0,
                        fontSize: 16,
                        tracking: -0.12
                    ) / 360
                },
                dividerWidthRatio: 0.006
            )

            #expect(geometry.leftTextOriginX == 0.045)
            #expect(abs(geometry.rightTextOriginX + geometry.rightTextWidth - 0.955) < 0.000_001)
            #expect(geometry.leftTextWidth <= 0.364)
            #expect(geometry.rightTextWidth <= 0.406)
            #expect(geometry.leftToRightGroupGap >= 0.014 - 0.000_001)
        }
    }

    @Test("Portrait maximum-width layout matches the historical balanced reference")
    func portraitMaximumWidthLayoutMatchesHistoricalBalancedReference() {

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
            - RendererConstants
                .CompactInformationBar
                .portrait
                .dividerWidthToBarHeight
                * RendererConstants
                    .CompactInformationBar
                    .portrait
                    .barHeightToWidth
                / 2
        let logoCenter =
            dividerCenter
            - (
                measuredSpec.barHeightToWidth
                * layout.dividerWidthRatio
                / 2
            )
            - layout.logoToDividerSpacingRatio
            - (
                measuredSpec.barHeightToWidth
                * layout.logoSizeRatio
                / 2
            )

        #expect(layout.rightColumnAlignment == .leading)
        #expect(measuredSpec.rightTextAlignment == .leading)
        #expect(
            layout.leftColumnWidthRatio
            == measuredSpec.leftWidth
        )
        #expect(
            layout.horizontalPaddingRatio
            + layout.leftGroupOffsetRatio
            == measuredSpec.leftX
        )
        #expect(
            layout.horizontalPaddingRatio
            >= ClassicWhitePortraitLayoutSpecification
                .minimumCanvasEdgeInset
        )
        #expect(
            abs(
                1 - (measuredSpec.rightX + measuredSpec.rightWidth)
                - ClassicWhitePortraitLayoutSpecification
                    .minimumCanvasEdgeInset
            ) < 0.000_001
        )
        #expect(
            layout.dividerToTextSpacingRatio
            == ClassicWhitePortraitLayoutSpecification
                .dividerToRightTextSpacing
        )
        #expect(abs(layout.dividerToTextSpacingRatio - 0.026) < 0.000_001)
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
            ) < 0.001
        )
        #expect(
            abs(
                logoCenter
                - measuredSpec.logoCenterX
            ) < 0.001
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

    @Test("Portrait divider-to-copy edge gap stays fixed as the right cluster adapts")
    func portraitDividerToCopyGapStaysFixedAsRightClusterAdapts() {
        let fullWidth = ClassicWhitePortraitLayoutSpecification.resolve(
            leftRowWidths: [0.25, 0.20],
            rightRowWidths: [0.406, 0.30],
            dividerWidthRatio: 0.006
        )
        let shortCopy = ClassicWhitePortraitLayoutSpecification.resolve(
            leftRowWidths: [0.25, 0.20],
            rightRowWidths: [0.18, 0.12],
            dividerWidthRatio: 0.006
        )

        for geometry in [fullWidth, shortCopy] {
            let dividerRightEdge = geometry.dividerCenterX + 0.006 / 2
            #expect(
                abs(
                    geometry.rightTextOriginX
                    - dividerRightEdge
                    - ClassicWhitePortraitLayoutSpecification.dividerToRightTextSpacing
                ) < 0.000_001
            )
        }

        #expect(abs(fullWidth.dividerCenterX - shortCopy.dividerCenterX) > 0.01)
        for geometry in [fullWidth, shortCopy] {
            let dividerLeftEdge = geometry.dividerCenterX - 0.006 / 2
            let logoSlotRightEdge =
                geometry.logoSlotOriginX
                + ClassicWhitePortraitLayoutSpecification.logoSlotWidth
            #expect(
                abs(
                    dividerLeftEdge
                    - logoSlotRightEdge
                    - ClassicWhitePortraitLayoutSpecification.logoToDividerSpacing
                ) < 0.000_001
            )
        }
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
        #expect(measuredSpec.rightTextAlignment == .leading)
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
