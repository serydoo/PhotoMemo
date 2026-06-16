import SwiftUI

struct RecordCardRenderer: View {

    let image: Image

    let metadata: PhotoMetadata

    let anchorResult: AnchorResult

    let badgeImage: Image?

    init(
        image: Image,
        metadata: PhotoMetadata,
        anchorResult: AnchorResult,
        badgeImage: Image? = nil
    ) {
        self.image = image
        self.metadata = metadata
        self.anchorResult = anchorResult
        self.badgeImage = badgeImage
    }

    var body: some View {

        VStack(spacing: 0) {

            image
                .resizable()
                .scaledToFit()

            infoBar
        }
    }

    private var infoBar: some View {

        GeometryReader { geometry in

            HStack(spacing: 0) {

                leftArea(width: geometry.size.width)

                centerArea(width: geometry.size.width)

                rightArea(width: geometry.size.width)
            }
            .padding(ClassicWhiteRenderer.padding)
            .background(
                ClassicWhiteRenderer.infoBarColor
            )
        }
        .frame(
            height: ClassicWhiteRenderer.infoBarHeight
        )
    }

    private func leftArea(width: CGFloat) -> some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text(anchorResult.title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(anchorResult.primaryText)
                .font(.headline)
        }
        .frame(
            width: width * ClassicWhiteRenderer.leftWidthRatio,
            alignment: .leading
        )
    }

    private func centerArea(width: CGFloat) -> some View {

        VStack {

            BadgeRenderer(
                image: badgeImage
            )
            .render()
        }
        .frame(
            width: width * ClassicWhiteRenderer.centerWidthRatio
        )
    }

    private func rightArea(width: CGFloat) -> some View {

        VStack(
            alignment: .trailing,
            spacing: 6
        ) {

            Text(metadata.deviceModel)
                .font(.headline)

            Text(metadata.lensModel)
                .font(.caption)

            Text("ISO \(metadata.iso)")
                .font(.caption2)

            Text(metadata.aperture)
                .font(.caption2)

            Text(metadata.shutterSpeed)
                .font(.caption2)
        }
        .frame(
            width: width * ClassicWhiteRenderer.rightWidthRatio,
            alignment: .trailing
        )
    }
}
