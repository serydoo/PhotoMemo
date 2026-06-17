import SwiftUI

struct RecordCardRenderer: View {

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
                height: height,
                layout: layout
            )

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
        height: CGFloat,
        layout: ClassicWhiteRenderer.Layout
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: height * 0.08
        ) {

            blockGroup(
                leftTopBlocks,
                fontSize: max(
                    16,
                    height * layout.titleFontRatio
                ),
                weight: .semibold,
                color: .primary
            )

            blockGroup(
                leftBottomBlocks,
                fontSize: max(
                    13,
                    height * layout.secondaryFontRatio
                ),
                weight: .regular,
                color: .secondary
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    private func rightArea(
        width: CGFloat,
        height: CGFloat,
        layout: ClassicWhiteRenderer.Layout
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: height * 0.08
        ) {

            blockGroup(
                rightTopBlocks,
                fontSize: max(
                    16,
                    height * layout.metadataFontRatio
                ),
                weight: .semibold,
                color: .primary
            )

            blockGroup(
                rightBottomBlocks,
                fontSize: max(
                    13,
                    height * layout.secondaryFontRatio
                ),
                weight: .regular,
                color: .secondary
            )
        }
        .frame(
            width: width * layout.rightColumnWidthRatio,
            alignment: .leading
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
    private func blockGroup(
        _ blocks: [CardTextBlock],
        fontSize: CGFloat,
        weight: Font.Weight,
        color: Color
    ) -> some View {

        if !blocks.isEmpty {

            VStack(
                alignment: .leading,
                spacing: fontSize * 0.28
            ) {

                ForEach(blocks) { block in

                    Text(block.value)
                        .font(
                            .system(
                                size: fontSize,
                                weight: weight
                            )
                        )
                        .foregroundStyle(color)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }
}
