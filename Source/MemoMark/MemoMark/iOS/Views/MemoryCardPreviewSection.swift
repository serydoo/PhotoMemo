#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct MemoryCardPreviewSection: View {

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @AppStorage(ConfigurationPreviewPreferenceKey.orientation)
    private var storedOrientation = ConfigurationPreviewBackground.Orientation.landscape.rawValue

    /// Expansion is an inspection gesture, not a preference. It should return
    /// to the compact preview when this surface is recreated or reopened.
    @State
    private var isExpanded = false

    let presentationStyle: RecordCardPresentationStyle
    let logoMode: ConfigurationLogoMode
    let customLogoImagePath: String?
    let subjectAvatarLogoImagePath: String?
    let regionText: String
    let timeText: String
    let contextText: String
    let memoryText: String
    let filmMarkOutputText: String
    let filmMarkConfiguration: FilmMarkConfiguration
    let isFilmMarkGeometryExpanded: Bool
    let onTap: (() -> Void)?

    private var orientation: ConfigurationPreviewBackground.Orientation {
        ConfigurationPreviewBackground.Orientation(rawValue: storedOrientation)
            ?? .landscape
    }

    private var alternateOrientation: ConfigurationPreviewBackground.Orientation {
        orientation == .landscape ? .portrait : .landscape
    }

    private var orientationAccessibilityValue: String {
        filmMarkLocalized(
            orientation == .landscape
                ? "configuration.preview.orientation.landscape"
                : "configuration.preview.orientation.portrait",
            fallback: orientation == .landscape ? "横图" : "竖图"
        )
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let activeCanvasAspectRatio = ConfigurationPreviewViewportSpec.canvasAspectRatio(
                for: presentationStyle,
                orientation: orientation
            )
            let alternateCanvasAspectRatio = ConfigurationPreviewViewportSpec.canvasAspectRatio(
                for: presentationStyle,
                orientation: alternateOrientation
            )
            let viewportAspectRatio = ConfigurationPreviewViewportSpec.viewportAspectRatio(
                canvasAspectRatio: activeCanvasAspectRatio,
                for: orientation,
                isExpanded: isExpanded
            )
            let viewportHeight = width
                / viewportAspectRatio
            let activeCanvasWidth = ConfigurationPreviewViewportSpec.canvasWidth(
                availableWidth: width,
                for: orientation,
                isExpanded: isExpanded
            )
            let activeCanvasHeight = activeCanvasWidth
                / activeCanvasAspectRatio
            let alternateRestingWidth = activeCanvasWidth
                * ConfigurationPreviewViewportSpec.alternateCardPeekScale
            let alternateCanvasWidth = alternateRestingWidth
            let alternateCanvasHeight = alternateCanvasWidth / alternateCanvasAspectRatio
            let alternateCenterX = width / 2
                + ConfigurationPreviewViewportSpec.alternateCardPeekOffset

            ZStack(alignment: .topLeading) {
                // The alternate orientation remains subtly visible behind the
                // active canvas; edge buttons provide deliberate switching.
                previewCanvas(for: alternateOrientation)
                    .frame(width: alternateCanvasWidth, height: alternateCanvasHeight)
                    .opacity(ConfigurationPreviewViewportSpec.alternateCardPeekOpacity)
                    .position(
                        x: alternateCenterX,
                        y: canvasCenterY(
                            canvasHeight: alternateCanvasHeight,
                            viewportHeight: viewportHeight,
                            orientation: alternateOrientation
                        ) + 8
                    )
                    .accessibilityHidden(true)

                previewCanvas(for: orientation)
                    .frame(width: activeCanvasWidth, height: activeCanvasHeight)
                    .position(
                        x: width / 2,
                        y: canvasCenterY(
                            canvasHeight: activeCanvasHeight,
                            viewportHeight: viewportHeight,
                            orientation: orientation
                        )
                    )
                    .contentShape(Rectangle())
                    .accessibilityElement(children: .combine)
                    .accessibilityValue(orientationAccessibilityValue)
                    .accessibilityAction(
                        named: Text(
                            filmMarkLocalized(
                                orientation == .landscape
                                    ? "configuration.preview.orientation.switch_to_portrait"
                                    : "configuration.preview.orientation.switch_to_landscape",
                                fallback: orientation == .landscape ? "切换为竖图" : "切换为横图"
                            )
                        )
                    ) {
                        setOrientation(alternateOrientation)
                    }

                if orientation == .portrait && !isExpanded {
                    VStack {
                        LinearGradient(
                            colors: [
                                ConfigurationUI.appBackground.opacity(0.72),
                                ConfigurationUI.appBackground.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 24)
                        Spacer(minLength: 0)
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .overlay(alignment: .top) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.top, 7)
                            .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
                    }
                }

                Button(action: toggleExpanded) {
                    Image(systemName: isExpanded
                        ? "arrow.down.right.and.arrow.up.left"
                        : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .modifier(PreviewControlGlass())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    filmMarkLocalized(
                        isExpanded
                            ? "configuration.preview.zoom.fit"
                            : "configuration.preview.zoom.expand",
                        fallback: isExpanded ? "按比例适应预览窗口" : "放大查看完整图片"
                    )
                )
                .accessibilityHint(
                    filmMarkLocalized(
                        "configuration.preview.zoom.hint",
                        fallback: "只改变预览显示，不改变输出内容或预设"
                    )
                )
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
            .frame(width: width, height: viewportHeight)
            .contentShape(Rectangle())
            .highPriorityGesture(previewExpandGesture)
            .overlay(alignment: .leading) {
                orientationArrowButton(systemImage: "chevron.left")
                    .padding(.leading, 6)
            }
            .overlay(alignment: .trailing) {
                orientationArrowButton(systemImage: "chevron.right")
                    .padding(.trailing, 6)
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: ConfigurationUI.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ConfigurationUI.cornerRadius, style: .continuous)
                    .stroke(ConfigurationUI.faintHairline)
                    .allowsHitTesting(false)
            }
            .shadow(color: ConfigurationUI.cardShadow, radius: 8, y: 3)
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded { onTap?() })
            .animation(
                reduceMotion
                    ? nil
                    : .interactiveSpring(response: 0.38, dampingFraction: 0.98, blendDuration: 0.12),
                value: orientation
            )
            .animation(
                reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.9),
                value: isExpanded
            )
            .accessibilityIdentifier("configuration.preview.production")
        }
        .aspectRatio(
            ConfigurationPreviewViewportSpec.viewportAspectRatio(
                canvasAspectRatio: ConfigurationPreviewViewportSpec.canvasAspectRatio(
                    for: presentationStyle,
                    orientation: orientation
                ),
                for: orientation,
                isExpanded: isExpanded
            ),
            contentMode: .fit
        )
        .animation(
            reduceMotion
                ? nil
                : .interactiveSpring(response: 0.38, dampingFraction: 0.98, blendDuration: 0.12),
            value: orientation
        )
        .animation(
            reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.9),
            value: isExpanded
        )
        // The preview sits above a scrolling editor. In full-canvas mode it
        // must keep the width-derived portrait height instead of shrinking
        // itself to the remaining viewport and making the photo unreadably thin.
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func previewCanvas(
        for orientation: ConfigurationPreviewBackground.Orientation
    ) -> some View {
        MemoryCardPreviewSurface(
            presentationStyle: presentationStyle,
            logoMode: logoMode,
            customLogoImagePath: customLogoImagePath,
            subjectAvatarLogoImagePath: subjectAvatarLogoImagePath,
            regionText: regionText,
            timeText: timeText,
            contextText: contextText,
            memoryText: memoryText,
            filmMarkOutputText: filmMarkOutputText,
            filmMarkConfiguration: filmMarkConfiguration,
            filmMarkPreviewMode: isFilmMarkGeometryExpanded ? .geometry : .contentStrip,
            previewOrientation: orientation
        )
    }

    private func canvasCenterY(
        canvasHeight: CGFloat,
        viewportHeight: CGFloat,
        orientation canvasOrientation: ConfigurationPreviewBackground.Orientation
    ) -> CGFloat {
        guard canvasOrientation == .portrait, !isExpanded else {
            return viewportHeight / 2
        }
        return viewportHeight - canvasHeight / 2
    }

    private var previewExpandGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onEnded { value in
                let vertical = abs(value.translation.height)
                guard orientation == .portrait,
                      vertical > 48,
                      vertical > abs(value.translation.width) * 1.15
                else {
                    return
                }
                setExpanded(value.translation.height > 0)
            }
    }

    private func orientationArrowButton(systemImage: String) -> some View {
        Button {
            setOrientation(alternateOrientation)
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.96))
                .frame(width: 44, height: 44)
                .shadow(color: .black.opacity(0.28), radius: 1, y: 1)
                .modifier(PreviewControlGlass())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            filmMarkLocalized(
                orientation == .landscape
                    ? "configuration.preview.orientation.switch_to_portrait"
                    : "configuration.preview.orientation.switch_to_landscape",
                fallback: orientation == .landscape ? "切换为竖图" : "切换为横图"
            )
        )
    }

    private func setOrientation(_ newValue: ConfigurationPreviewBackground.Orientation) {
        withAnimation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.88)) {
            storedOrientation = newValue.rawValue
        }
    }

    private func toggleExpanded() {
        setExpanded(!isExpanded)
    }

    private func setExpanded(_ newValue: Bool) {
        withAnimation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.9)) {
            isExpanded = newValue
        }
    }
}

private struct PreviewControlGlass: ViewModifier {

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: Circle())
        } else {
            content
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.30), lineWidth: 0.7)
                }
        }
    }
}
#endif
