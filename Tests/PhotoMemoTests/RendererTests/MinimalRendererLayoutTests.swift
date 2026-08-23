import CoreGraphics
import Foundation
import SwiftUI
import Testing
@testable import PhotoMemo

@Suite("Minimal renderer layout")
struct MinimalRendererLayoutTests {

    @Test("Landscape uses a thin single-line bottom bar")
    func landscapeGeometry() {
        let layout = MinimalRenderer.layout(for: .landscape)

        #expect(layout.barHeightToImageWidth == 0.075)
        #expect(layout.trailingAnchorX == 0.95)
        #expect(layout.maximumModuleWidth == 0.62)
        #expect(layout.textLineLimit == 1)
        #expect(layout.textSizeToBarHeight == 0.38)
    }

    @Test("Portrait uses a taller two-line bottom bar")
    func portraitGeometry() {
        let layout = MinimalRenderer.layout(for: .portrait)

        #expect(layout.barHeightToImageWidth == 0.095)
        #expect(layout.trailingAnchorX == 0.94)
        #expect(layout.maximumModuleWidth == 0.82)
        #expect(layout.textLineLimit == 2)
        #expect(layout.textSizeToBarHeight == 0.31)
    }

    @Test("Minimal output keeps the source photo canvas")
    func outputSize() {
        let landscape = MinimalRenderer.outputPixelSize(
            imageWidth: 4_032,
            imageHeight: 3_024
        )
        let portrait = MinimalRenderer.outputPixelSize(
            imageWidth: 3_024,
            imageHeight: 4_032
        )

        #expect(landscape == CGSize(width: 4_032, height: 3_024))
        #expect(portrait == CGSize(width: 3_024, height: 4_032))
    }

    @Test("Minimal normalizes odd source dimensions before media encoding")
    func outputSizeNormalizesOddDimensions() {
        let oddLandscape = MinimalRenderer.outputPixelSize(
            imageWidth: 5_712,
            imageHeight: 3_213
        )
        let oddPortrait = MinimalRenderer.outputPixelSize(
            imageWidth: 3_213,
            imageHeight: 5_712
        )

        #expect(oddLandscape == CGSize(width: 5_712, height: 3_214))
        #expect(oddPortrait == CGSize(width: 3_214, height: 5_712))
    }

    @Test("Compact preview shows an image slice with a trailing floating module")
    func compactPreviewGeometry() {
        let preview = MinimalCardLayoutSpecification.compactPreview

        #expect(preview.imageSliceHeightToWidth == 0.20625)
        #expect(preview.moduleWidthToWidth == 0.68)
    }

    @Test("Minimal layout uses a same-canvas floating module")
    func sameCanvasFloatingGeometry() {
        let layout = MinimalRenderer.layout(for: .landscape)

        #expect(layout.outputAddsBottomBar == false)
        #expect(layout.barHeightToImageWidth == 0.075)
        #expect(layout.capsuleHorizontalPaddingToBarHeight == 0.50)
        #expect(layout.capsuleVerticalPaddingToBarHeight == 0.00)
        #expect(layout.avatarLeadingInsetToBarHeight == 0.08)
        #expect(layout.avatarAreaWidthToBarHeight == 0.92)
        #expect(layout.avatarSizeToBarHeight == 0.78)
        #expect(layout.avatarTextSpacingToBarHeight == 0.20)
    }

    @Test("Minimal avatar fits inside the capsule silhouette")
    func avatarFitsInsideCapsuleSilhouette() {
        for orientation in [
            MinimalRenderer.Orientation.landscape,
            .portrait
        ] {
            let layout = MinimalRenderer.layout(for: orientation)

            #expect(layout.capsuleVerticalPaddingToBarHeight == 0)
            #expect(layout.avatarSizeToBarHeight < layout.capsuleHeightToBarHeight)
            #expect(layout.avatarAreaWidthToBarHeight > layout.avatarSizeToBarHeight)
            #expect(
                layout.avatarLeadingInsetToBarHeight
                + layout.avatarSizeToBarHeight
                <= layout.avatarAreaWidthToBarHeight
            )
        }
    }

    @Test("Minimal uses the existing Apple logo when no badge is configured")
    func emptyBadgeUsesAppleLogoFallback() {
        #expect(
            ClassicWhiteRenderer.FrameInput
                .resolvedLogoBadge(from: nil)
                == .appleClassic
        )
        #expect(
            ClassicWhiteRenderer.FrameInput
                .resolvedLogoBadge(from: Badge.none)
            == .appleClassic
        )
    }

    @Test("Minimal projects the canonical smart result from the memory region")
    func projectsSmartResultFromMemoryRegion() {
        var template = Template.classicWhite
        template.leftTopArea.items = []
        template.rightBottomArea.items = [.title]

        let metadata = PhotoMetadata(
            imageWidth: 4_032,
            imageHeight: 3_024
        )
        let card = RecordCard(
            template: template,
            presentationStyle: .minimal,
            metadata: metadata,
            context: MetadataContext(),
            title: "智能输出结果"
        )

        #expect(
            MinimalRenderer.informationText(for: card)
            == "智能输出结果"
        )
    }

    @Test("Minimal keeps legacy slot A content as a compatibility fallback")
    func keepsLegacySlotAContentAsFallback() {
        var template = Template.classicWhite
        template.leftTopArea.items = [.title]
        template.rightBottomArea.items = []

        let metadata = PhotoMetadata(
            imageWidth: 4_032,
            imageHeight: 3_024
        )
        let card = RecordCard(
            template: template,
            presentationStyle: .minimal,
            metadata: metadata,
            context: MetadataContext(),
            title: "旧配置内容"
        )

        #expect(
            MinimalRenderer.informationText(for: card)
            == "旧配置内容"
        )
    }

    @Test("Minimal creates one transparent bounded layer for media composition")
    @MainActor
    func createsBoundedFloatingArtifact() throws {
        let metadata = PhotoMetadata(
            imageWidth: 400,
            imageHeight: 300
        )
        let card = RecordCard(
            template: .classicWhite,
            presentationStyle: .minimal,
            metadata: metadata,
            context: MetadataContext(),
            title: "同画布悬浮内容"
        )
        let optionalArtifact = try RecordCardPresentationPlanner()
            .floatingArtifact(
                for: card,
                canvasSize: CGSize(width: 400, height: 300)
            )
        let artifact = try #require(optionalArtifact)

        #expect(artifact.placement == .floating)
        #expect(artifact.canvasBackground == .transparent)
        #expect(artifact.canvasSize == CGSize(width: 400, height: 300))
        #expect(artifact.photoFrame == CGRect(x: 0, y: 0, width: 400, height: 300))
        #expect(artifact.layers.count == 1)
        let expectedLayerFrame = MinimalCardLayoutSpecification
            .floatingModuleFrame(
                imageWidth: 400,
                imageHeight: 300
            )
        #expect(artifact.layers[0].frame == expectedLayerFrame)
        #expect(artifact.layers[0].frame.width < artifact.photoFrame.width)
        #expect(artifact.layers[0].frame.height < artifact.photoFrame.height)
        #expect(artifact.layers[0].image.width == Int(expectedLayerFrame.width))
        #expect(artifact.layers[0].image.height == Int(expectedLayerFrame.height))
    }

    @Test("Minimal floating artifact remains encoder-safe for odd Live Photo still sizes")
    @MainActor
    func createsEncoderSafeFloatingArtifactForOddLivePhotoStillSize() throws {
        let metadata = PhotoMetadata(
            imageWidth: 401,
            imageHeight: 301
        )
        let card = RecordCard(
            template: .classicWhite,
            presentationStyle: .minimal,
            metadata: metadata,
            context: MetadataContext(),
            title: "奇数尺寸"
        )
        let optionalArtifact = try RecordCardPresentationPlanner()
            .floatingArtifact(
                for: card,
                canvasSize: CGSize(width: 401, height: 301)
            )
        let artifact = try #require(optionalArtifact)

        #expect(artifact.canvasSize == CGSize(width: 402, height: 302))
        #expect(artifact.photoFrame == CGRect(x: 0, y: 0, width: 402, height: 302))
        #expect(artifact.layers.count == 1)
        #expect(artifact.layers[0].frame.width < artifact.canvasSize.width)
        #expect(artifact.layers[0].frame.height < artifact.canvasSize.height)
        _ = try artifact.validatedForEncoder()
    }

}
