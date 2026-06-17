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

        let trailingClusterSpacingRatio: CGFloat

        let leftColumnWidthRatio: CGFloat

        let rightColumnWidthRatio: CGFloat

        let badgeSizeRatio: CGFloat

        let dividerHeightRatio: CGFloat

        let titleFontRatio: CGFloat

        let secondaryFontRatio: CGFloat

        let metadataFontRatio: CGFloat

        let groupSpacingRatio: CGFloat

        let titleTracking: CGFloat

        let metadataTracking: CGFloat

        let secondaryTracking: CGFloat

        func finalAspectRatio(
            imageAspectRatio: CGFloat
        ) -> CGFloat {

            imageAspectRatio
                / (1 + borderToImageHeightRatio)
        }
    }

    static let infoBarColor =
        Color.white

    static let titleTextColor =
        Color(
            red: 34 / 255,
            green: 37 / 255,
            blue: 43 / 255
        )

    static let metadataTextColor =
        Color(
            red: 64 / 255,
            green: 68 / 255,
            blue: 76 / 255
        )

    static let secondaryTextColor =
        Color(
            red: 116 / 255,
            green: 121 / 255,
            blue: 130 / 255
        )

    static let dividerColor =
        Color.black.opacity(0.08)

    static let dividerWidth: CGFloat = 1

    static func layout(
        for orientation: CardOrientation
    ) -> Layout {

        switch orientation {

        case .landscape:

            return Layout(
                borderToImageHeightRatio: 1021 / 4536,
                horizontalPaddingRatio: 0.031,
                verticalPaddingRatio: 0.19,
                interItemSpacingRatio: 0.024,
                trailingClusterSpacingRatio: 0.017,
                leftColumnWidthRatio: 0.39,
                rightColumnWidthRatio: 0.33,
                badgeSizeRatio: 0.43,
                dividerHeightRatio: 0.48,
                titleFontRatio: 0.235,
                secondaryFontRatio: 0.148,
                metadataFontRatio: 0.182,
                groupSpacingRatio: 0.068,
                titleTracking: -0.2,
                metadataTracking: 0.35,
                secondaryTracking: 0
            )

        case .portrait:

            return Layout(
                borderToImageHeightRatio: 753 / 8064,
                horizontalPaddingRatio: 0.04,
                verticalPaddingRatio: 0.19,
                interItemSpacingRatio: 0.031,
                trailingClusterSpacingRatio: 0.021,
                leftColumnWidthRatio: 0.35,
                rightColumnWidthRatio: 0.42,
                badgeSizeRatio: 0.46,
                dividerHeightRatio: 0.5,
                titleFontRatio: 0.24,
                secondaryFontRatio: 0.15,
                metadataFontRatio: 0.19,
                groupSpacingRatio: 0.072,
                titleTracking: -0.15,
                metadataTracking: 0.28,
                secondaryTracking: 0
            )
        }
    }
}
