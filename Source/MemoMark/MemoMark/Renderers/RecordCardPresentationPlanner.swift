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

    /// Builds the renderer-neutral output artifact for the selected style.
    /// Each renderer owns its complete canvas geometry and layer pixels; the
    /// media pipeline must not reconstruct a footer by cropping a final image.
    @MainActor
    func artifact(
        for card: RecordCard,
        canvasSize: CGSize
    ) throws -> PresentationArtifact {
        switch card.presentationStyle {
        case .classicWhite:
            return try classicWhiteArtifact(
                for: card,
                canvasSize: canvasSize
            )
        case .minimal:
            return try minimalArtifact(
                for: card,
                canvasSize: canvasSize
            )
        }
    }

    /// Compatibility entry point for existing Minimal-focused callers. New
    /// output code should consume `artifact(for:canvasSize:)`.
    @MainActor
    func floatingArtifact(
        for card: RecordCard,
        canvasSize: CGSize
    ) throws -> PresentationArtifact? {
        guard card.presentationStyle == .minimal else {
            return nil
        }
        return try minimalArtifact(
            for: card,
            canvasSize: canvasSize
        )
    }

    @MainActor
    private func minimalArtifact(
        for card: RecordCard,
        canvasSize: CGSize
    ) throws -> PresentationArtifact {

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

    @MainActor
    private func classicWhiteArtifact(
        for card: RecordCard,
        canvasSize: CGSize
    ) throws -> PresentationArtifact {
        let outputSize = ClassicWhiteRenderer.outputPixelSize(
            for: card.metadata,
            fallbackSize: canvasSize
        )
        let sourceHeight = CGFloat(
            max(
                card.metadata.imageHeight
                ?? Int(canvasSize.height.rounded()),
                1
            )
        )
        let footerHeight = outputSize.height - sourceHeight
        guard footerHeight > 0 else {
            throw LivePhotoVideoCompositionError.invalidOverlayGeometry
        }

        let footer = ClassicWhiteInformationBarRenderer(
            card: card,
            width: outputSize.width,
            height: footerHeight
        )
        .frame(
            width: outputSize.width,
            height: footerHeight
        )
        let renderer = ImageRenderer(content: footer)
        renderer.scale = 1
        renderer.proposedSize = .init(
            width: outputSize.width,
            height: footerHeight
        )
        renderer.isOpaque = true

        guard let footerImage = renderer.cgImage else {
            throw RecordCardExportError.renderFailed
        }

        let footerFrame = CGRect(
            x: 0,
            y: 0,
            width: outputSize.width,
            height: footerHeight
        )
        let photoFrame = CGRect(
            x: 0,
            y: footerHeight,
            width: outputSize.width,
            height: sourceHeight
        )
        return try PresentationArtifact(
            canvasSize: outputSize,
            photoFrame: photoFrame,
            footerFrame: footerFrame,
            footerImage: footerImage,
            placement: .footer,
            canvasBackground: .opaqueWhite,
            layers: [
                .init(
                    frame: footerFrame,
                    image: footerImage,
                    zIndex: 100
                )
            ]
        )
    }
}
