#if os(iOS)
import SwiftUI
import UIKit

struct MemoMarkTypographyToken {

    let size: CGFloat
    let uiWeight: UIFont.Weight
    let uiTextStyle: UIFont.TextStyle
    let swiftUIWeight: Font.Weight
    let swiftUITextStyle: Font.TextStyle

    var swiftUIFont: Font {
        Font
            .system(
                swiftUITextStyle,
                design: .default
            )
            .weight(swiftUIWeight)
    }

    func uiFont(
        compatibleWith traitCollection: UITraitCollection? = nil
    ) -> UIFont {
        UIFontMetrics(
            forTextStyle: uiTextStyle
        ).scaledFont(
            for: UIFont.systemFont(
                ofSize: size,
                weight: uiWeight
            ),
            compatibleWith: traitCollection
        )
    }
}

enum MemoMarkDesignTokens {

    enum Spacing {
        static let extraSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
        static let pageHorizontal: CGFloat = 16
        static let cardContent: CGFloat = 14
    }

    enum CornerRadius {
        static let control: CGFloat = 10
        static let compactControl: CGFloat = 11
        static let card: CGFloat = 18
        static let preview: CGFloat = 12
    }

    enum Stroke {
        static let hairlineWidth: CGFloat = 0.5
        static let standardWidth: CGFloat = 1
    }

    enum SurfaceMaterial {
        static let contextual: Material = .regular
        static let elevated: Material = .thick
    }

    enum Elevation {
        static let cardColor = Color(
            uiColor: UIColor { traitCollection in
                UIColor.black.withAlphaComponent(
                    traitCollection.userInterfaceStyle == .dark
                    ? 0.30
                    : 0.05
                )
            }
        )
        static let cardRadius: CGFloat = 4
        static let cardOffsetY: CGFloat = 1
        static let previewRadius: CGFloat = 8
        static let previewOffsetY: CGFloat = 3
    }

    enum ControlState {
        static let minimumTouchTarget: CGFloat = 44
        static let disabledOpacity: Double = 0.45
        static let pressedOpacity: Double = 0.82
        static let selectedTintOpacity: Double = 0.075
        static let hoverTintOpacity: Double = 0.018
    }

    enum Semantic {

        static let interaction = Color.accentColor
        static let success = Color(uiColor: .systemGreen)
        static let memoryStatistics = Color(uiColor: .systemTeal)
        static let danger = Color(uiColor: .systemRed)
        static let warning = Color(uiColor: .systemOrange)
        static let quietInformation = Color.secondary
        static let onAccent = Color.white
        static let fixedLightBackground = Color.white
        static let pageBackground =
            Color(uiColor: .systemGroupedBackground)
        static let cardBackground =
            Color(uiColor: .secondarySystemGroupedBackground)
        static let controlBackground =
            Color(uiColor: .secondarySystemFill)
        static let hairline = Color(uiColor: .separator).opacity(0.24)
    }

    enum Motion {

        static let quick: Double = 0.16
        static let standard: Double = 0.24
        static let deliberate: Double = 0.32
    }

    enum Layout {

        static let cardCornerRadius: CGFloat = 24
        static let cardPadding: CGFloat = 24
        static let compactCardCornerRadius: CGFloat = 18
        static let compactCardPadding: CGFloat = 14
        static let compactInnerCardCornerRadius: CGFloat = 18
        static let compactInnerCardPadding: CGFloat = 12
        static let dividerInset: CGFloat = 12
        static let compactTrailingControlWidth: CGFloat = 128
        static let configurationSheetCompactHeight: CGFloat = 390
        static let configurationSheetContentFraction: CGFloat = 0.58
        static let brandLineSpacing: CGFloat = 3
        static let compactPrimaryActionWidth: CGFloat = 184
        static let compactPrimaryActionHeight: CGFloat = 40
        static let compactPrimaryActionCornerRadius: CGFloat = 12
        static let compactPrimaryActionTintOpacity: Double = 0.84
        static let compactPrimaryActionShadowOpacity: Double = 0.08
    }

    enum Share {

        static let contentTopInset: CGFloat = 28
        static let contentActionSpacing: CGFloat = 12
        static let bottomActionInset: CGFloat = 24
        static let primaryActionHitTarget: CGFloat = 44
        static let checklistRowSpacing: CGFloat = 10
        static let checklistIconContainerWidth: CGFloat = 20
        static let checklistIconSize: CGFloat = 16
    }

    enum Typography {

        static let hero = MemoMarkTypographyToken(
            size: 28,
            uiWeight: .bold,
            uiTextStyle: .largeTitle,
            swiftUIWeight: .bold,
            swiftUITextStyle: .title2
        )

        static let heroSubtitle = MemoMarkTypographyToken(
            size: 17,
            uiWeight: .regular,
            uiTextStyle: .body,
            swiftUIWeight: .regular,
            swiftUITextStyle: .body
        )

        static let sectionTitle = MemoMarkTypographyToken(
            size: 19,
            uiWeight: .semibold,
            uiTextStyle: .title2,
            swiftUIWeight: .semibold,
            swiftUITextStyle: .title3
        )

        static let value = MemoMarkTypographyToken(
            size: 20,
            uiWeight: .semibold,
            uiTextStyle: .title2,
            swiftUIWeight: .medium,
            swiftUITextStyle: .headline
        )

        static let moduleTitle = MemoMarkTypographyToken(
            size: 17,
            uiWeight: .semibold,
            uiTextStyle: .headline,
            swiftUIWeight: .semibold,
            swiftUITextStyle: .headline
        )

        static let body = MemoMarkTypographyToken(
            size: 16,
            uiWeight: .regular,
            uiTextStyle: .body,
            swiftUIWeight: .regular,
            swiftUITextStyle: .body
        )

        static let detail = MemoMarkTypographyToken(
            size: 15,
            uiWeight: .regular,
            uiTextStyle: .subheadline,
            swiftUIWeight: .regular,
            swiftUITextStyle: .subheadline
        )

        static let secondary = MemoMarkTypographyToken(
            size: 14,
            uiWeight: .regular,
            uiTextStyle: .footnote,
            swiftUIWeight: .regular,
            swiftUITextStyle: .caption
        )

        static let brand = MemoMarkTypographyToken(
            size: 14,
            uiWeight: .medium,
            uiTextStyle: .footnote,
            swiftUIWeight: .medium,
            swiftUITextStyle: .caption
        )

        static let caption = MemoMarkTypographyToken(
            size: 13,
            uiWeight: .regular,
            uiTextStyle: .caption1,
            swiftUIWeight: .regular,
            swiftUITextStyle: .caption2
        )

        static let button = MemoMarkTypographyToken(
            size: 17,
            uiWeight: .semibold,
            uiTextStyle: .body,
            swiftUIWeight: .semibold,
            swiftUITextStyle: .body
        )
    }
}
#endif
