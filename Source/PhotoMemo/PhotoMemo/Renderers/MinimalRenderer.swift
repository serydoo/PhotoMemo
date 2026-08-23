import SwiftUI

enum MinimalRenderer {

    typealias Orientation = MinimalCardLayoutSpecification.Orientation
    typealias Layout = MinimalCardLayoutSpecification.Layout

    static let outerSurface = Color.white
    static let capsuleSurface = Color(
        red: 250 / 255,
        green: 248 / 255,
        blue: 243 / 255
    )
    static let hairline = Color(
        red: 230 / 255,
        green: 226 / 255,
        blue: 218 / 255
    )
    static let foreground = Color(
        red: 29 / 255,
        green: 29 / 255,
        blue: 31 / 255
    )

    static func orientation(
        imageWidth: Int,
        imageHeight: Int
    ) -> Orientation {
        MinimalCardLayoutSpecification.orientation(
            imageWidth: imageWidth,
            imageHeight: imageHeight
        )
    }

    static func layout(for orientation: Orientation) -> Layout {
        MinimalCardLayoutSpecification.layout(for: orientation)
    }

    static func outputPixelSize(
        imageWidth: Int,
        imageHeight: Int
    ) -> CGSize {
        MinimalCardLayoutSpecification.outputPixelSize(
            imageWidth: imageWidth,
            imageHeight: imageHeight
        )
    }

    static func outputPixelSize(
        for metadata: PhotoMetadata,
        fallbackSize: CGSize
    ) -> CGSize {
        outputPixelSize(
            imageWidth:
                metadata.imageWidth
                ?? Int(fallbackSize.width),
            imageHeight:
                metadata.imageHeight
                ?? Int(fallbackSize.height)
        )
    }

    /// Resolves the single semantic value shown by Minimal's compact module.
    ///
    /// The Memory Engine's smart result is canonically carried by slot D
    /// (`rightBottom`). Older Minimal configurations may still put a custom
    /// value in slot A, so that value is retained as a compatibility fallback.
    /// Keeping the priority here makes preview, still export, and Live Photo
    /// overlay rendering consume the same semantic contract instead of each
    /// guessing a template area.
    static func informationText(for card: RecordCard) -> String {
        let blocks = CardTextBlockEngine().build(from: card)
        let priority: [CardTextArea] = [
            .rightBottom,
            .leftTop,
            .leftBottom,
            .rightTop
        ]

        for area in priority {
            if let value = blocks
                .first(where: { $0.area == area })?
                .value
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !value.isEmpty {
                return value
            }
        }

        return ""
    }
}

struct MinimalCardRenderer: View {

    let image: Image
    let card: RecordCard

    var body: some View {
        GeometryReader { geometry in
            let layout = MinimalRenderer.layout(for: orientation)
            let barHeight = CGFloat(
                MinimalCardLayoutSpecification.barHeightPixels(
                    imageWidth: max(Int(geometry.size.width.rounded()), 1),
                    imageHeight: max(Int(geometry.size.height.rounded()), 1)
                )
            )
            ZStack(alignment: .bottomTrailing) {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                MinimalInformationBar(
                    card: card,
                    width: geometry.size.width,
                    height: barHeight,
                    layout: layout
                )
                .padding(
                    .trailing,
                    geometry.size.width * (1 - layout.trailingAnchorX)
                )
                .padding(
                    .bottom,
                    geometry.size.width * layout.overlayBottomInsetToImageWidth
                )
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .clipped()
    }

    private var orientation: MinimalRenderer.Orientation {
        MinimalRenderer.orientation(
            imageWidth: max(card.metadata.imageWidth ?? 1, 1),
            imageHeight: max(card.metadata.imageHeight ?? 1, 1)
        )
    }

}

/// Transparent bounded layer used by static and Live Photo composition. The
/// source image is supplied by the media composer; this view contributes only
/// the floating capsule pixels at the layer's local bottom-trailing edge.
struct MinimalCardOverlayLayerRenderer: View {

    let card: RecordCard
    let canvasWidth: CGFloat
    let layerHeight: CGFloat

    var body: some View {
        let layout = MinimalRenderer.layout(for: orientation)

        ZStack(alignment: .bottomTrailing) {
            Color.clear

            MinimalInformationBar(
                card: card,
                width: canvasWidth,
                height: layerHeight,
                layout: layout
            )
        }
        .clipped()
    }

    private var orientation: MinimalRenderer.Orientation {
        MinimalRenderer.orientation(
            imageWidth: max(card.metadata.imageWidth ?? 1, 1),
            imageHeight: max(card.metadata.imageHeight ?? 1, 1)
        )
    }
}

private struct MinimalInformationBar: View {

    let card: RecordCard
    let width: CGFloat
    let height: CGFloat
    let layout: MinimalRenderer.Layout

    var body: some View {
        let capsuleHeight =
            height * layout.capsuleHeightToBarHeight
        let avatarSize = min(
            height * layout.avatarSizeToBarHeight,
            capsuleHeight
        )

        return HStack(
            spacing: height * layout.avatarTextSpacingToBarHeight
        ) {
            BadgeRenderer(
                badge:
                    ClassicWhiteRenderer.FrameInput
                    .resolvedLogoBadge(from: card.badge),
                systemSymbolTint: MinimalRenderer.foreground
            )
            .render(
                size:
                    avatarSize
            )
            .opacity(0.94)
            .frame(
                width:
                    height
                    * layout.avatarAreaWidthToBarHeight,
                height: capsuleHeight,
                alignment: .leading
            )

            Text(outputText.isEmpty ? " " : outputText)
                .font(
                    .system(
                        size:
                            height
                            * layout.textSizeToBarHeight,
                        weight: .medium
                    )
                )
                .monospacedDigit()
                .foregroundStyle(MinimalRenderer.foreground)
                .lineLimit(layout.textLineLimit)
                .multilineTextAlignment(.leading)
                .allowsTightening(true)
                .minimumScaleFactor(0.78)
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding(
            .trailing,
            height * layout.capsuleHorizontalPaddingToBarHeight
        )
        .padding(
            .leading,
            height * layout.avatarLeadingInsetToBarHeight
        )
        .padding(
            .vertical,
            height * layout.capsuleVerticalPaddingToBarHeight
        )
        .background {
            RoundedRectangle(
                cornerRadius: capsuleHeight / 2,
                style: .continuous
            )
            .fill(MinimalRenderer.capsuleSurface)
            .overlay {
                RoundedRectangle(
                    cornerRadius: capsuleHeight / 2,
                    style: .continuous
                )
                .stroke(
                    MinimalRenderer.hairline,
                    lineWidth: max(1, height * 0.006)
                )
            }
        }
        .frame(
            maxWidth: width * layout.maximumModuleWidth,
            minHeight: capsuleHeight,
            alignment: .trailing
        )
    }

    private var outputText: String {
        MinimalRenderer.informationText(for: card)
    }
}
