import CoreGraphics
import CoreText
import Foundation

struct FilmMarkResolvedLayout: Equatable {

    let anchor: FilmMarkPlacementAnchor
    let canvasSize: CGSize
    let frame: CGRect
    let substrateFrame: CGRect
    let effectBounds: CGRect
    let safeRect: CGRect
    let normalizedOffset: FilmMarkNormalizedOffset
    let isContentOverflowingSafeArea: Bool
}

/// Text measurement is layout input, not a renderer-owned policy. The fit
/// flag is kept beside the size so a constraint-sized partial result cannot be
/// mistaken for a valid complete layout.
struct FilmMarkTextMeasurement: Equatable {
    let size: CGSize
    let didFitEntireString: Bool
}

/// FilmMark owns its own geometry contract. Existing Classic White and
/// Minimal layout specifications deliberately do not use this type.
enum FilmMarkLayoutSpecification {

    static let normalizedNudgeStep: CGFloat = 0.005

    static func measure(
        text: String,
        canvasSize: CGSize,
        appearance: FilmMarkAppearanceDraft
    ) -> FilmMarkTextMeasurement {
        let pointSize = max(
            min(canvasSize.width, canvasSize.height)
                * appearance.fontSize.relativeToCanvasWidth,
            1
        )
        let font = CTFontCreateWithName(
            appearance.fontID.resolvedPostScriptName as CFString,
            pointSize,
            nil
        )
        let attributedText = NSAttributedString(
            string: text.isEmpty ? " " : text,
            attributes: [
                kCTFontAttributeName as NSAttributedString.Key: font
            ]
        )
        let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
        let constraint = CGSize(
            width: max(canvasSize.width * 0.92, 1),
            height: max(canvasSize.height * 0.40, pointSize)
        )
        var fitRange = CFRange()
        let suggested = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRange(location: 0, length: attributedText.length),
            nil,
            constraint,
            &fitRange
        )
        let didFitEntireString =
            fitRange.location == 0 && fitRange.length == attributedText.length
        let measuredSize = didFitEntireString ? suggested : constraint
        return FilmMarkTextMeasurement(
            size: CGSize(
                width: max(ceil(measuredSize.width), 1),
                height: max(ceil(measuredSize.height), ceil(pointSize * 1.25))
            ),
            didFitEntireString: didFitEntireString
        )
    }

    static func nudged(
        _ placement: FilmMarkPlacementDraft,
        direction: FilmMarkPlacementDirection
    ) -> FilmMarkPlacementDraft {
        let step = normalizedNudgeStep
        let xDelta: CGFloat
        let yDelta: CGFloat

        switch direction {
        case .up:
            xDelta = 0
            yDelta = -step
        case .down:
            xDelta = 0
            yDelta = step
        case .left:
            xDelta = -step
            yDelta = 0
        case .right:
            xDelta = step
            yDelta = 0
        }

        return FilmMarkPlacementDraft(
            anchor: placement.anchor,
            normalizedOffset: FilmMarkNormalizedOffset(
                x: placement.normalizedOffset.x + xDelta,
                y: placement.normalizedOffset.y + yDelta
            )
        )
    }

    /// Padding is part of FM layout, rather than a renderer-only background
    /// detail. This keeps the selected substrate from changing the apparent
    /// placement between the compact preview and exported artifacts.
    static func substratePadding(
        for appearance: FilmMarkAppearanceDraft,
        canvasSize: CGSize
    ) -> CGSize {
        guard appearance.substrate == .paperWhite
            || appearance.substrate == .systemGlass
        else {
            return .zero
        }

        let pointSize = max(
            min(canvasSize.width, canvasSize.height)
                * appearance.fontSize.relativeToCanvasWidth,
            1
        )
        return CGSize(
            width: ceil(pointSize * 0.42),
            height: ceil(pointSize * 0.28)
        )
    }

    static func resolve(
        canvasSize: CGSize,
        contentSize: CGSize,
        placement: FilmMarkPlacementDraft,
        appearance: FilmMarkAppearanceDraft = .init(),
        safeAreaInsets: FilmMarkNormalizedInsets = .default,
        didFitEntireString: Bool = true
    ) -> FilmMarkResolvedLayout {
        let canvasWidth = max(canvasSize.width, 0)
        let canvasHeight = max(canvasSize.height, 0)
        let canvas = CGRect(
            x: 0,
            y: 0,
            width: canvasWidth,
            height: canvasHeight
        )

        let safeRect = CGRect(
            x: canvas.minX + canvas.width * safeAreaInsets.left,
            y: canvas.minY + canvas.height * safeAreaInsets.top,
            width: max(
                canvas.width
                    * (1 - safeAreaInsets.left - safeAreaInsets.right),
                0
            ),
            height: max(
                canvas.height
                    * (1 - safeAreaInsets.top - safeAreaInsets.bottom),
                0
            )
        )

        let contentWidth = max(contentSize.width, 0)
        let contentHeight = max(contentSize.height, 0)
        let padding = substratePadding(
            for: appearance,
            canvasSize: CGSize(width: canvasWidth, height: canvasHeight)
        )
        let substrateWidth = contentWidth + padding.width * 2
        let substrateHeight = contentHeight + padding.height * 2
        let effectOutset: CGFloat = appearance.substrate == .softShadow
            ? 2
            : 0
        let placementRect: CGRect
        if effectOutset == 0 {
            placementRect = safeRect
        } else {
            placementRect = CGRect(
                x: safeRect.minX + effectOutset,
                y: safeRect.minY + effectOutset,
                width: max(safeRect.width - effectOutset * 2, 0),
                height: max(safeRect.height - effectOutset * 2, 0)
            )
        }
        let contentRect = CGRect(
            x: 0,
            y: 0,
            width: contentWidth,
            height: contentHeight
        )
        let contentWouldOverflow =
            !didFitEntireString || contentRect.width > placementRect.width
            || contentRect.height > placementRect.height
            || substrateWidth > placementRect.width
            || substrateHeight > placementRect.height

        let baseX: CGFloat
        switch placement.anchor {
        case .bottomLeft:
            baseX = placementRect.minX
        case .bottomRight:
            baseX = placementRect.maxX - substrateWidth
        }
        let baseY = placementRect.maxY - substrateHeight

        let desiredX = baseX
            + placement.normalizedOffset.x * canvas.width
        let desiredY = baseY
            + placement.normalizedOffset.y * canvas.height

        let maxX = max(placementRect.minX, placementRect.maxX - substrateWidth)
        let maxY = max(placementRect.minY, placementRect.maxY - substrateHeight)
        let resolvedSubstrateX = min(max(desiredX, placementRect.minX), maxX)
        let resolvedSubstrateY = min(max(desiredY, placementRect.minY), maxY)
        let substrateFrame = CGRect(
            x: resolvedSubstrateX,
            y: resolvedSubstrateY,
            width: substrateWidth,
            height: substrateHeight
        )
        let effectBounds = substrateFrame.insetBy(
            dx: -effectOutset,
            dy: -effectOutset
        )
        let overflowing = contentWouldOverflow
            || !safeRect.contains(effectBounds)
        let frame = CGRect(
            x: resolvedSubstrateX + padding.width,
            y: resolvedSubstrateY + padding.height,
            width: contentWidth,
            height: contentHeight
        )

        let resolvedOffset = FilmMarkNormalizedOffset(
            x: canvas.width > 0
                ? (resolvedSubstrateX - baseX) / canvas.width
                : 0,
            y: canvas.height > 0
                ? (resolvedSubstrateY - baseY) / canvas.height
                : 0
        )

        return FilmMarkResolvedLayout(
            anchor: placement.anchor,
            canvasSize: CGSize(width: canvasWidth, height: canvasHeight),
            frame: frame,
            substrateFrame: substrateFrame,
            effectBounds: effectBounds,
            safeRect: safeRect,
            normalizedOffset: resolvedOffset,
            isContentOverflowingSafeArea: overflowing
        )
    }
}

/// Converts the top-left preview coordinate domain into the bottom-left
/// coordinate domain used by Core Graphics-backed presentation artifacts.
/// This is the only owner of that conversion.
enum FilmMarkCoordinateBridge {

    static func artifactFrame(
        for frame: CGRect,
        canvasSize: CGSize
    ) -> CGRect {
        CGRect(
            x: frame.minX,
            y: canvasSize.height - frame.maxY,
            width: frame.width,
            height: frame.height
        )
    }

    static func artifactFrame(
        for resolvedLayout: FilmMarkResolvedLayout
    ) -> CGRect {
        artifactFrame(
            for: resolvedLayout.frame,
            canvasSize: resolvedLayout.canvasSize
        )
    }
}
