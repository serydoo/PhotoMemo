import CoreGraphics
import CoreText
import Foundation

struct ClassicWhitePortraitResolvedLayout: Equatable {
    let leftTextOriginX: CGFloat
    let leftTextWidth: CGFloat
    let rightTextOriginX: CGFloat
    let rightTextWidth: CGFloat
    let logoSlotOriginX: CGFloat
    let dividerCenterX: CGFloat
    let leftToRightGroupGap: CGFloat
    let didConstrainLeftText: Bool
    let didConstrainRightText: Bool
}

/// Shared portrait information-bar geometry consumed by Classic White preview
/// and output. All horizontal values are normalized to the canvas width.
enum ClassicWhitePortraitLayoutSpecification {

    static let minimumCanvasEdgeInset: CGFloat = 0.045
    static let minimumGroupGap: CGFloat = 0.014

    static let maximumLeftTextWidth: CGFloat = 0.364
    static let maximumRightTextWidth: CGFloat = 0.406

    // Historical maximum-width reference columns, retained for compact
    // preview fallbacks and audit comparisons; resolved portrait layouts use
    // measured row widths below.
    static let leftTextOriginX: CGFloat = 0.062
    static let leftTextWidth: CGFloat = maximumLeftTextWidth
    static let leftGroupOffset: CGFloat = 0.017
    static let rightTextOriginX: CGFloat = 0.549
    static let rightTextWidth: CGFloat = maximumRightTextWidth

    static let historicalLogoCenterX: CGFloat = 0.4695
    static let historicalDividerCenterX: CGFloat = 0.5212
    static let logoCenterX: CGFloat = historicalLogoCenterX
    static let dividerCenterX: CGFloat = historicalDividerCenterX

    static let logoSlotWidth: CGFloat = 0.10
    static let logoToDividerSpacing: CGFloat = 0.015
    static let dividerToRightTextSpacing: CGFloat = 0.026
    static let dividerWidthToCanvasWidth: CGFloat = 0.1660 * 0.022

    /// Measures one single-line row in the same system family used by the
    /// Classic White text views. The caller supplies the resolved font size
    /// and tracking so the Layout Engine remains the owner of resulting width.
    static func measureTextWidth(
        _ text: String,
        fontSize: CGFloat,
        tracking: CGFloat,
        weight: CTFontSymbolicTraits = .traitBold
    ) -> CGFloat {
        let size = max(fontSize, 1)
        let baseFont = CTFontCreateUIFontForLanguage(
            .system,
            size,
            nil
        ) ?? CTFontCreateWithName("HelveticaNeue" as CFString, size, nil)
        let font = CTFontCreateCopyWithSymbolicTraits(
            baseFont,
            size,
            nil,
            weight,
            weight
        ) ?? baseFont
        let attributed = NSAttributedString(
            string: text.isEmpty ? " " : text,
            attributes: [
                kCTFontAttributeName as NSAttributedString.Key: font,
                kCTKernAttributeName as NSAttributedString.Key: tracking
            ]
        )
        let line = CTLineCreateWithAttributedString(attributed)
        let measured = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
        return max(measured, 1)
    }

    /// Resolves both measured text groups in one pass. The left context stays
    /// leading-aligned to its outer inset. The logo, divider, and right copy
    /// form a trailing-anchored cluster whose leading edge contracts or grows
    /// with the wider right-hand row. Existing line scaling/truncation remains
    /// responsible when measured copy exceeds the bounded text columns.
    static func resolve(
        leftRowWidths: [CGFloat],
        rightRowWidths: [CGFloat],
        dividerWidthRatio: CGFloat = dividerWidthToCanvasWidth
    ) -> ClassicWhitePortraitResolvedLayout {
        let measuredLeftWidth = max(leftRowWidths.max() ?? 0, 0)
        let measuredRightWidth = max(rightRowWidths.max() ?? 0, 0)
        let rightTextWidth = min(measuredRightWidth, maximumRightTextWidth)

        let rightTextOrigin = 1
            - minimumCanvasEdgeInset
            - rightTextWidth
        let dividerCenter = rightTextOrigin
            - dividerToRightTextSpacing
            - (dividerWidthRatio / 2)

        let logoSlotLeading = dividerCenter
            - (dividerWidthRatio / 2)
            - logoToDividerSpacing
            - logoSlotWidth
        let maximumLeftWidthForGap = max(
            logoSlotLeading
                - minimumGroupGap
                - minimumCanvasEdgeInset,
            0
        )
        let leftTextWidth = min(
            measuredLeftWidth,
            maximumLeftWidthForGap,
            maximumLeftTextWidth
        )

        return ClassicWhitePortraitResolvedLayout(
            leftTextOriginX: minimumCanvasEdgeInset,
            leftTextWidth: leftTextWidth,
            rightTextOriginX: rightTextOrigin,
            rightTextWidth: rightTextWidth,
            logoSlotOriginX: logoSlotLeading,
            dividerCenterX: dividerCenter,
            leftToRightGroupGap: logoSlotLeading
                - (minimumCanvasEdgeInset + leftTextWidth),
            didConstrainLeftText: measuredLeftWidth > leftTextWidth,
            didConstrainRightText: measuredRightWidth > rightTextWidth
        )
    }
}
