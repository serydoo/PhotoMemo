import SwiftUI

struct BadgeRenderer {

    let badge: Badge?

    init(badge: Badge? = nil) {
        self.badge = badge
    }

    @ViewBuilder
    func render(size: CGFloat = 128) -> some View {

        if let badge {

            switch badge.type {

            case .none:

                emptyBadge(
                    size: size
                )

            case .systemSymbol:

                Image(
                    systemName:
                        badge.systemSymbol
                        ?? "questionmark"
                )
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: size,
                        height: size
                    )
                    .foregroundStyle(.primary)

            case .png,
                 .customUpload,
                 .svg:

                if let image = image(for: badge) {

                    image
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: size,
                            height: size
                        )

                } else {

                    emptyBadge(
                        size: size
                    )
                }
            }

        } else {

            emptyBadge(
                size: size
            )
        }
    }

    private func image(
        for badge: Badge
    ) -> Image? {

        if let imagePath = badge.imagePath,
           let image = PlatformImage.loadPhotoMemoImage(
                contentsOfFile: imagePath
           ) {

            return image.swiftUIImage
        }

        return nil
    }

    private func emptyBadge(
        size: CGFloat
    ) -> some View {

        Color.clear
            .frame(
                width: size,
                height: size
            )
    }
}
