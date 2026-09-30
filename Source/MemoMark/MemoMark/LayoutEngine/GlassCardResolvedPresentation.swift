import CoreGraphics

/// A single resolved plan consumed by preview and output drawing.
struct GlassCardResolvedPresentation {
    struct TextSlot {
        let text: String
        let frame: CGRect
        let isPrimary: Bool
        let fit: GlassCardTextFitSpecification.Result
    }

    let canvasSize: CGSize
    let geometry: GlassCardLayoutSpecification.ResolvedGeometry
    let slots: [TextSlot]

    /// Restrict the output bitmap to the rail and its shadow, not a whole photo.
    var overlayFrame: CGRect {
        let recipe = GlassCardMaterialRecipe.darkLayerV1
        let panel = geometry.panelFrame
        let shadowMargin = panel.height * recipe.shadowRadiusToPanelHeight * 3
        let top = max(panel.minY - shadowMargin, 0).rounded(.down)
        return CGRect(x: 0, y: top, width: canvasSize.width, height: canvasSize.height - top)
    }
    /// Existing still/motion artifacts use a bottom-left origin.
    var artifactOverlayFrame: CGRect {
        let frame = overlayFrame
        return CGRect(x: frame.minX, y: canvasSize.height - frame.maxY, width: frame.width, height: frame.height)
    }

    let isEmpty: Bool

    var isContentOverflowing: Bool {
        slots.contains { $0.fit.outcome == .overflow }
    }

    static func resolve(
        content: GlassCardContentProjection,
        canvasSize: CGSize
    ) -> Self {
        let geometry = GlassCardLayoutSpecification.resolvedGeometry(canvasSize: canvasSize)
        let layout = GlassCardLayoutSpecification.layout
        let values: [(String, CGRect, Bool)] = [
            (content.leftTop, geometry.leftTopFrame, true),
            (content.leftBottom, geometry.leftBottomFrame, false),
            (content.rightTop, geometry.rightTopFrame, true),
            (content.rightBottom, geometry.rightBottomFrame, false)
        ]
        return Self(
            canvasSize: canvasSize,
            geometry: geometry,
            slots: values.map { text, frame, primary in
                let ratio = primary ? layout.primaryFontToPanelHeight : layout.secondaryFontToPanelHeight
                return TextSlot(
                    text: text, frame: frame, isPrimary: primary,
                    fit: GlassCardTextFitSpecification.resolve(
                        text: text, frame: frame.size,
                        pointSize: geometry.panelFrame.height * ratio * (primary ? 1.12 : 1.04),
                        isPrimary: primary, lineLimit: 1,
                        minimumScale: primary ? 0.72 : 0.70
                    )
                )
            },
            isEmpty: content.isEmpty
        )
    }
}
