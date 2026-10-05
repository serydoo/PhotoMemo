#if DEBUG && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// DEBUG appearance experiments for MemoMark's fourth presentation family.
///
/// Production registration and output use GlassCardProductionRenderer and
/// GlassCardOverlayLayer. This separate research renderer keeps material
/// candidates out of durable configuration and the production media pipeline.
enum GlassCardRenderer {

    static let foreground = Color.white.opacity(0.96)
    static let secondaryForeground = Color.white.opacity(0.72)
    static let keyline = GlassCardMaterialRecipe.lightLayerV1.keyline.swiftUIColor
    static let surfaceTint = Color.white.opacity(0.12)
    static let fixedAlphaSurface = GlassCardMaterialRecipe.lightLayerV1.surface.swiftUIColor
    static let darkFixedAlphaSurface = GlassCardMaterialRecipe.darkLayerV1.surface.swiftUIColor
}

private extension GlassCardMaterialRecipe.RGBA {
    var swiftUIColor: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

enum GlassCardPrototypeSurfaceCandidate: String, CaseIterable, Identifiable {
    case systemMaterial = "系统材质"
    case fixedAlpha = "固定透明层"
    case darkFixedAlpha = "深色透明层"

    var id: Self { self }

    /// System material is a visual reference, never an export recipe.
    var exportRecipe: GlassCardMaterialRecipe? {
        switch self {
        case .systemMaterial: nil
        case .fixedAlpha: .lightLayerV1
        case .darkFixedAlpha: .darkLayerV1
        }
    }
}

enum GlassCardPrototypeEdgeCandidate: String, CaseIterable, Identifiable {
    case noAddedEdge = "无新增边缘"
    case restrainedKeyline = "单层细边"

    var id: Self { self }
}

enum GlassCardPrototypeInkCandidate: String, CaseIterable, Identifiable {
    case referenceWhite = "素材白字"
    case darkInk = "深色文字"

    var id: Self { self }

    var primary: Color {
        switch self {
        case .referenceWhite: GlassCardRenderer.foreground
        case .darkInk: Color.black.opacity(0.88)
        }
    }

    var secondary: Color {
        switch self {
        case .referenceWhite: GlassCardRenderer.secondaryForeground
        case .darkInk: Color.black.opacity(0.70)
        }
    }

    var divider: Color {
        switch self {
        case .referenceWhite: Color.white.opacity(0.30)
        case .darkInk: Color.black.opacity(0.28)
        }
    }
}

enum GlassCardPrototypeTypeScale: String, CaseIterable, Identifiable {
    case current = "当前字号"
    case largerProbe = "加大字号"
    case referenceFit = "素材拟合"

    var id: Self { self }

    var primaryMultiplier: CGFloat {
        switch self {
        case .current: 1
        case .largerProbe: 1.25
        case .referenceFit: 1.12
        }
    }

    var secondaryMultiplier: CGFloat {
        switch self {
        case .current: 1
        case .largerProbe: 1.25
        case .referenceFit: 1.04
        }
    }
}

enum GlassCardPrototypeTextFitCandidate: String, CaseIterable, Identifiable {
    case singleLine = "单行缩放"
    case wrapTwoLines = "最多两行"

    var id: Self { self }

    var lineLimit: Int {
        switch self {
        case .singleLine: 1
        case .wrapTwoLines: 2
        }
    }

    var allowsVerticalExpansion: Bool {
        self == .wrapTwoLines
    }
}

enum GlassCardPrototypeCompositionCandidate: String, CaseIterable, Identifiable {
    case referenceArrangement = "素材构图"
    case leadingBadge = "左侧徽标"

    var id: Self { self }
}

struct GlassCardPrototypeAppearance: Equatable {
    var surfaceCandidate: GlassCardPrototypeSurfaceCandidate = .systemMaterial
    var edgeCandidate: GlassCardPrototypeEdgeCandidate
    var inkCandidate: GlassCardPrototypeInkCandidate = .referenceWhite
    var typeScale: GlassCardPrototypeTypeScale
    var textFitCandidate: GlassCardPrototypeTextFitCandidate = .singleLine
    var compositionCandidate: GlassCardPrototypeCompositionCandidate = .referenceArrangement

    /// Shared eligibility measurement for the reference arrangement's four slots.
    func overflowingPositions(content: GlassCardContentProjection, canvasSize: CGSize) -> [String] {
        let plan = GlassCardResolvedPresentation.resolve(content: content, canvasSize: canvasSize,
            primaryFontMultiplier: typeScale.primaryMultiplier,
            secondaryFontMultiplier: typeScale.secondaryMultiplier,
            lineLimit: textFitCandidate.lineLimit)
        let names = ["左上", "左下", "右上", "右下"]
        return plan.slots.enumerated().compactMap { index, slot in
            slot.fit.outcome == .overflow ? names[index] : nil
        }
    }

    static let current = Self(
        surfaceCandidate: .systemMaterial,
        edgeCandidate: .restrainedKeyline,
        typeScale: .current,
        textFitCandidate: .singleLine,
        compositionCandidate: .referenceArrangement
    )
}

struct GlassCardPrototypeRenderer<Photo: View>: View {

    let photo: Photo
    let content: GlassCardContentProjection
    let badge: Badge?
    let appearance: GlassCardPrototypeAppearance

    init(
        content: GlassCardContentProjection,
        badge: Badge?,
        appearance: GlassCardPrototypeAppearance = .current,
        @ViewBuilder photoContent: () -> Photo
    ) {
        self.photo = photoContent()
        self.content = content
        self.badge = badge
        self.appearance = appearance
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                photo
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipped()

                GlassCardPrototypeOverlay(
                    content: content,
                    badge: badge,
                    appearance: appearance,
                    canvasSize: geometry.size
                )
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .clipped()
    }
}

/// Transparent foreground for the branch-only fixed-alpha artifact probe.
/// Preview and probe use this same geometry and drawing view.
struct GlassCardPrototypeOverlay: View {

    let content: GlassCardContentProjection
    let badge: Badge?
    let appearance: GlassCardPrototypeAppearance
    let canvasSize: CGSize

    var body: some View {
        let geometry = GlassCardResolvedPresentation.resolve(content: content, canvasSize: canvasSize,
            primaryFontMultiplier: appearance.typeScale.primaryMultiplier,
            secondaryFontMultiplier: appearance.typeScale.secondaryMultiplier,
            lineLimit: appearance.textFitCandidate.lineLimit).geometry
        let panelFrame = geometry.panelFrame

        ZStack(alignment: .topLeading) {
            GlassCardInformationPanel(
                content: content,
                badge: badge,
                appearance: appearance,
                geometry: geometry,
                size: panelFrame.size
            )
            .frame(width: panelFrame.width, height: panelFrame.height)
            .offset(x: panelFrame.minX, y: panelFrame.minY)
        }
        .frame(
            width: canvasSize.width,
            height: canvasSize.height,
            alignment: .topLeading
        )
    }
}

private struct GlassCardInformationPanel: View {

    let content: GlassCardContentProjection
    let badge: Badge?
    let appearance: GlassCardPrototypeAppearance
    let geometry: GlassCardLayoutSpecification.ResolvedGeometry
    let size: CGSize

    private var layout: GlassCardLayoutSpecification.Layout {
        GlassCardLayoutSpecification.layout
    }

    var body: some View {
        let height = max(size.height, 1)
        let recipe = appearance.surfaceCandidate.exportRecipe ?? .lightLayerV1
        let shape = RoundedRectangle(
            cornerRadius: height * layout.cornerRadiusToPanelHeight,
            style: .continuous
        )

        contentArrangement(height: height)
        .frame(width: size.width, height: size.height)
        .background {
            Group {
                switch appearance.surfaceCandidate {
                case .systemMaterial:
                    // Research-only visual reference. The system material is
                    // not a deterministic exported-image recipe.
                    shape
                        .fill(.ultraThinMaterial)
                        .overlay { shape.fill(GlassCardRenderer.surfaceTint) }
                case .fixedAlpha:
                    // One constant-alpha fill can be rasterized as a
                    // transparent PresentationArtifact layer. The same layer
                    // blends with each still image or motion frame.
                    shape.fill(GlassCardRenderer.fixedAlphaSurface)
                case .darkFixedAlpha:
                    shape.fill(GlassCardRenderer.darkFixedAlphaSurface)
                }
            }
            .overlay {
                if appearance.edgeCandidate == .restrainedKeyline {
                    shape.stroke(
                        GlassCardRenderer.keyline,
                        lineWidth: height * recipe.keylineWidthToPanelHeight
                    )
                }
            }
        }
        .shadow(
            color: recipe.shadow.swiftUIColor,
            radius: height * recipe.shadowRadiusToPanelHeight,
            y: height * recipe.shadowOffsetToPanelHeight
        )
    }

    @ViewBuilder
    private func contentArrangement(height: CGFloat) -> some View {
        switch appearance.compositionCandidate {
        case .referenceArrangement:
            referenceArrangement(height: height)

        case .leadingBadge:
            HStack(spacing: height * layout.dividerSpacingToPanelHeight) {
                badgeView(height: height)
                    .frame(
                        width: height * layout.logoZoneWidthToPanelHeight,
                        height: height
                    )

                divider(height: height)

                informationColumn(
                    primary: content.leftTop,
                    secondary: content.leftBottom,
                    horizontalAlignment: .leading,
                    textAlignment: .leading,
                    rowSpacingToPanelHeight: layout.leftRowSpacingToPanelHeight,
                    height: height
                )

                Spacer(minLength: height * layout.columnSpacingToPanelHeight)

                informationColumn(
                    primary: content.rightTop,
                    secondary: content.rightBottom,
                    horizontalAlignment: .trailing,
                    textAlignment: .trailing,
                    rowSpacingToPanelHeight: layout.rightRowSpacingToPanelHeight,
                    height: height
                )
            }
            .padding(.leading, height * layout.leftPaddingToPanelHeight)
            .padding(.trailing, height * layout.rightPaddingToPanelHeight)
        }
    }

    private func referenceArrangement(height: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            positionedInformation(
                content.leftTop,
                in: geometry.leftTopFrame,
                fontSize: height * layout.primaryFontToPanelHeight * appearance.typeScale.primaryMultiplier,
                weight: .semibold,
                color: appearance.inkCandidate.primary,
                minimumScale: 0.72
            )
            positionedInformation(
                content.leftBottom,
                in: geometry.leftBottomFrame,
                fontSize: height * layout.secondaryFontToPanelHeight * appearance.typeScale.secondaryMultiplier,
                weight: .medium,
                color: appearance.inkCandidate.secondary,
                minimumScale: 0.70
            )
            badgeView(height: height)
                .frame(width: geometry.badgeFrame.width, height: geometry.badgeFrame.height)
                .offset(x: geometry.badgeFrame.minX, y: geometry.badgeFrame.minY)
            Rectangle()
                .fill(appearance.inkCandidate.divider)
                .frame(width: geometry.dividerFrame.width, height: geometry.dividerFrame.height)
                .offset(x: geometry.dividerFrame.minX, y: geometry.dividerFrame.minY)
            positionedInformation(
                content.rightTop,
                in: geometry.rightTopFrame,
                fontSize: height * layout.primaryFontToPanelHeight * appearance.typeScale.primaryMultiplier,
                weight: .semibold,
                color: appearance.inkCandidate.primary,
                minimumScale: 0.72
            )
            positionedInformation(
                content.rightBottom,
                in: geometry.rightBottomFrame,
                fontSize: height * layout.secondaryFontToPanelHeight * appearance.typeScale.secondaryMultiplier,
                weight: .medium,
                color: appearance.inkCandidate.secondary,
                minimumScale: 0.70
            )
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    private func positionedInformation(
        _ value: String,
        in frame: CGRect,
        fontSize: CGFloat,
        weight: Font.Weight,
        color: Color,
        minimumScale: CGFloat
    ) -> some View {
        let fit = GlassCardTextFitSpecification.resolve(
            text: value,
            frame: frame.size,
            pointSize: fontSize,
            isPrimary: weight == .semibold,
            lineLimit: appearance.textFitCandidate.lineLimit,
            minimumScale: minimumScale
        )
        return Text(value)
            .font(Font(GlassCardTextFitSpecification.font(
                pointSize: fit.pointSize,
                isPrimary: weight == .semibold
            )))
            .foregroundStyle(color)
            .lineLimit(appearance.textFitCandidate.lineLimit)
            .fixedSize(horizontal: false, vertical: false)
            .frame(width: frame.width, height: frame.height, alignment: .leading)
            .multilineTextAlignment(.leading)
            .offset(x: frame.minX, y: frame.minY)
    }

    private func divider(height: CGFloat) -> some View {
        Rectangle()
            .fill(appearance.inkCandidate.divider)
            .frame(
                width: max(1, height * 0.006),
                height: height * layout.dividerHeightToPanelHeight
            )
    }

    @ViewBuilder
    private func badgeView(height: CGFloat) -> some View {
        BadgeRenderer(
            badge: ClassicWhiteRenderer.FrameInput.resolvedLogoBadge(from: badge),
            systemSymbolTint: appearance.inkCandidate.primary
        )
        .render(size: height * layout.logoSizeToPanelHeight)
        .opacity(0.96)
    }

    private func informationColumn(
        primary: String,
        secondary: String,
        horizontalAlignment: HorizontalAlignment,
        textAlignment: TextAlignment,
        rowSpacingToPanelHeight: CGFloat,
        height: CGFloat
    ) -> some View {
        VStack(
            alignment: horizontalAlignment,
            spacing: height * rowSpacingToPanelHeight
        ) {
            Text(primary.isEmpty ? " " : primary)
                .font(
                    .system(
                        size: height
                            * layout.primaryFontToPanelHeight
                            * appearance.typeScale.primaryMultiplier,
                        weight: .semibold
                    )
                )
                .foregroundStyle(appearance.inkCandidate.primary)
                .lineLimit(appearance.textFitCandidate.lineLimit)
                .fixedSize(
                    horizontal: false,
                    vertical: appearance.textFitCandidate.allowsVerticalExpansion
                )
                .minimumScaleFactor(0.72)
                .allowsTightening(true)

            Text(secondary.isEmpty ? " " : secondary)
                .font(
                    .system(
                        size: height
                            * layout.secondaryFontToPanelHeight
                            * appearance.typeScale.secondaryMultiplier,
                        weight: .medium
                    )
                )
                .foregroundStyle(appearance.inkCandidate.secondary)
                .lineLimit(appearance.textFitCandidate.lineLimit)
                .fixedSize(
                    horizontal: false,
                    vertical: appearance.textFitCandidate.allowsVerticalExpansion
                )
                .minimumScaleFactor(0.70)
                .allowsTightening(true)
        }
        .multilineTextAlignment(textAlignment)
    }
}

#endif
