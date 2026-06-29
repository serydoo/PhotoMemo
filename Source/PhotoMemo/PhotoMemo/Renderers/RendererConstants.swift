import CoreGraphics
import SwiftUI

enum RendererConstants {

    enum Grid {
        static let unit: CGFloat = 8
        static let xSmall: CGFloat = unit
        static let small: CGFloat = unit * 1.5
        static let medium: CGFloat = unit * 2
        static let large: CGFloat = unit * 3
        static let xLarge: CGFloat = unit * 4
    }

    enum ColorPalette {
        static let documentBackground =
            Color(red: 0.965, green: 0.958, blue: 0.940)
        static let informationBarBackground = Color.white
        static let primaryText = Color.black.opacity(0.88)
        static let secondaryText = Color.black.opacity(0.56)
        static let divider = Color.black.opacity(0.08)
        static let badgeBackground = Color.black.opacity(0.035)
    }

    enum Typography {
        static let heroSize: CGFloat = 22
        static let primarySize: CGFloat = 16
        static let secondarySize: CGFloat = 13
        static let captionSize: CGFloat = 11

        static let heroWeight: Font.Weight = .semibold
        static let regularWeight: Font.Weight = .regular
    }

    enum Border {
        static let photoAreaHeightRatio: CGFloat = 0.68
        static let informationBarHeightRatio: CGFloat = 0.32
        static let cornerRadius: CGFloat = 22
        static let informationBarTopDividerHeight: CGFloat = 1
    }

    enum Slot {
        static let recorder =
            SlotSpec(
                role: .recorder,
                anchor: UnitPoint2D(x: 0.06, y: 0.18),
                size: UnitSize2D(width: 0.28, height: 0.28),
                weight: 5
            )

        static let timeline =
            SlotSpec(
                role: .timeline,
                anchor: UnitPoint2D(x: 0.42, y: 0.18),
                size: UnitSize2D(width: 0.20, height: 0.28),
                weight: 4
            )

        static let captureSummary =
            SlotSpec(
                role: .captureSummary,
                anchor: UnitPoint2D(x: 0.74, y: 0.18),
                size: UnitSize2D(width: 0.18, height: 0.28),
                weight: 3
            )

        static let memoryBlock =
            SlotSpec(
                role: .memoryBlock,
                anchor: UnitPoint2D(x: 0.06, y: 0.60),
                size: UnitSize2D(width: 0.62, height: 0.32),
                weight: 6
            )

        static let badge =
            SlotSpec(
                role: .badge,
                anchor: UnitPoint2D(x: 0.82, y: 0.64),
                size: UnitSize2D(width: 0.12, height: 0.24),
                weight: 1
            )
    }

    enum CaptureSummary {
        static let allowedFactCount = 4

        static let allowedFacts: [CaptureFact] = [
            .focalLength,
            .aperture,
            .iso,
            .shutterSpeed
        ]
    }

    enum CompactInformationBar {
        static let background = Color(
            red: 244 / 255,
            green: 244 / 255,
            blue: 242 / 255
        )

        static let primaryText = Color.black.opacity(0.98)

        static let secondaryText = Color(
            red: 112 / 255,
            green: 112 / 255,
            blue: 118 / 255
        )

        static let logoTint = Color(
            red: 142 / 255,
            green: 142 / 255,
            blue: 147 / 255
        )

        static let divider = Color(
            red: 216 / 255,
            green: 216 / 255,
            blue: 216 / 255
        )

        static let portrait = CompactInformationBarSpec(
            barHeightToWidth: 0.1660,
            referencePhotoHeightToWidth: 8064.0 / 4536.0,
            leftX: 0.045,
            leftWidth: 0.364,
            logoCenterX: 0.490,
            logoSizeToBarHeight: 0.410,
            dividerCenterX: 0.540,
            dividerTopY: 0.264,
            dividerHeight: 0.468,
            dividerWidthToBarHeight: 0.022,
            rightX: 0.566,
            rightWidth: 0.389,
            primaryFontToBarHeight: 0.190,
            secondaryFontToBarHeight: 0.142,
            groupSpacingToBarHeight: 0.098,
            contentCenterY: 0.500,
            primaryYOffsetToBarHeight: 0.019,
            secondaryYOffsetToBarHeight: -0.028,
            primaryTracking: -0.12,
            secondaryTracking: 0
        )

        static let landscape = CompactInformationBarSpec(
            barHeightToWidth: 0.1266,
            referencePhotoHeightToWidth: 2754.0 / 4896.0,
            leftX: 0.035,
            leftWidth: 0.300,
            logoCenterX: 0.636,
            logoSizeToBarHeight: 0.410,
            dividerCenterX: 0.675,
            dividerTopY: 0.263,
            dividerHeight: 0.472,
            dividerWidthToBarHeight: 0.022,
            rightX: 0.696,
            rightWidth: 0.268,
            primaryFontToBarHeight: 0.190,
            secondaryFontToBarHeight: 0.142,
            groupSpacingToBarHeight: 0.112,
            contentCenterY: 0.500,
            primaryYOffsetToBarHeight: 0.020,
            secondaryYOffsetToBarHeight: -0.037,
            primaryTracking: -0.18,
            secondaryTracking: 0
        )

        static func spec(
            for orientation: CompactInformationBarOrientation
        ) -> CompactInformationBarSpec {
            switch orientation {
            case .portrait:
                return portrait
            case .landscape:
                return landscape
            }
        }
    }
}

struct UnitPoint2D: Equatable {
    let x: CGFloat
    let y: CGFloat
}

struct UnitSize2D: Equatable {
    let width: CGFloat
    let height: CGFloat
}

struct SlotSpec: Equatable {
    let role: SlotRole
    let anchor: UnitPoint2D
    let size: UnitSize2D
    let weight: Int
}

enum SlotRole: Equatable {
    case recorder
    case timeline
    case captureSummary
    case memoryBlock
    case badge
}

enum CaptureFact: Equatable {
    case focalLength
    case aperture
    case iso
    case shutterSpeed
}

enum CompactInformationBarOrientation: Equatable {
    case portrait
    case landscape
}

struct CompactInformationBarSpec: Equatable {
    let barHeightToWidth: CGFloat
    let referencePhotoHeightToWidth: CGFloat
    let leftX: CGFloat
    let leftWidth: CGFloat
    let logoCenterX: CGFloat
    let logoSizeToBarHeight: CGFloat
    let dividerCenterX: CGFloat
    let dividerTopY: CGFloat
    let dividerHeight: CGFloat
    let dividerWidthToBarHeight: CGFloat
    let rightX: CGFloat
    let rightWidth: CGFloat
    let primaryFontToBarHeight: CGFloat
    let secondaryFontToBarHeight: CGFloat
    let groupSpacingToBarHeight: CGFloat
    let contentCenterY: CGFloat
    let primaryYOffsetToBarHeight: CGFloat
    let secondaryYOffsetToBarHeight: CGFloat
    let primaryTracking: CGFloat
    let secondaryTracking: CGFloat
}
