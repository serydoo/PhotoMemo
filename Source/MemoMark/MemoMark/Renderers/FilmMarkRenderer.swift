import CoreGraphics
import CoreText
import SwiftUI

/// Provisional FM renderer adapter. It consumes a resolved presentation and
/// does not own content composition, coordinate conversion, or export.
enum FilmMarkRenderer {

    static func outputPixelSize(
        for card: RecordCard,
        fallbackSize: CGSize
    ) -> CGSize {
        CGSize(
            width: max(card.metadata.imageWidth.map(CGFloat.init) ?? fallbackSize.width, 1),
            height: max(card.metadata.imageHeight.map(CGFloat.init) ?? fallbackSize.height, 1)
        )
    }

    fileprivate static func swiftUIFont(
        for fontID: FilmMarkFontID,
        pointSize: CGFloat
    ) -> Font {
        // Menlo is the verified system monospaced face used by the CoreText
        // measurement path below. Keeping both paths on the same face avoids
        // a preview/export frame mismatch while custom assets remain
        // unverified.
        return .custom(
            fontID.resolvedPostScriptName,
            fixedSize: max(pointSize, 1)
        )
    }

    fileprivate static func color(
        from value: FilmMarkRGBAColor
    ) -> Color {
        Color(
            red: value.red,
            green: value.green,
            blue: value.blue,
            opacity: value.alpha
        )
    }

    fileprivate static func cgColor(
        from value: FilmMarkRGBAColor
    ) -> CGColor {
        CGColor(
            red: value.red,
            green: value.green,
            blue: value.blue,
            alpha: value.alpha
        )
    }

}

struct FilmMarkCardRenderer: View {

    let image: Image
    let presentation: FilmMarkResolvedPresentation

    private var canvasAspectRatio: CGFloat {
        let width = max(presentation.canvasSize.width, 1)
        let height = max(presentation.canvasSize.height, 1)
        return width / height
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipped()
                FilmMarkTextLayer(
                    presentation: presentation,
                    displaySize: geometry.size
                )
            }
        }
        // FM has one placement system for every source orientation, but it
        // must still preserve the source aspect ratio in preview.
        .aspectRatio(canvasAspectRatio, contentMode: .fit)
        .clipped()
    }
}

/// Transparent full-canvas layer used by the still and Live Photo artifact
/// adapters. Its frame is the resolved canvas, so no media pipeline branch is
/// needed for FM.
struct FilmMarkCardOverlayLayerRenderer: View {

    let presentation: FilmMarkResolvedPresentation

    var body: some View {
        FilmMarkTextLayer(
            presentation: presentation,
            displaySize: presentation.canvasSize
        )
        .frame(
            width: presentation.canvasSize.width,
            height: presentation.canvasSize.height,
            alignment: .topLeading
        )
        .background(Color.clear)
    }
}

struct FilmMarkTextLayer: View {
    let presentation: FilmMarkResolvedPresentation
    let displaySize: CGSize

    var body: some View {
        if let image = try? FilmMarkRasterRenderer.render(
            presentation: presentation
        ) {
            Image(decorative: image, scale: 1)
                .resizable()
                .interpolation(.high)
                .frame(
                    width: max(displaySize.width, 1),
                    height: max(displaySize.height, 1),
                    alignment: .topLeading
                )
        }
    }
}

enum FilmMarkRasterizationError: Error, Equatable {
    case invalidCanvas
    case colorSpaceUnavailable
    case contextUnavailable
    case fontUnavailable
    case textOverflow
    case imageUnavailable
}

/// Rasterizes the resolved FM artifact with the same CoreText face and frame
/// that the Layout Engine measured. This is the shared preview/still/motion
/// drawing adapter; it intentionally receives no authored or layout choices.
enum FilmMarkRasterRenderer {

    static func render(
        presentation: FilmMarkResolvedPresentation,
        contextFactory: ((Int, Int, CGColorSpace) -> CGContext?)? = nil
    ) throws -> CGImage {
        let canvasWidth = Int(ceil(presentation.canvasSize.width))
        let canvasHeight = Int(ceil(presentation.canvasSize.height))
        guard canvasWidth > 0, canvasHeight > 0 else {
            throw FilmMarkRasterizationError.invalidCanvas
        }

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            throw FilmMarkRasterizationError.colorSpaceUnavailable
        }

        let context: CGContext?
        if let contextFactory {
            context = contextFactory(
                canvasWidth,
                canvasHeight,
                colorSpace
            )
        } else {
            context = CGContext(
                data: nil,
                width: canvasWidth,
                height: canvasHeight,
                bitsPerComponent: 8,
                bytesPerRow: canvasWidth * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        }
        guard let context else {
            throw FilmMarkRasterizationError.contextUnavailable
        }

        let layout = presentation.layout
        let pointSize = presentation.typography.pointSize
        let cornerRadius = min(max(pointSize * 0.24, 4), 18)

        context.saveGState()
        drawSubstrate(
            in: context,
            presentation: presentation,
            rect: layout.substrateFrame,
            cornerRadius: cornerRadius
        )
        context.restoreGState()

        guard !presentation.content.primaryOutput.isEmpty else {
            guard let image = context.makeImage() else {
                throw FilmMarkRasterizationError.imageUnavailable
            }
            return image
        }

        let font = CTFontCreateWithName(
            presentation.appearance.fontID.resolvedPostScriptName as CFString,
            pointSize,
            nil
        )
        guard CTFontGetGlyphCount(font) > 0 else {
            throw FilmMarkRasterizationError.fontUnavailable
        }
        let attributedText = NSAttributedString(
            string: presentation.content.primaryOutput,
            attributes: [
                kCTFontAttributeName as NSAttributedString.Key: font,
                kCTForegroundColorAttributeName as NSAttributedString.Key:
                    FilmMarkRenderer.cgColor(
                        from: presentation.appearance.color
                    )
            ]
        )
        let framesetter = CTFramesetterCreateWithAttributedString(
            attributedText
        )
        let textFrame = layout.frame
        let textPath = CGPath(
            rect: FilmMarkCoordinateBridge.artifactFrame(
                for: textFrame,
                canvasSize: presentation.canvasSize
            ),
            transform: nil
        )
        let frame = CTFramesetterCreateFrame(
            framesetter,
            CFRange(location: 0, length: attributedText.length),
            textPath,
            nil
        )
        guard CTFrameGetVisibleStringRange(frame).length
            == attributedText.length else {
            throw FilmMarkRasterizationError.textOverflow
        }
        if presentation.appearance.substrate == .softShadow {
            context.setShadow(
                offset: CGSize(width: 0, height: -1.5),
                blur: 3.5,
                color: CGColor(
                    red: 0,
                    green: 0,
                    blue: 0,
                    alpha: 0.72
                )
            )
        }
        CTFrameDraw(frame, context)
        guard let image = context.makeImage() else {
            throw FilmMarkRasterizationError.imageUnavailable
        }
        return image
    }

    private static func drawSubstrate(
        in context: CGContext,
        presentation: FilmMarkResolvedPresentation,
        rect: CGRect,
        cornerRadius: CGFloat
    ) {
        let drawRect = FilmMarkCoordinateBridge.artifactFrame(
            for: rect,
            canvasSize: presentation.canvasSize
        )
        let path = CGPath(
            roundedRect: drawRect,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )

        switch presentation.appearance.substrate {
        case .none, .softShadow:
            break
        case .translucentLabel:
            context.addPath(path)
            context.setFillColor(
                CGColor(red: 0, green: 0, blue: 0, alpha: 0.24)
            )
            context.fillPath()
        case .paperWhite:
            context.addPath(path)
            context.setFillColor(
                CGColor(red: 1, green: 1, blue: 1, alpha: 1)
            )
            context.fillPath()
        case .systemGlass:
            context.addPath(path)
            context.setFillColor(
                CGColor(red: 1, green: 1, blue: 1, alpha: 0.22)
            )
            context.fillPath()
            context.addPath(path)
            context.setStrokeColor(
                CGColor(red: 1, green: 1, blue: 1, alpha: 0.72)
            )
            context.setLineWidth(1)
            context.strokePath()
        }

        if presentation.appearance.substrate == .softShadow {
            context.saveGState()
            context.addPath(path)
            context.setShadow(
                offset: CGSize(width: 0, height: -1.5),
                blur: 3.5,
                color: CGColor(
                    red: 0,
                    green: 0,
                    blue: 0,
                    alpha: 0.72
                )
            )
            context.setFillColor(CGColor(gray: 1, alpha: 0.001))
            context.fillPath()
            context.restoreGState()
        }
    }

}
