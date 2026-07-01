#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct InteractiveMemoryCardCompactPreview: View {

    let leftPrimaryText: String
    let leftSecondaryText: String
    let rightPrimaryText: String
    let rightSecondaryText: String
    let badgeSystemImage: String
    let badgeTitle: String
    let selectedRegion: CardRegion
    let hoveredRegion: CardRegion?
    let onSelectRegion: (CardRegion) -> Void
    let onHoverRegion: (CardRegion?) -> Void

    private var compactPreviewSpec: CompactInformationBarSpec {
        RendererConstants.CompactInformationBar.landscape
    }

    private var compactPreviewWidth: CGFloat {
        590
    }

    private var compactPreviewHeight: CGFloat {
        compactPreviewWidth * compactPreviewSpec.barHeightToWidth
    }

    var body: some View {
        cardSurface
    }

    private var cardSurface: some View {
        bottomCardPreview
            .frame(
                width: compactPreviewWidth,
                height: compactPreviewHeight
            )
            .background(ConfigurationUI.panelBackground)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.cornerRadius,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.cornerRadius,
                    style: .continuous
                )
                .stroke(ConfigurationUI.faintHairline, lineWidth: 1)
            )
            .shadow(
                color: ConfigurationUI.cardShadow,
                radius: 10,
                y: 4
            )
            .animation(
                .easeInOut(duration: 0.16),
                value: selectedRegion
            )
            .animation(
                .easeInOut(duration: 0.12),
                value: hoveredRegion
            )
    }

    private var bottomCardPreview: some View {
        informationBarPreview
    }

    private var informationBarPreview: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let spec = compactPreviewSpec

            ZStack(alignment: .topLeading) {
                RendererConstants.CompactInformationBar.background

                compactTextPair(
                    primaryRegion: CardRegion.region(for: .leftPrimary),
                    secondaryRegion: CardRegion.region(for: .leftSecondary),
                    primary: leftPrimaryText,
                    secondary: leftSecondaryText,
                    spec: spec,
                    barHeight: size.height
                )
                .frame(
                    width: size.width * spec.leftWidth,
                    height: size.height * 0.62,
                    alignment: .leading
                )
                .position(
                    x: size.width * spec.leftX + size.width * spec.leftWidth / 2,
                    y: size.height * spec.contentCenterY
                )

                compactLogoRegion(
                    spec: spec,
                    barHeight: size.height
                )
                .position(
                    x: size.width * spec.logoCenterX,
                    y: size.height * spec.contentCenterY
                )

                Rectangle()
                    .fill(RendererConstants.CompactInformationBar.divider)
                    .frame(
                        width: min(
                            max(
                                size.height * spec.dividerWidthToBarHeight,
                                8
                            ),
                            16
                        ),
                        height: size.height * spec.dividerHeight
                    )
                    .position(
                        x: size.width * spec.dividerCenterX,
                        y: size.height * spec.dividerTopY + size.height * spec.dividerHeight / 2
                    )

                compactTextPair(
                    primaryRegion: CardRegion.region(for: .rightPrimary),
                    secondaryRegion: CardRegion.region(for: .rightSecondary),
                    primary: rightPrimaryText,
                    secondary: rightSecondaryText,
                    spec: spec,
                    barHeight: size.height
                )
                .frame(
                    width: size.width * spec.rightWidth,
                    height: size.height * 0.62,
                    alignment: .leading
                )
                .position(
                    x: size.width * spec.rightX + size.width * spec.rightWidth / 2,
                    y: size.height * spec.contentCenterY
                )
            }
        }
    }

    private func compactTextPair(
        primaryRegion: CardRegion,
        secondaryRegion: CardRegion,
        primary: String,
        secondary: String,
        spec: CompactInformationBarSpec,
        barHeight: CGFloat
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: barHeight * spec.groupSpacingToBarHeight
        ) {
            compactTextLine(
                primaryRegion,
                value: primary,
                fontSize: barHeight * primaryFontToBarHeight(
                    for: primaryRegion,
                    spec: spec
                ),
                weight: .semibold,
                tracking: spec.primaryTracking,
                color: RendererConstants.CompactInformationBar.primaryText
            )
            .offset(
                y: barHeight * spec.primaryYOffsetToBarHeight
            )

            compactTextLine(
                secondaryRegion,
                value: secondary,
                fontSize: barHeight * spec.secondaryFontToBarHeight,
                weight: .regular,
                tracking: spec.secondaryTracking,
                color: RendererConstants.CompactInformationBar.secondaryText
            )
            .offset(
                y: barHeight * spec.secondaryYOffsetToBarHeight
            )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .center
        )
    }

    private func compactTextLine(
        _ region: CardRegion,
        value: String,
        fontSize: CGFloat,
        weight: Font.Weight,
        tracking: CGFloat,
        color: Color
    ) -> some View {
        previewRegionButton(
            region,
            accessibilityValue: value
        ) {
            Text(value.isEmpty ? " " : value)
                .font(
                    .system(
                        size: fontSize,
                        weight: weight
                    )
                )
                .kerning(tracking)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
        }
    }

    private func primaryFontToBarHeight(
        for region: CardRegion,
        spec: CompactInformationBarSpec
    ) -> CGFloat {
        region == CardRegion.region(for: .rightPrimary)
            ? spec.rightPrimaryFontToBarHeight
            : spec.primaryFontToBarHeight
    }

    private func compactLogoRegion(
        spec: CompactInformationBarSpec,
        barHeight: CGFloat
    ) -> some View {
        let logoSize = barHeight * spec.logoSizeToBarHeight

        return previewRegionButton(
            .badge,
            accessibilityValue: badgeTitle
        ) {
            Image(systemName: badgeSystemImage)
                .font(
                    .system(
                        size: logoSize,
                        weight: .semibold
                    )
                )
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    RendererConstants.CompactInformationBar.logoTint
                )
                .frame(
                    width: logoSize * 1.25,
                    height: logoSize * 1.25
                )
        }
    }

    private func previewRegionButton<Content: View>(
        _ region: CardRegion,
        accessibilityValue: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Button {
            onSelectRegion(region)
        } label: {
            content()
                .modifier(
                    InteractiveMemoryCardCompactPreviewChrome(
                        region: region,
                        selectedRegion: selectedRegion,
                        hoveredRegion: hoveredRegion
                    )
                )
        }
        .buttonStyle(.plain)
        .onHover {
            onHoverRegion($0 ? region : nil)
        }
        .accessibilityIdentifier(region.accessibilityIdentifier)
        .accessibilityLabel(region.accessibilityLabel)
        .accessibilityValue(accessibilityValue)
    }
}

private struct InteractiveMemoryCardCompactPreviewChrome: ViewModifier {

    let region: CardRegion
    let selectedRegion: CardRegion
    let hoveredRegion: CardRegion?

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        strokeColor,
                        lineWidth: strokeWidth
                    )
            )
            .contentShape(
                RoundedRectangle(cornerRadius: cornerRadius)
            )
    }

    private var isSelected: Bool {
        region == selectedRegion
    }

    private var isHovered: Bool {
        region == hoveredRegion
    }

    private var cornerRadius: CGFloat {
        switch region {
        case .slotA,
             .slotB,
             .slotC,
             .slotD:
            return 6
        default:
            return 8
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return ConfigurationUI.selectedBackground
        }

        if isHovered {
            return ConfigurationUI.hoverBackground
        }

        return Color.clear
    }

    private var strokeColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.30)
        }

        if isHovered {
            return ConfigurationUI.hairline
        }

        return Color.clear
    }

    private var strokeWidth: CGFloat {
        isSelected ? 1 : 0.75
    }
}
#endif
