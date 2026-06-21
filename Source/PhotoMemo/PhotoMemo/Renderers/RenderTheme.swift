import SwiftUI

struct RenderTheme {

    struct ColorToken: Equatable {

        let red: UInt8

        let green: UInt8

        let blue: UInt8

        init(
            red: UInt8,
            green: UInt8,
            blue: UInt8
        ) {
            self.red = red
            self.green = green
            self.blue = blue
        }

        var color: Color {

            Color(
                red: Double(red) / 255,
                green: Double(green) / 255,
                blue: Double(blue) / 255
            )
        }

        var hexString: String {

            String(
                format: "#%02X%02X%02X",
                red,
                green,
                blue
            )
        }
    }

    struct BottomBar: Equatable {

        let height: CGFloat
    }

    struct Grid: Equatable {

        let leftRatio: CGFloat

        let centerRatio: CGFloat

        let rightRatio: CGFloat
    }

    struct Typography: Equatable {

        let primaryTextSize: CGFloat

        let secondaryTextSize: CGFloat

        let primaryLineBoxHeight: CGFloat

        let secondaryLineBoxHeight: CGFloat

        let primaryTracking: CGFloat

        let secondaryTracking: CGFloat
    }

    struct Spacing: Equatable {

        let horizontalPadding: CGFloat

        let topPadding: CGFloat

        let bottomPadding: CGFloat

        let minimumRowGap: CGFloat

        let centerModuleSpacing: CGFloat
    }

    struct Divider: Equatable {

        let width: CGFloat

        let height: CGFloat

        let color: ColorToken
    }

    struct CenterModule: Equatable {

        let symbolSize: CGFloat
    }

    struct Colors: Equatable {

        let background: ColorToken

        let primaryText: ColorToken

        let secondaryText: ColorToken

        let accent: ColorToken
    }

    let bottomBar: BottomBar

    let colors: Colors

    let grid: Grid

    let typography: Typography

    let spacing: Spacing

    let divider: Divider

    let centerModule: CenterModule

    var contentHeight: CGFloat {

        max(
            0,
            bottomBar.height
            - spacing.topPadding
            - spacing.bottomPadding
        )
    }
}

enum ClassicWhiteTheme {

    static let theme = RenderTheme(
        bottomBar: .init(
            height: 260
        ),
        colors: .init(
            background: .init(
                red: 0xF4,
                green: 0xF3,
                blue: 0xF3
            ),
            primaryText: .init(
                red: 0x20,
                green: 0x20,
                blue: 0x20
            ),
            secondaryText: .init(
                red: 0x72,
                green: 0x72,
                blue: 0x76
            ),
            accent: .init(
                red: 0x88,
                green: 0x88,
                blue: 0x8D
            )
        ),
        grid: .init(
            leftRatio: 0.40,
            centerRatio: 0.20,
            rightRatio: 0.40
        ),
        typography: .init(
            primaryTextSize: 28,
            secondaryTextSize: 18,
            primaryLineBoxHeight: 34,
            secondaryLineBoxHeight: 24,
            primaryTracking: -0.16,
            secondaryTracking: 0
        ),
        spacing: .init(
            horizontalPadding: 80,
            topPadding: 54,
            bottomPadding: 42,
            minimumRowGap: 16,
            centerModuleSpacing: 18
        ),
        divider: .init(
            width: 2,
            height: 110,
            color: .init(
                red: 0xD8,
                green: 0xD8,
                blue: 0xD8
            )
        ),
        centerModule: .init(
            symbolSize: 48
        )
    )
}
