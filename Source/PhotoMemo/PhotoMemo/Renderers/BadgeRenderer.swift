import SwiftUI

struct BadgeRenderer {

    let image: Image?

    init(image: Image? = nil) {
        self.image = image
    }

    @ViewBuilder
    func render(size: CGFloat = 128) -> some View {

        if let image {

            image
                .resizable()
                .scaledToFit()
                .frame(
                    width: size,
                    height: size
                )

        } else {

            Image(systemName: "applelogo")
                .resizable()
                .scaledToFit()
                .frame(
                    width: size,
                    height: size
                )
        }
    }
}
