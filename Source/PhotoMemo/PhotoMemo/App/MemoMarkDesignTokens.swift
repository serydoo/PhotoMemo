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

    enum Layout {

        static let cardCornerRadius: CGFloat = 24
        static let cardPadding: CGFloat = 24
        static let dividerInset: CGFloat = 12
        static let brandLineSpacing: CGFloat = 3
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
