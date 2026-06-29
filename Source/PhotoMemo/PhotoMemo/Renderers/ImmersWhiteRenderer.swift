import SwiftUI

enum ImmersWhiteRenderer {

    enum ColumnAlignment: Equatable {
        case leading
        case trailing
    }

    enum CardOrientation {
        case landscape
        case portrait
    }

    struct Layout {

        let borderToImageHeightRatio: CGFloat

        let horizontalPaddingRatio: CGFloat

        let verticalPaddingRatio: CGFloat

        let logoToDividerSpacingRatio: CGFloat

        let dividerToTextSpacingRatio: CGFloat

        let leftColumnWidthRatio: CGFloat

        let rightColumnWidthRatio: CGFloat

        let logoSlotWidthRatio: CGFloat

        let logoSizeRatio: CGFloat

        let dividerHeightRatio: CGFloat

        let titleFontRatio: CGFloat

        let metadataFontRatio: CGFloat

        let bottomFontRatio: CGFloat

        let titleLineSpacingRatio: CGFloat

        let metadataLineSpacingRatio: CGFloat

        let bottomLineSpacingRatio: CGFloat

        let groupSpacingRatio: CGFloat

        let titleTracking: CGFloat

        let metadataTracking: CGFloat

        let bottomTracking: CGFloat

        let rightColumnAlignment:
            ColumnAlignment

        func finalAspectRatio(
            imageAspectRatio: CGFloat
        ) -> CGFloat {

            imageAspectRatio
                / (1 + borderToImageHeightRatio)
        }
    }

    struct FrameInput: Hashable {

        let imageWidth: Int

        let imageHeight: Int

        let slot0: String

        let slot1: String

        let slot2: String

        let slot3: String

        let routine: Bool

        let styleID: String

        let styleName: String

        let logoName: String?

        static func build(
            from card: RecordCard,
            blocks: [CardTextBlock]
        ) -> FrameInput {

            func value(
                for area: CardTextArea
            ) -> String {

                blocks.first {
                    $0.area == area
                }?.value
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ) ?? ""
            }

            let slot0 = value(for: .leftTop)
            let slot1 = value(for: .rightTop)
            let slot2 = value(for: .leftBottom)
            let slot3 = value(for: .rightBottom)

            return FrameInput(
                imageWidth: max(
                    card.metadata.imageWidth ?? 0,
                    1
                ),
                imageHeight: max(
                    card.metadata.imageHeight ?? 0,
                    1
                ),
                slot0: slot0,
                slot1: slot1,
                slot2: slot2,
                slot3: slot3,
                routine:
                    !slot0.isEmpty
                    || !slot1.isEmpty
                    || !slot2.isEmpty
                    || !slot3.isEmpty,
                styleID: card.template.preset.rawValue,
                styleName:
                    card.template.preset.displayName,
                logoName: visibleBadgeName(
                    from: card.badge
                )
            )
        }

        private static func visibleBadgeName(
            from badge: Badge?
        ) -> String? {

            let resolvedBadge =
                resolvedLogoBadge(
                    from: badge
                )

            guard let resolvedBadge else {
                return nil
            }

            let trimmed =
                resolvedBadge.name.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            return trimmed.isEmpty ? nil : trimmed
        }

        static func resolvedLogoBadge(
            from badge: Badge?
        ) -> Badge? {

            if let badge,
               badge.type != .none {
                return badge
            }

            return .appleClassic
        }
    }

    static let infoBarColor =
        RendererConstants.CompactInformationBar.background

    static let primaryTextColor =
        RendererConstants.CompactInformationBar.primaryText

    static let secondaryTextColor =
        RendererConstants.CompactInformationBar.secondaryText

    static let logoTintColor =
        RendererConstants.CompactInformationBar.logoTint

    static let dividerColor =
        RendererConstants.CompactInformationBar.divider

    static let dividerWidth: CGFloat = 2

    static let primaryMinimumScaleFactor: CGFloat = 0.82

    static let secondaryMinimumScaleFactor: CGFloat = 0.84

    static func orientation(
        for metadata: PhotoMetadata
    ) -> CardOrientation {

        let width =
            CGFloat(metadata.imageWidth ?? 1)
        let height =
            CGFloat(metadata.imageHeight ?? 1)

        return width >= height
            ? .landscape
            : .portrait
    }

    static func layout(
        for orientation: CardOrientation
    ) -> Layout {

        switch orientation {

        case .landscape:

            return Layout(
                borderToImageHeightRatio: 1021 / 4536,
                horizontalPaddingRatio: 0.033,
                verticalPaddingRatio: 0.19,
                logoToDividerSpacingRatio: 0.012,
                dividerToTextSpacingRatio: 0.008,
                leftColumnWidthRatio: 0.42,
                rightColumnWidthRatio: 0.35,
                logoSlotWidthRatio: 0.076,
                logoSizeRatio: 0.34,
                dividerHeightRatio: 0.50,
                titleFontRatio: 0.218,
                metadataFontRatio: 0.218,
                bottomFontRatio: 0.132,
                titleLineSpacingRatio: 0.012,
                metadataLineSpacingRatio: 0.012,
                bottomLineSpacingRatio: 0.008,
                groupSpacingRatio: 0.112,
                titleTracking: -0.18,
                metadataTracking: -0.18,
                bottomTracking: 0,
                rightColumnAlignment:
                    .leading
            )

        case .portrait:

            return Layout(
                borderToImageHeightRatio: 753 / 8064,
                horizontalPaddingRatio: 0.041,
                verticalPaddingRatio: 0.2,
                logoToDividerSpacingRatio: 0.015,
                dividerToTextSpacingRatio: 0.007,
                leftColumnWidthRatio: 0.43,
                rightColumnWidthRatio: 0.35,
                logoSlotWidthRatio: 0.10,
                logoSizeRatio: 0.42,
                dividerHeightRatio: 0.54,
                titleFontRatio: 0.225,
                metadataFontRatio: 0.225,
                bottomFontRatio: 0.142,
                titleLineSpacingRatio: 0.011,
                metadataLineSpacingRatio: 0.011,
                bottomLineSpacingRatio: 0.008,
                groupSpacingRatio: 0.098,
                titleTracking: -0.12,
                metadataTracking: -0.12,
                bottomTracking: 0,
                rightColumnAlignment:
                    .leading
            )
        }
    }

    static func outputPixelSize(
        for metadata: PhotoMetadata,
        fallbackSize: CGSize
    ) -> CGSize {

        let width =
            CGFloat(
                metadata.imageWidth
                ?? Int(fallbackSize.width)
            )

        let imageHeight =
            CGFloat(
                metadata.imageHeight
                ?? Int(fallbackSize.height)
            )

        let layout =
            layout(
                for: orientation(
                    for: metadata
                )
            )

        return CGSize(
            width: width,
            height:
                imageHeight
                * (1 + layout.borderToImageHeightRatio)
        )
    }
}

struct ImmersWhiteCardRenderer: View {

    private struct BlockStyle {

        let fontSize: CGFloat

        let weight: Font.Weight

        let design: Font.Design

        let color: Color

        let tracking: CGFloat

        let lineSpacing: CGFloat

        let lineLimit: Int

        let minimumScaleFactor: CGFloat

        let alignment: HorizontalAlignment

        let textAlignment: TextAlignment
    }

    let image: Image

    let card: RecordCard

    private let textBlockEngine =
        CardTextBlockEngine()

    var body: some View {

        GeometryReader { geometry in

            let layout =
                ImmersWhiteRenderer.layout(
                    for: orientation
                )

            let imageHeight =
                geometry.size.height
                / (1 + layout.borderToImageHeightRatio)

            let infoBarHeight =
                geometry.size.height
                - imageHeight

            VStack(spacing: 0) {

                image
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: geometry.size.width,
                        height: imageHeight
                    )
                    .clipped()

                infoBar(
                    width: geometry.size.width,
                    height: infoBarHeight,
                    layout: layout
                )
            }
        }
        .aspectRatio(
            ImmersWhiteRenderer
                .layout(for: orientation)
                .finalAspectRatio(
                    imageAspectRatio: imageAspectRatio
                ),
            contentMode: .fit
        )
    }

    private func infoBar(
        width: CGFloat,
        height: CGFloat,
        layout: ImmersWhiteRenderer.Layout
    ) -> some View {

        HStack(
            alignment: .center,
            spacing: 0
        ) {

            leftArea(
                width: width,
                height: height,
                layout: layout
            )

            Spacer(minLength: 0)

            trailingCluster(
                width: width,
                height: height,
                layout: layout
            )
        }
        .padding(
            .horizontal,
            width * layout.horizontalPaddingRatio
        )
        .padding(
            .vertical,
            height * layout.verticalPaddingRatio
        )
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .leading
        )
        .background(
            ImmersWhiteRenderer.infoBarColor
        )
    }

    private func leftArea(
        width: CGFloat,
        height: CGFloat,
        layout: ImmersWhiteRenderer.Layout
    ) -> some View {

        pinnedColumn(
            topValue: frameInput.slot0,
            bottomValue: frameInput.slot2,
            topStyle: BlockStyle(
                fontSize: max(
                    16,
                    height * layout.titleFontRatio
                ),
                weight: .bold,
                design: .default,
                color: ImmersWhiteRenderer
                    .primaryTextColor,
                tracking:
                    layout.titleTracking,
                lineSpacing:
                    height
                    * layout.titleLineSpacingRatio,
                lineLimit: 1,
                minimumScaleFactor:
                    ImmersWhiteRenderer
                    .primaryMinimumScaleFactor,
                alignment: .leading,
                textAlignment: .leading
            ),
            bottomStyle: BlockStyle(
                fontSize: max(
                    12,
                    height * layout.bottomFontRatio
                ),
                weight: .regular,
                design: .default,
                color: ImmersWhiteRenderer
                    .secondaryTextColor,
                tracking:
                    layout.bottomTracking,
                lineSpacing:
                    height
                    * layout.bottomLineSpacingRatio,
                lineLimit: 1,
                minimumScaleFactor:
                    ImmersWhiteRenderer
                    .secondaryMinimumScaleFactor,
                alignment: .leading,
                textAlignment: .leading
            ),
            spacing:
                height
                * layout.groupSpacingRatio
        )
        .frame(
            width:
                width
                * layout.leftColumnWidthRatio,
            alignment: .leading
        )
    }

    @ViewBuilder
    private func trailingCluster(
        width: CGFloat,
        height: CGFloat,
        layout: ImmersWhiteRenderer.Layout
    ) -> some View {

        HStack(
            alignment: .center,
            spacing: 0
        ) {

            if showsLogo {

                logoArea(
                    width: width,
                    height: height,
                    layout: layout
                )
                .frame(
                    width:
                        width
                        * layout.logoSlotWidthRatio,
                    alignment: .trailing
                )
                .padding(
                    .trailing,
                    width
                    * layout.logoToDividerSpacingRatio
                )

                Rectangle()
                    .fill(
                        ImmersWhiteRenderer.dividerColor
                    )
                    .frame(
                        width:
                            ImmersWhiteRenderer
                            .dividerWidth,
                        height:
                            height
                            * layout.dividerHeightRatio
                    )
                    .padding(
                        .trailing,
                        width
                        * layout.dividerToTextSpacingRatio
                    )
            }

            rightArea(
                width: width,
                height: height,
                layout: layout
            )
            .frame(
                width:
                    width
                    * layout.rightColumnWidthRatio,
                alignment:
                    layout.rightColumnAlignment == .leading
                    ? .leading
                    : .trailing
            )
        }
    }

    @ViewBuilder
    private func logoArea(
        width: CGFloat,
        height: CGFloat,
        layout: ImmersWhiteRenderer.Layout
    ) -> some View {

        BadgeRenderer(
            badge: resolvedLogoBadge
        )
        .render(
            size:
                min(
                    height * layout.logoSizeRatio,
                    width * layout.logoSlotWidthRatio
                )
        )
        .colorMultiply(
            ImmersWhiteRenderer.logoTintColor
        )
        .opacity(0.94)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .trailing
        )
    }

    private func rightArea(
        width: CGFloat,
        height: CGFloat,
        layout: ImmersWhiteRenderer.Layout
    ) -> some View {

        let horizontalAlignment:
            HorizontalAlignment =
            layout.rightColumnAlignment == .leading
            ? .leading
            : .trailing

        let textAlignment:
            TextAlignment =
            layout.rightColumnAlignment == .leading
            ? .leading
            : .trailing

        return pinnedColumn(
            topValue: frameInput.slot1,
            bottomValue: frameInput.slot3,
            topStyle: BlockStyle(
                fontSize: max(
                    15,
                    height * layout.metadataFontRatio
                ),
                weight: .bold,
                design: .default,
                color: ImmersWhiteRenderer
                    .primaryTextColor,
                tracking:
                    layout.metadataTracking,
                lineSpacing:
                    height
                    * layout.metadataLineSpacingRatio,
                lineLimit: 1,
                minimumScaleFactor:
                    ImmersWhiteRenderer
                    .primaryMinimumScaleFactor,
                alignment:
                    horizontalAlignment,
                textAlignment:
                    textAlignment
            ),
            bottomStyle: BlockStyle(
                fontSize: max(
                    12,
                    height * layout.bottomFontRatio
                ),
                weight: .regular,
                design: .default,
                color: ImmersWhiteRenderer
                    .secondaryTextColor,
                tracking:
                    layout.bottomTracking,
                lineSpacing:
                    height
                    * layout.bottomLineSpacingRatio,
                lineLimit: 2,
                minimumScaleFactor:
                    ImmersWhiteRenderer
                    .secondaryMinimumScaleFactor,
                alignment:
                    horizontalAlignment,
                textAlignment:
                    textAlignment
            ),
            spacing:
                height
                * layout.groupSpacingRatio
        )
    }

    @ViewBuilder
    private func pinnedColumn(
        topValue: String,
        bottomValue: String,
        topStyle: BlockStyle,
        bottomStyle: BlockStyle,
        spacing: CGFloat
    ) -> some View {

        let hasTop =
            !topValue.isEmpty
        let hasBottom =
            !bottomValue.isEmpty
        let clusterSpacing =
            hasTop && hasBottom
            ? spacing
            : 0

        VStack(
            alignment: topStyle.alignment,
            spacing: clusterSpacing
        ) {

            if hasTop {
                styledText(
                    topValue,
                    style: topStyle
                )
            }

            if hasBottom {
                styledText(
                    bottomValue,
                    style: bottomStyle
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .center
        )
    }

    private func styledText(
        _ value: String,
        style: BlockStyle
    ) -> some View {

        Text(value)
            .font(
                .system(
                    size: style.fontSize,
                    weight: style.weight,
                    design: style.design
                )
            )
            .monospacedDigit()
            .kerning(style.tracking)
            .lineSpacing(style.lineSpacing)
            .foregroundStyle(style.color)
            .lineLimit(style.lineLimit)
            .allowsTightening(true)
            .minimumScaleFactor(
                style.minimumScaleFactor
            )
            .multilineTextAlignment(
                style.textAlignment
            )
            .frame(
                maxWidth: .infinity,
                alignment:
                    style.alignment == .leading
                    ? .leading
                    : .trailing
            )
    }

    private var blocks: [CardTextBlock] {

        textBlockEngine.build(
            from: card
        )
    }

    private var frameInput:
        ImmersWhiteRenderer.FrameInput {

        ImmersWhiteRenderer.FrameInput.build(
            from: card,
            blocks: blocks
        )
    }

    private var showsLogo: Bool {

        frameInput.logoName != nil
    }

    private var resolvedLogoBadge: Badge? {

        ImmersWhiteRenderer.FrameInput
            .resolvedLogoBadge(
                from: card.badge
            )
    }

    private var imageAspectRatio: CGFloat {

        let width =
            CGFloat(frameInput.imageWidth)
        let height =
            CGFloat(frameInput.imageHeight)

        guard height > 0 else {
            return 1
        }

        return width / height
    }

    private var orientation:
        ImmersWhiteRenderer.CardOrientation {

        ImmersWhiteRenderer.orientation(
            for: card.metadata
        )
    }
}
