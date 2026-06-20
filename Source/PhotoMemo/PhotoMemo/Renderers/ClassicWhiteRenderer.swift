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

        let badgeToDividerSpacingRatio: CGFloat

        let dividerToContentSpacingRatio: CGFloat

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
        Color(
            red: 244 / 255,
            green: 244 / 255,
            blue: 242 / 255
        )

    static let titleTextColor =
        Color(
            red: 32 / 255,
            green: 32 / 255,
            blue: 32 / 255
        )

    static let metadataTextColor =
        Color(
            red: 38 / 255,
            green: 38 / 255,
            blue: 38 / 255
        )

    static let secondaryTextColor =
        Color(
            red: 122 / 255,
            green: 122 / 255,
            blue: 122 / 255
        )

    static let dividerColor =
        Color(
            red: 216 / 255,
            green: 216 / 255,
            blue: 216 / 255
        )

    static let dividerWidth: CGFloat = 2

    static func layout(
        for orientation: CardOrientation
    ) -> Layout {

        switch orientation {

        case .landscape:

            return Layout(
                borderToImageHeightRatio: 557 / 5000,
                horizontalPaddingRatio: 0.034,
                verticalPaddingRatio: 0.13,
                interItemSpacingRatio: 0.022,
                badgeToDividerSpacingRatio: 0.010,
                dividerToContentSpacingRatio: 0.022,
                leftColumnWidthRatio: 0.40,
                rightColumnWidthRatio: 0.32,
                badgeSizeRatio: 0.29,
                dividerHeightRatio: 0.41,
                titleFontRatio: 0.165,
                secondaryFontRatio: 0.078,
                metadataFontRatio: 0.165,
                groupSpacingRatio: 0.055,
                titleTracking: -0.08,
                metadataTracking: -0.04,
                secondaryTracking: 0
            )

        case .portrait:

            return Layout(
                borderToImageHeightRatio: 235 / 8582,
                horizontalPaddingRatio: 0.045,
                verticalPaddingRatio: 0.135,
                interItemSpacingRatio: 0.024,
                badgeToDividerSpacingRatio: 0.010,
                dividerToContentSpacingRatio: 0.022,
                leftColumnWidthRatio: 0.44,
                rightColumnWidthRatio: 0.38,
                badgeSizeRatio: 0.33,
                dividerHeightRatio: 0.47,
                titleFontRatio: 0.14,
                secondaryFontRatio: 0.072,
                metadataFontRatio: 0.14,
                groupSpacingRatio: 0.05,
                titleTracking: 0,
                metadataTracking: 0,
                secondaryTracking: 0
            )
        }
    }
}
