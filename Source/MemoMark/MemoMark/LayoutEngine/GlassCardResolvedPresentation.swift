import CoreGraphics
import Foundation

/// A single resolved plan consumed by preview and output drawing.
struct GlassCardResolvedPresentation {
    struct TextSlot {
        let text: String
        let frame: CGRect
        let isPrimary: Bool
        let lineLimit: Int
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

    var artifactPanelFrame: CGRect {
        let panel = geometry.panelFrame
        return CGRect(x: panel.minX, y: canvasSize.height - panel.maxY, width: panel.width, height: panel.height)
    }

    var panelCornerRadius: CGFloat {
        geometry.panelFrame.height * GlassCardLayoutSpecification.layout.cornerRadiusToPanelHeight
    }

    let isEmpty: Bool

    var isContentOverflowing: Bool {
        slots.contains { $0.fit.outcome == .overflow }
    }

    static func resolve(
        content: GlassCardContentProjection,
        canvasSize: CGSize,
        primaryFontMultiplier: CGFloat = 1.12,
        secondaryFontMultiplier: CGFloat = 1.04,
        lineLimit: Int = 1,
        permitsExplicitSecondaryLines: Bool = false
    ) -> Self {
        let layout = GlassCardLayoutSpecification.layout
        let panel = GlassCardLayoutSpecification.panelFrame(canvasSize: canvasSize)
        func preferredFontSize(primary: Bool) -> CGFloat {
            panel.height * (primary ? layout.primaryFontToPanelHeight * primaryFontMultiplier
                : layout.secondaryFontToPanelHeight * secondaryFontMultiplier)
        }
        let preferredRightWidth = max(
            GlassCardTextFitSpecification.preferredWidth(text: content.rightTop,
                pointSize: preferredFontSize(primary: true), isPrimary: true),
            GlassCardTextFitSpecification.preferredWidth(text: content.rightBottom,
                pointSize: preferredFontSize(primary: false), isPrimary: false)
        )
        let geometry = GlassCardLayoutSpecification.resolvedGeometry(canvasSize: canvasSize,
            preferredRightColumnWidth: preferredRightWidth)
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
                let wrapsSupplement = permitsExplicitSecondaryLines && !primary
                    && text.rangeOfCharacter(from: .newlines) != nil
                let resolvedLineLimit = wrapsSupplement ? max(lineLimit, 2) : lineLimit
                // Secondary rows have room below their existing top edge. Grow
                // only the explicit two-line slot, without crossing the primary
                // row or the rail's bottom padding. Scaling stays bounded.
                let resolvedFrame = wrapsSupplement
                    ? CGRect(x: frame.minX, y: frame.minY, width: frame.width,
                        height: min(frame.height * 1.5, panel.maxY - panel.height * 0.07 - frame.minY))
                    : frame
                return TextSlot(
                    text: text, frame: resolvedFrame, isPrimary: primary, lineLimit: resolvedLineLimit,
                    fit: GlassCardTextFitSpecification.resolve(
                        text: text, frame: resolvedFrame.size,
                        pointSize: preferredFontSize(primary: primary),
                        isPrimary: primary, lineLimit: resolvedLineLimit,
                        minimumScale: primary ? 0.72 : 0.70
                    )
                )
            },
            isEmpty: content.isEmpty
        )
    }
}
