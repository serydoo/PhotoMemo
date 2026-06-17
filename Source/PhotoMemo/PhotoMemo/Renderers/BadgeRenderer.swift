import SwiftUI
import AppKit

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

                placeholder(
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

                    placeholder(
                        size: size
                    )
                }
            }

        } else {

            placeholder(
                size: size
            )
        }
    }

    private func image(
        for badge: Badge
    ) -> Image? {

        if let imagePath = badge.imagePath,
           let image = NSImage(contentsOfFile: imagePath) {

            return Image(nsImage: image)
        }

        return nil
    }

    private func placeholder(
        size: CGFloat
    ) -> some View {

        Image(systemName: "circle.dashed")
            .resizable()
            .scaledToFit()
            .frame(
                width: size,
                height: size
            )
            .foregroundStyle(.tertiary)
    }
}
