import SwiftUI

enum ClassicWhiteRenderer {

    enum CardOrientation {
        case landscape
        case portrait
    }

    struct Layout {

        let borderToImageHeightRatio: CGFloat

        let horizontalPaddingRatio: CGFloat

        let verticalPaddingRatio: CGFloat

        let interItemSpacingRatio: CGFloat

        let rightColumnWidthRatio: CGFloat

        let badgeSizeRatio: CGFloat

        let dividerHeightRatio: CGFloat

        let titleFontRatio: CGFloat

        let secondaryFontRatio: CGFloat

        let metadataFontRatio: CGFloat

        func finalAspectRatio(
            imageAspectRatio: CGFloat
        ) -> CGFloat {

            imageAspectRatio
                / (1 + borderToImageHeightRatio)
        }
    }

    static let infoBarColor =
        Color(
            red: 248 / 255,
            green: 247 / 255,
            blue: 245 / 255
        )

    static let dividerColor =
        Color.black.opacity(0.12)

    static let dividerWidth: CGFloat = 1

    static func layout(
        for orientation: CardOrientation
    ) -> Layout {

        switch orientation {

        case .landscape:

            return Layout(
                borderToImageHeightRatio: 1021 / 4536,
                horizontalPaddingRatio: 0.034,
                verticalPaddingRatio: 0.2,
                interItemSpacingRatio: 0.022,
                rightColumnWidthRatio: 0.31,
                badgeSizeRatio: 0.48,
                dividerHeightRatio: 0.55,
                titleFontRatio: 0.27,
                secondaryFontRatio: 0.17,
                metadataFontRatio: 0.27
            )

        case .portrait:

            return Layout(
                borderToImageHeightRatio: 753 / 8064,
                horizontalPaddingRatio: 0.045,
                verticalPaddingRatio: 0.2,
                interItemSpacingRatio: 0.03,
                rightColumnWidthRatio: 0.42,
                badgeSizeRatio: 0.52,
                dividerHeightRatio: 0.6,
                titleFontRatio: 0.28,
                secondaryFontRatio: 0.17,
                metadataFontRatio: 0.28
            )
        }
    }
}
