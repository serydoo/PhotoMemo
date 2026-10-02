#if !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// Shared native-material policy for preview and source-dependent output artifacts.
enum GlassCardProductionRenderer {
    static var usesNativeMaterial: Bool { NativeBackdropMaterialRenderer.isAvailable }
    static var recipe: GlassCardMaterialRecipe { usesNativeMaterial ? .foregroundOnly : .darkLayerV1 }
    static var secondaryTextOpacity: Double { usesNativeMaterial ? 0.96 : 0.78 }

    static func backdropMaterial(for plan: GlassCardResolvedPresentation) -> PresentationArtifact.BackdropMaterial {
        .init(frame: plan.artifactPanelFrame, renderFrame: plan.artifactOverlayFrame, cornerRadius: plan.panelCornerRadius)
    }

    static func outputPixelSize(for metadata: PhotoMetadata, fallbackSize: CGSize) -> CGSize {
        PresentationPixelGeometry.encoderSafeSize(CGSize(
            width: max(metadata.imageWidth.map(CGFloat.init) ?? fallbackSize.width, 1),
            height: max(metadata.imageHeight.map(CGFloat.init) ?? fallbackSize.height, 1)
        ))
    }

    static func resolve(card: RecordCard, canvasSize: CGSize) -> GlassCardResolvedPresentation {
        .resolve(content: GlassCardContentResolver.resolve(from: card), canvasSize: canvasSize)
    }
}

struct GlassCardCardRenderer: View {
    let image: Image
    let card: RecordCard

    var body: some View {
        GeometryReader { proxy in
            let canvasSize = GlassCardProductionRenderer.outputPixelSize(
                for: card.metadata, fallbackSize: proxy.size
            )
            let plan = GlassCardProductionRenderer.resolve(card: card, canvasSize: canvasSize)
            ZStack(alignment: .topLeading) {
                if GlassCardProductionRenderer.usesNativeMaterial {
                    NativeBackdropMaterialCanvas(image: image, canvasSize: canvasSize, material: GlassCardProductionRenderer.backdropMaterial(for: plan))
                } else {
                    image.resizable().scaledToFill().frame(width: canvasSize.width, height: canvasSize.height).clipped()
                }
                GlassCardOverlayLayer(presentation: plan, badge: card.badge)
            }
            .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
            .scaleEffect(proxy.size.width / canvasSize.width, anchor: .topLeading)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
    }
}

struct GlassCardOverlayLayer: View {
    let presentation: GlassCardResolvedPresentation
    let badge: Badge?

    let recipe: GlassCardMaterialRecipe
    let secondaryTextOpacity: Double

    init(
        presentation: GlassCardResolvedPresentation,
        badge: Badge?,
        recipe: GlassCardMaterialRecipe = GlassCardProductionRenderer.recipe,
        secondaryTextOpacity: Double = GlassCardProductionRenderer.secondaryTextOpacity
    ) {
        self.presentation = presentation
        self.badge = badge
        self.recipe = recipe
        self.secondaryTextOpacity = secondaryTextOpacity
    }

    var body: some View {
        let geometry = presentation.geometry
        let panel = geometry.panelFrame
        let shape = RoundedRectangle(
            cornerRadius: panel.height * GlassCardLayoutSpecification.layout.cornerRadiusToPanelHeight,
            style: .continuous
        )
        ZStack(alignment: .topLeading) {
            ZStack(alignment: .topLeading) {
                shape.fill(color(recipe.surface))
                    .overlay(shape.stroke(color(recipe.keyline), lineWidth: panel.height * recipe.keylineWidthToPanelHeight))
                    .shadow(color: color(recipe.shadow), radius: panel.height * recipe.shadowRadiusToPanelHeight,
                            y: panel.height * recipe.shadowOffsetToPanelHeight)
                ForEach(presentation.slots.indices, id: \.self) { index in
                    let slot = presentation.slots[index]
                    Text(slot.text)
                        .font(Font(GlassCardTextFitSpecification.font(
                            pointSize: slot.fit.pointSize, isPrimary: slot.isPrimary
                        )))
                        .foregroundStyle(Color.white.opacity(slot.isPrimary ? 0.96 : secondaryTextOpacity))
                        .lineLimit(1)
                        .frame(width: slot.frame.width, height: slot.frame.height, alignment: .leading)
                        .offset(x: slot.frame.minX, y: slot.frame.minY)
                }
                BadgeRenderer(
                    badge: ClassicWhiteRenderer.FrameInput.resolvedLogoBadge(from: badge),
                    systemSymbolTint: .white.opacity(0.96)
                ).render(size: geometry.badgeFrame.width)
                    .frame(width: geometry.badgeFrame.width, height: geometry.badgeFrame.height)
                    .offset(x: geometry.badgeFrame.minX, y: geometry.badgeFrame.minY)
                Rectangle().fill(Color.white.opacity(0.32))
                    .frame(width: geometry.dividerFrame.width, height: geometry.dividerFrame.height)
                    .offset(x: geometry.dividerFrame.minX, y: geometry.dividerFrame.minY)
            }
            .frame(width: panel.width, height: panel.height)
            .offset(x: panel.minX, y: panel.minY)
        }
        .frame(width: presentation.canvasSize.width, height: presentation.canvasSize.height, alignment: .topLeading)
    }

    private func color(_ value: GlassCardMaterialRecipe.RGBA) -> Color {
        Color(.sRGB, red: value.red, green: value.green, blue: value.blue, opacity: value.alpha)
    }
}
#endif
