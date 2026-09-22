import SwiftUI

/// A view-only calibration mode. It deliberately does not belong to the
/// durable FilmMark configuration, because it changes how a person inspects
/// the same resolved output rather than the output itself.
enum FilmMarkPreviewMode: Equatable {
    /// A readable lower-photo detail shared with the compact preview height of
    /// Classic White and Minimal. This is a content reading aid, not a 1:1
    /// position or size calibration surface.
    case contentStrip

    /// The full photo-relative coordinate canvas used while the related
    /// geometry controls are open. The viewport shows its lower photo region
    /// so the calibration surface remains usable in landscape.
    case geometry
}

/// Presentation-only geometry for the FM calibration viewport.
///
/// The Layout Engine still resolves the complete photo canvas. These values
/// only decide how much of that canvas the Configuration Center reveals while
/// the position and size controls are open; they must never enter rendering,
/// export, or durable FilmMark configuration.
enum FilmMarkPreviewGeometrySpec {

    static let canvasSize = CGSize(width: 1_200, height: 675)

    /// Never reveal more than the lower half of the sample photograph. The
    /// inner canvas remains bottom-aligned, so the upper half is clipped
    /// without changing the text's photo-relative coordinate system.
    static let maximumVisibleImageHeightFraction: CGFloat = 0.50

    /// Landscape configuration needs to leave room for the editor and its
    /// bottom save action. This is intentionally a viewport height, not a
    /// renderer or output-canvas dimension.
    static let calibrationViewportHeight: CGFloat = 150

    static func cropHeight(
        canvasHeight: CGFloat,
        availableHeight: CGFloat
    ) -> CGFloat {
        min(
            max(availableHeight, 0),
            max(canvasHeight, 0) * maximumVisibleImageHeightFraction
        )
    }
}

/// Maps the durable, continuous FM type-size ratio to the compact preview.
/// This is preview-only typography: the resolved layout used for calibration
/// and export remains owned by the Layout Engine.
enum FilmMarkPreviewTypography {
    static func compactContentFontSize(
        for fontSize: FilmMarkFontSize,
        height: CGFloat
    ) -> CGFloat {
        let position = FilmMarkFontSize.sliderPosition(for: fontSize)
        let sizeFactor: CGFloat

        // The slider midpoint deliberately preserves the former prominent
        // visual size. Values on either side remain continuous, so a custom
        // stored ratio never falls back to the old four-step presentation.
        if position <= 0.5 {
            sizeFactor = 0.26 + (0.41 - 0.26) * (position / 0.5)
        } else {
            sizeFactor = 0.41 + (0.48 - 0.41) * ((position - 0.5) / 0.5)
        }

        return min(max(height * sizeFactor, 11), 20)
    }
}

/// A calibration view for the authored FilmMark presentation.
///
/// The content strip keeps the three presentation styles comparable at the
/// Configuration Center's compact preview height. Opening “位置与字号” changes
/// only this view's inspection mode; it continues to resolve the same FM
/// content and configuration that preview/export share.
struct FilmMarkPreviewSurface: View {

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    let content: FilmMarkContentProjection
    let configuration: FilmMarkConfiguration
    var mode: FilmMarkPreviewMode = .contentStrip

    /// The background asset is 1600×900, while this virtual layout canvas is
    /// deliberately smaller. Its ratio is the truth the Layout Engine needs;
    /// rendering more pixels would only add transient raster work on every
    /// nudge or size change in the Configuration Center.
    private var geometryCanvasSize: CGSize {
        FilmMarkPreviewGeometrySpec.canvasSize
    }

    var body: some View {
        Group {
            switch mode {
            case .contentStrip:
                contentStrip
            case .geometry:
                geometryCalibration
            }
        }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.2),
            value: mode
        )
    }

    private var contentStrip: some View {
        GeometryReader { geometry in
            ZStack(alignment: compactContentAlignment) {
                previewBackground(
                    width: geometry.size.width,
                    height: geometry.size.height
                )

                if content.primaryOutput.isEmpty {
                    emptyContentLabel
                } else {
                    contentStripLabel(height: geometry.size.height)
                        .padding(
                            .horizontal,
                            max(10, geometry.size.width * 0.04)
                        )
                        .padding(
                            .vertical,
                            max(5, geometry.size.height * 0.12)
                        )
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .clipped()
        }
        .aspectRatio(
            1 / RendererConstants.CompactInformationBar.landscape
                .barHeightToWidth,
            contentMode: .fit
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            filmMarkLocalized(
                "filmMark.preview.content.accessibility",
                fallback: "FilmMark 文字内容预览"
            )
        )
        .accessibilityValue(content.primaryOutput)
    }

    private var geometryCalibration: some View {
        let presentation = FilmMarkPresentationResolver.resolve(
            content: content,
            configuration: configuration,
            canvasSize: geometryCanvasSize
        )

        return VStack(alignment: .leading, spacing: 6) {
            Text(
                filmMarkLocalized(
                    "filmMark.preview.geometry_note",
                    fallback: "位置与字号校准示意，实际输出会根据照片比例自适应。"
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isStaticText)

            GeometryReader { geometry in
                let canvasSize = CGSize(
                    width: geometry.size.width,
                    height: geometry.size.width
                        * geometryCanvasSize.height
                        / geometryCanvasSize.width
                )
                let cropHeight = min(
                    FilmMarkPreviewGeometrySpec.cropHeight(
                        canvasHeight: canvasSize.height,
                        availableHeight: geometry.size.height
                    ),
                    canvasSize.height
                )

                // Keep the wide canvas geometry intact, but present no more
                // than its lower half at the top of the inspector. This
                // preserves the bottom-aligned placement guide while keeping
                // the controls and save action visible in landscape.
                ZStack(alignment: .topLeading) {
                    previewBackground(
                        width: canvasSize.width,
                        height: canvasSize.height
                    )
                    FilmMarkTextLayer(
                        presentation: presentation,
                        displaySize: canvasSize
                    )
                    FilmMarkPreviewPlacementGuide(
                        layout: presentation.layout,
                        displaySize: canvasSize
                    )
                    if presentation.content.primaryOutput.isEmpty {
                        emptyContentLabel
                            .frame(
                                width: canvasSize.width,
                                height: canvasSize.height,
                                alignment: .center
                            )
                    }
                }
                .frame(
                    width: canvasSize.width,
                    height: cropHeight,
                    alignment: .bottom
                )
                .clipped()
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height,
                    alignment: .top
                )
            }
            .frame(
                height: FilmMarkPreviewGeometrySpec
                    .calibrationViewportHeight
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            filmMarkLocalized(
                "filmMark.preview.geometry.accessibility",
                fallback: "FilmMark 位置与字号完整预览"
            )
        )
        .accessibilityValue(content.primaryOutput)
    }

    private var compactContentAlignment: Alignment {
        switch configuration.placement.anchor {
        case .bottomLeft:
            .bottomLeading
        case .bottomRight:
            .bottomTrailing
        }
    }

    private func previewBackground(
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        Image(
            ConfigurationPreviewBackground.filmMark.assetName(
                for: ConfigurationPreviewBackground.surface(
                    forPreviewWidth: width
                )
            )
        )
            .resizable()
            .scaledToFill()
            .frame(
                width: max(width, 1),
                height: max(height, 1),
                alignment: .bottom
            )
            .overlay {
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.06),
                        Color.black.opacity(0.28)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipped()
            .accessibilityHidden(true)
    }

    private func contentStripLabel(height: CGFloat) -> some View {
        Text(content.primaryOutput)
            .font(
                .system(
                    size: compactContentFontSize(for: height),
                    weight: .medium,
                    design: .monospaced
                )
            )
            .foregroundStyle(filmMarkColor)
            .lineLimit(1)
            .minimumScaleFactor(0.70)
            .allowsTightening(true)
            .padding(
                .horizontal,
                max(7, height * 0.28)
            )
            .padding(
                .vertical,
                max(4, height * 0.13)
            )
            .background {
                compactSubstrate
            }
            .shadow(
                color: configuration.appearance.substrate == .softShadow
                    ? .black.opacity(0.72)
                    : .clear,
                radius: 3.5,
                y: 1.5
            )
    }

    private var compactSubstrate: some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
        return Group {
            switch configuration.appearance.substrate {
            case .none, .softShadow:
                Color.clear
            case .paperWhite:
                shape.fill(Color.white.opacity(0.94))
            case .systemGlass:
                shape
                    .fill(Color.white.opacity(0.26))
                    .overlay {
                        shape.stroke(Color.white.opacity(0.54))
                    }
            case .translucentLabel:
                shape.fill(Color.black.opacity(0.26))
            }
        }
    }

    private var emptyContentLabel: some View {
        Text(
            filmMarkLocalized(
                "filmMark.preview.empty",
                fallback: "暂无胶片内容"
            )
        )
        .font(.caption.weight(.medium))
        .foregroundStyle(.white.opacity(0.90))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.black.opacity(0.30), in: Capsule())
        .allowsHitTesting(false)
    }

    private var filmMarkColor: Color {
        Color(
            red: configuration.appearance.color.red,
            green: configuration.appearance.color.green,
            blue: configuration.appearance.color.blue,
            opacity: configuration.appearance.color.alpha
        )
    }

    private func compactContentFontSize(for height: CGFloat) -> CGFloat {
        FilmMarkPreviewTypography.compactContentFontSize(
            for: configuration.appearance.fontSize,
            height: height
        )
    }
}

private struct FilmMarkPreviewPlacementGuide: View {

    let layout: FilmMarkResolvedLayout
    let displaySize: CGSize

    var body: some View {
        let safeFrame = scaled(layout.safeRect)

        RoundedRectangle(
            cornerRadius: max(8, displaySize.height * 0.04),
            style: .continuous
        )
        .stroke(
            Color.white.opacity(0.32),
            style: StrokeStyle(lineWidth: 1, dash: [5, 5])
        )
        .frame(width: safeFrame.width, height: safeFrame.height)
        .position(x: safeFrame.midX, y: safeFrame.midY)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func scaled(_ frame: CGRect) -> CGRect {
        guard layout.canvasSize.width > 0, layout.canvasSize.height > 0 else {
            return .zero
        }
        return CGRect(
            x: frame.minX / layout.canvasSize.width * displaySize.width,
            y: frame.minY / layout.canvasSize.height * displaySize.height,
            width: frame.width / layout.canvasSize.width * displaySize.width,
            height: frame.height / layout.canvasSize.height * displaySize.height
        )
    }
}
