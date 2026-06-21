import SwiftUI

#if !PHOTOMEMO_SHARE_EXTENSION
private struct ClassicWhiteModuleContent {

    let primary: String

    let secondary: String
}

struct ClassicWhiteCardRenderer: View {

    struct LayoutMetrics: Equatable {

        let contentWidth: CGFloat

        let leftModuleWidth: CGFloat

        let centerModuleWidth: CGFloat

        let rightModuleWidth: CGFloat

        let contentHeight: CGFloat
    }

    let image: Image

    let card: RecordCard

    private let textBlockEngine =
        CardTextBlockEngine()

    private let theme =
        ClassicWhiteRenderer.theme

    var body: some View {

        VStack(spacing: 0) {

            image
                .resizable()
                .scaledToFit()
                .aspectRatio(
                    imageAspectRatio,
                    contentMode: .fit
                )
                .frame(maxWidth: .infinity)
                .layoutPriority(1)

            infoBar
                .frame(
                    height: theme.bottomBar.height
                )
        }
        .background(
            theme.colors.background.color
        )
    }

    private var infoBar: some View {

        GeometryReader { geometry in

            let layout =
                Self.layoutMetrics(
                    forTotalWidth: geometry.size.width,
                    theme: theme
                )

            HStack(
                alignment: .center,
                spacing: 0
            ) {

                ClassicWhiteTextModuleRenderer(
                    content: leftModuleContent,
                    theme: theme
                )
                .frame(
                    width:
                        layout.leftModuleWidth,
                    height: layout.contentHeight,
                    alignment: .leading
                )

                ClassicWhiteCenterModuleRenderer(
                    badge: card.badge,
                    theme: theme
                )
                .frame(
                    width:
                        layout.centerModuleWidth,
                    height: layout.contentHeight
                )

                ClassicWhiteTextModuleRenderer(
                    content: rightModuleContent,
                    theme: theme
                )
                .frame(
                    width:
                        layout.rightModuleWidth,
                    height: layout.contentHeight,
                    alignment: .leading
                )
            }
            .padding(
                .horizontal,
                theme.spacing.horizontalPadding
            )
            .padding(
                .top,
                theme.spacing.topPadding
            )
            .padding(
                .bottom,
                theme.spacing.bottomPadding
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .background(
                theme.colors.background.color
            )
        }
    }

    private var blocks: [CardTextBlock] {

        textBlockEngine.build(
            from: card
        )
    }

    private var leftModuleContent: ClassicWhiteModuleContent {

        .init(
            primary: value(
                for: .leftTop
            ),
            secondary: value(
                for: .leftBottom
            )
        )
    }

    private var rightModuleContent: ClassicWhiteModuleContent {

        .init(
            primary: value(
                for: .rightTop
            ),
            secondary: value(
                for: .rightBottom
            )
        )
    }

    private func value(
        for area: CardTextArea
    ) -> String {

        blocks.first {
            $0.area == area
        }?.value
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""
    }

    private var imageAspectRatio: CGFloat {

        let outputSize =
            ClassicWhiteRenderer
            .outputPixelSize(
                for: card.metadata,
                fallbackSize: CGSize(
                    width: 1,
                    height: 1
                )
            )

        let imageHeight =
            outputSize.height
            - theme.bottomBar.height

        guard imageHeight > 0 else {
            return 1
        }

        return outputSize.width / imageHeight
    }

    static func layoutMetrics(
        forTotalWidth totalWidth: CGFloat,
        theme: RenderTheme =
            ClassicWhiteRenderer.theme
    ) -> LayoutMetrics {

        let contentWidth =
            max(
                0,
                totalWidth
                - theme.spacing.horizontalPadding * 2
            )

        return LayoutMetrics(
            contentWidth: contentWidth,
            leftModuleWidth:
                contentWidth
                * theme.grid.leftRatio,
            centerModuleWidth:
                contentWidth
                * theme.grid.centerRatio,
            rightModuleWidth:
                contentWidth
                * theme.grid.rightRatio,
            contentHeight: theme.contentHeight
        )
    }
}

private struct ClassicWhiteTextModuleRenderer: View {

    let content: ClassicWhiteModuleContent

    let theme: RenderTheme

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            textLine(
                content.primary,
                role: .primary,
                lineBoxHeight:
                    theme.typography
                    .primaryLineBoxHeight,
                alignment: .topLeading
            )

            Spacer(
                minLength:
                    theme.spacing.minimumRowGap
            )

            textLine(
                content.secondary,
                role: .secondary,
                lineBoxHeight:
                    theme.typography
                    .secondaryLineBoxHeight,
                alignment: .bottomLeading
            )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
    }

    @ViewBuilder
    private func textLine(
        _ value: String,
        role: ClassicWhiteTextRole,
        lineBoxHeight: CGFloat,
        alignment: Alignment
    ) -> some View {

        if value.isEmpty {

            Color.clear
                .frame(
                    maxWidth: .infinity,
                    minHeight: lineBoxHeight,
                    maxHeight: lineBoxHeight,
                    alignment: alignment
                )

        } else {

            Text(value)
                .font(
                    .system(
                        size: role.fontSize(
                            using: theme
                        ),
                        weight: role.fontWeight,
                        design: .default
                    )
                )
                .monospacedDigit()
                .kerning(
                    role.tracking(
                        using: theme
                    )
                )
                .foregroundStyle(
                    role.color(
                        using: theme
                    )
                )
                .lineLimit(1)
                .truncationMode(.tail)
                .allowsTightening(false)
                .multilineTextAlignment(.leading)
                .frame(
                    maxWidth: .infinity,
                    minHeight: lineBoxHeight,
                    maxHeight: lineBoxHeight,
                    alignment: alignment
                )
        }
    }
}

private struct ClassicWhiteCenterModuleRenderer: View {

    let badge: Badge?

    let theme: RenderTheme

    var body: some View {

        HStack(
            alignment: .center,
            spacing:
                theme.spacing
                .centerModuleSpacing
        ) {

            BadgeRenderer(
                badge: badge
            )
            .render(
                size:
                    theme.centerModule
                    .symbolSize
            )

            Rectangle()
                .fill(
                    theme.divider.color.color
                )
                .frame(
                    width: theme.divider.width,
                    height: theme.divider.height
                )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .center
        )
    }
}

private enum ClassicWhiteTextRole {

    case primary

    case secondary

    var fontWeight: Font.Weight {

        switch self {

        case .primary:
            return .medium

        case .secondary:
            return .regular
        }
    }

    func fontSize(
        using theme: RenderTheme
    ) -> CGFloat {

        switch self {

        case .primary:
            return theme.typography.primaryTextSize

        case .secondary:
            return theme.typography.secondaryTextSize
        }
    }

    func tracking(
        using theme: RenderTheme
    ) -> CGFloat {

        switch self {

        case .primary:
            return theme.typography.primaryTracking

        case .secondary:
            return theme.typography.secondaryTracking
        }
    }

    func color(
        using theme: RenderTheme
    ) -> Color {

        switch self {

        case .primary:
            return theme.colors.primaryText.color

        case .secondary:
            return theme.colors.secondaryText.color
        }
    }
}
#endif
