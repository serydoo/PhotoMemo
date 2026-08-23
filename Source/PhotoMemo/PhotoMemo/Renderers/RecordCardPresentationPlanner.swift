import SwiftUI
import CoreGraphics

/// Single registration point between a presentation style and its visual
/// renderer. Export and media services consume the returned plan without
/// branching on a concrete renderer.
struct RecordCardPresentationPlanner {

    func outputPixelSize(
        for card: RecordCard,
        fallbackSize: CGSize
    ) -> CGSize {
        switch card.presentationStyle {
        case .classicWhite:
            ClassicWhiteRenderer.outputPixelSize(
                for: card.metadata,
                fallbackSize: fallbackSize
            )
        case .minimal:
            MinimalRenderer.outputPixelSize(
                for: card.metadata,
                fallbackSize: fallbackSize
            )
        }
    }

    func content(
        for card: RecordCard,
        image: Image
    ) -> AnyView {
        switch card.presentationStyle {
        case .classicWhite:
            AnyView(ClassicWhiteCardRenderer(image: image, card: card))
        case .minimal:
            AnyView(MinimalCardRenderer(image: image, card: card))
        }
    }

    /// Builds the renderer-neutral overlay artifact for styles that compose
    /// inside the source photo canvas. Classic White continues through its
    /// established appended-area export path until its own artifact planner
    /// is migrated.
    @MainActor
    func floatingArtifact(
        for card: RecordCard,
        canvasSize: CGSize
    ) throws -> PresentationArtifact? {
        guard card.presentationStyle == .minimal else {
            return nil
        }

        let geometry = MinimalCardLayoutSpecification.outputGeometry(
            imageWidth: max(Int(ceil(canvasSize.width)), 1),
            imageHeight: max(Int(ceil(canvasSize.height)), 1)
        )
        let layerFrame = MinimalCardLayoutSpecification.floatingModuleFrame(
            imageWidth: max(Int(ceil(canvasSize.width)), 1),
            imageHeight: max(Int(ceil(canvasSize.height)), 1)
        )
        let overlay = MinimalCardOverlayLayerRenderer(
            card: card,
            canvasWidth: geometry.canvasSize.width,
            layerHeight: layerFrame.height
        )
        .frame(
            width: layerFrame.width,
            height: layerFrame.height,
            alignment: .bottomTrailing
        )
        let renderer = ImageRenderer(content: overlay)
        renderer.scale = 1
        renderer.proposedSize = .init(layerFrame.size)
        renderer.isOpaque = false

        guard let overlayImage = renderer.cgImage else {
            throw RecordCardExportError.renderFailed
        }

        let fullFrame = CGRect(origin: .zero, size: geometry.canvasSize)
        return try PresentationArtifact(
            canvasSize: geometry.canvasSize,
            photoFrame: fullFrame,
            footerFrame: layerFrame,
            footerImage: overlayImage,
            placement: .floating,
            canvasBackground: .transparent,
            layers: [
                .init(frame: layerFrame, image: overlayImage, zIndex: 100)
            ]
        )
    }
}
