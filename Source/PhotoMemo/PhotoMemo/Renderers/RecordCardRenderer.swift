import SwiftUI

struct RecordCardRenderer: View {

    private struct BlockStyle {

        let fontSize: CGFloat

        let weight: Font.Weight

        let design: Font.Design

        let color: Color

        let tracking: CGFloat

        let lineLimit: Int

        let lineSpacing: CGFloat

        let alignment: HorizontalAlignment

        let textAlignment: TextAlignment
    }

    let image: Image

    let card: RecordCard

    private let textBlockEngine =
        CardTextBlockEngine()

    init(
        image: Image,
        card: RecordCard
    ) {
        self.image = image
        self.card = card
    }

    var body: some View {

        switch card.template.preset {

        case .immersWhite:

            ImmersWhiteCardRenderer(
                image: image,
                card: card
            )

        case .template1,
             .template2,
             .template3:

            classicWhiteCard
        }
    }

    private var classicWhiteCard: some View {

        GeometryReader { geometry in

            let layout =
                ClassicWhiteRenderer.layout(
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
            ClassicWhiteRenderer
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
        layout: ClassicWhiteRenderer.Layout
    ) -> some View {

        HStack(
            alignment: .center,
            spacing: width * layout.interItemSpacingRatio
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
            maxHeight: .infinity
        )
        .background(
            ClassicWhiteRenderer.infoBarColor
        )
    }

    private func leftArea(
        width: CGFloat,
        height: CGFloat,
        layout: ClassicWhiteRenderer.Layout
    ) -> some View {

        pinnedBlockColumn(
            topBlocks: leftTopBlocks,
            bottomBlocks: leftBottomBlocks,
            topStyle: BlockStyle(
                fontSize: max(
                    16,
                    height * layout.titleFontRatio
                ),
                weight: .semibold,
                design: .rounded,
                color: ClassicWhiteRenderer.titleTextColor,
                tracking: layout.titleTracking,
                lineLimit: 2,
                lineSpacing: height * 0.01,
                alignment: .center,
                textAlignment: .center
            ),
            bottomStyle: BlockStyle(
                fontSize: max(
                    13,
                    height * layout.secondaryFontRatio
                ),
                weight: .regular,
                design: .rounded,
                color: ClassicWhiteRenderer.secondaryTextColor,
                tracking: layout.secondaryTracking,
                lineLimit: 2,
                lineSpacing: height * 0.008,
                alignment: .center,
                textAlignment: .center
            ),
            spacing: height * layout.groupSpacingRatio
        )
        .frame(
            width: width * layout.leftColumnWidthRatio,
            alignment: .center
        )
    }

    private func trailingCluster(
        width: CGFloat,
        height: CGFloat,
        layout: ClassicWhiteRenderer.Layout
    ) -> some View {

        HStack(
            alignment: .center,
            spacing: width * layout.trailingClusterSpacingRatio
        ) {

            BadgeRenderer(
                badge: card.badge
            )
            .render(
                size: height * layout.badgeSizeRatio
            )

            Rectangle()
                .fill(
                    ClassicWhiteRenderer.dividerColor
                )
                .frame(
                    width: ClassicWhiteRenderer.dividerWidth,
                    height: height * layout.dividerHeightRatio
                )

            rightArea(
                width: width,
                height: height,
                layout: layout
            )
        }
    }

    private func rightArea(
        width: CGFloat,
        height: CGFloat,
        layout: ClassicWhiteRenderer.Layout
    ) -> some View {

        pinnedBlockColumn(
            topBlocks: rightTopBlocks,
            bottomBlocks: rightBottomBlocks,
            topStyle: BlockStyle(
                fontSize: max(
                    15,
                    height * layout.metadataFontRatio
                ),
                weight: .medium,
                design: .rounded,
                color: ClassicWhiteRenderer.metadataTextColor,
                tracking: layout.metadataTracking,
                lineLimit: 2,
                lineSpacing: height * 0.006,
                alignment: .center,
                textAlignment: .center
            ),
            bottomStyle: BlockStyle(
                fontSize: max(
                    13,
                    height * layout.secondaryFontRatio
                ),
                weight: .medium,
                design: .rounded,
                color: ClassicWhiteRenderer.secondaryTextColor,
                tracking: layout.secondaryTracking,
                lineLimit: 2,
                lineSpacing: height * 0.01,
                alignment: .center,
                textAlignment: .center
            ),
            spacing: height * layout.groupSpacingRatio
        )
        .frame(
            width: width * layout.rightColumnWidthRatio,
            alignment: .center
        )
    }

    private var blocks: [CardTextBlock] {

        textBlockEngine.build(
            from: card
        )
    }

    private var leftTopBlocks: [CardTextBlock] {

        blocks.filter {
            $0.area == .leftTop
        }
    }

    private var leftBottomBlocks: [CardTextBlock] {

        blocks.filter {
            $0.area == .leftBottom
        }
    }

    private var rightTopBlocks: [CardTextBlock] {

        blocks.filter {
            $0.area == .rightTop
        }
    }

    private var rightBottomBlocks: [CardTextBlock] {

        blocks.filter {
            $0.area == .rightBottom
        }
    }

    private var imageAspectRatio: CGFloat {

        let width =
            CGFloat(card.metadata.imageWidth ?? 1)

        let height =
            CGFloat(card.metadata.imageHeight ?? 1)

        guard height > 0 else {
            return 1
        }

        return width / height
    }

    private var orientation: ClassicWhiteRenderer.CardOrientation {

        imageAspectRatio >= 1
            ? .landscape
            : .portrait
    }

    @ViewBuilder
    private func pinnedBlockColumn(
        topBlocks: [CardTextBlock],
        bottomBlocks: [CardTextBlock],
        topStyle: BlockStyle,
        bottomStyle: BlockStyle,
        spacing: CGFloat
    ) -> some View {

        VStack(
            alignment: .center,
            spacing: 0
        ) {

            blockGroup(
                topBlocks,
                style: topStyle
            )

            Spacer(
                minLength:
                    topBlocks.isEmpty || bottomBlocks.isEmpty
                    ? 0
                    : spacing
            )

            blockGroup(
                bottomBlocks,
                style: bottomStyle
            )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .center
        )
    }

    @ViewBuilder
    private func blockGroup(
        _ blocks: [CardTextBlock],
        style: BlockStyle
    ) -> some View {

        if !blocks.isEmpty {

            VStack(
                alignment: style.alignment,
                spacing: style.fontSize * 0.24
            ) {

                ForEach(blocks) { block in

                    styledText(
                        block.value,
                        style: style
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    @ViewBuilder
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
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(style.textAlignment)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
