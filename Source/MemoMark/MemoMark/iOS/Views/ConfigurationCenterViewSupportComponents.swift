#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import UIKit

struct ConfigurationPageHeader: View {

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    let title: String
    let subtitle: String?

    init(
        _ title: String,
        subtitle: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(localized(title))
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)

            if let subtitle,
               !subtitle.isEmpty {
                Text(localized(subtitle))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(
            minHeight: subtitle?.isEmpty == false ? 52 : 31,
            alignment: .topLeading
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func localized(_ value: String) -> String {
        MemoMarkLanguage.interfaceStored.localized(
            key: value,
            fallback: value
        )
    }
}

struct ConfigurationSheetSubtitle: View {

    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(localized(text))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, ConfigurationUI.contentColumnPadding)
            .padding(.top, ConfigurationUI.sheetSubtitleTopPadding)
            .padding(.bottom, ConfigurationUI.sheetSubtitleBottomPadding)
            .background(ConfigurationUI.appBackground)
    }

    private func localized(_ value: String) -> String {
        MemoMarkLanguage.interfaceStored.localized(
            key: value,
            fallback: value
        )
    }
}

struct CompactSelectionLabel: View {

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(
                    dynamicTypeSize.isAccessibilitySize ? 1 : 0.76
                )
                .allowsTightening(!dynamicTypeSize.isAccessibilitySize)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)

            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.smallCornerRadius,
                style: .continuous
            )
            .fill(ConfigurationUI.controlBackground)
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.smallCornerRadius,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
        .frame(minHeight: ConfigurationUI.minimumInteractiveHeight)
        .contentShape(Rectangle())
    }
}

enum ConfigurationSectionCardMetrics {

    static let cardHeaderMinimumHeight: CGFloat = 28
    static let compactConfigurationRowMinimumHeight: CGFloat = 64
    static let cardHeaderContentSpacing: CGFloat = 6
    static let cardVerticalPadding: CGFloat = 10
    static let headerContentSpacing: CGFloat = 10
    static let sectionSpacing: CGFloat = 12
}

/// Displays the value that is currently effective for one Configuration Center row.
/// It is intentionally plain; selection emphasis belongs to the control that
/// actually changes the value.
struct ConfigurationResultLabel: View {

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    let title: String
    let accessibilityLabel: String
    let accessibilityValue: String

    var body: some View {
        Text(localized(title))
            .font(.caption.weight(.medium))
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
            .minimumScaleFactor(0.76)
            .allowsTightening(true)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(.secondary)
            .frame(
                minHeight: ConfigurationUI.minimumInteractiveHeight,
                alignment: .trailing
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(localized(accessibilityLabel))
            .accessibilityValue(localized(accessibilityValue))
    }

    private func localized(_ value: String) -> String {
        MemoMarkLanguage.interfaceStored.localized(
            key: value,
            fallback: value
        )
    }
}

/// Compact, reusable header row for Configuration Center sections.
/// It keeps the regular-size layout short while allowing a vertical fallback
/// at accessibility sizes so titles and effective values are never clipped.
struct ConfigurationCompactSectionRow: View {

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    let title: String
    let subtitle: String
    let resultTitle: String
    let resultAccessibilityLabel: String
    let resultAccessibilityValue: String
    let isExpanded: Bool
    let expandedAccessibilityLabel: String
    let collapsedAccessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 8) {
                        heading

                        HStack(spacing: 8) {
                            resultLabel
                            Spacer(minLength: 0)
                            disclosureIndicator
                        }
                    }
                } else {
                    HStack(alignment: .center, spacing: 8) {
                        heading
                            .layoutPriority(1)

                        Spacer(minLength: 0)

                        resultLabel
                        disclosureIndicator
                    }
                }
            }
            .frame(
                maxWidth: .infinity,
                minHeight:
                    ConfigurationSectionCardMetrics.compactConfigurationRowMinimumHeight,
                alignment: .leading
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(localized(resultAccessibilityLabel))
        .accessibilityValue(
            localized(resultAccessibilityValue)
                + ", "
                + localized(isExpanded ? "已展开" : "已折叠")
        )
        .accessibilityHint(
            localized(
                isExpanded
                    ? expandedAccessibilityLabel
                    : collapsedAccessibilityLabel
            )
        )
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(localized(title))
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .allowsTightening(true)
                .accessibilityAddTraits(.isHeader)

            Text(localized(subtitle))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var resultLabel: some View {
        ConfigurationResultLabel(
            title: resultTitle,
            accessibilityLabel: resultAccessibilityLabel,
            accessibilityValue: resultAccessibilityValue
        )
        .layoutPriority(0)
    }

    private var disclosureIndicator: some View {
        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(
                width: ConfigurationUI.minimumInteractiveHeight,
                height: ConfigurationUI.minimumInteractiveHeight
            )
            .accessibilityHidden(true)
    }

    private func localized(_ value: String) -> String {
        MemoMarkLanguage.interfaceStored.localized(
            key: value,
            fallback: value
        )
    }
}

enum CompactInformationRowMetrics {

    static let iconSize = ConfigurationUI.compactIconSize
    static let iconCornerRadius = ConfigurationUI.compactIconCornerRadius
    static let horizontalPadding: CGFloat = ConfigurationUI.innerPanelPadding
    static let verticalPadding = ConfigurationUI.compactRowVerticalPadding
    static let contentSpacing: CGFloat = 12
}

struct ConfigurationSectionHeading: View {

    let title: String
    let subtitle: String?
    let systemImage: String?
    let tint: Color

    init(
        _ title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        tint: Color = .accentColor
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if let systemImage {
                CompactHeadingIcon(
                    systemImage: systemImage,
                    tint: tint
                )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                if let subtitle,
                   !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ConfigurationCardChrome: ViewModifier {

    @Environment(\.colorSchemeContrast)
    private var accessibilityContrast

    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let shadowY: CGFloat
    let background: Color

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
                .fill(background)
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
                .stroke(cardHairline)
            )
            .shadow(
                color: ConfigurationUI.cardShadow,
                radius: shadowRadius,
                y: shadowY
            )
    }

    private var cardHairline: Color {
        accessibilityContrast == .increased
            ? ConfigurationUI.hairline
            : ConfigurationUI.faintHairline
    }
}

struct ConfigurationSheetPanelChrome: ViewModifier {

    @Environment(\.colorSchemeContrast)
    private var accessibilityContrast

    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
                .fill(ConfigurationUI.panelBackground)
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
                .stroke(panelHairline)
            )
    }

    private var panelHairline: Color {
        accessibilityContrast == .increased
            ? ConfigurationUI.hairline
            : ConfigurationUI.faintHairline
    }
}

extension View {

    func v1CardChrome(
        cornerRadius: CGFloat = ConfigurationUI.cardCornerRadius,
        shadowRadius: CGFloat = 4,
        shadowY: CGFloat = 1,
        background: Color = ConfigurationUI.panelBackground
    ) -> some View {
        modifier(
            ConfigurationCardChrome(
                cornerRadius: cornerRadius,
                shadowRadius: shadowRadius,
                shadowY: shadowY,
                background: background
            )
        )
    }

    func v1ConfigurationSheetPanelChrome(
        cornerRadius: CGFloat = ConfigurationUI.sheetPanelCornerRadius
    ) -> some View {
        modifier(
            ConfigurationSheetPanelChrome(
                cornerRadius: cornerRadius
            )
        )
    }
}

enum CompactBottomActionMetrics {

    static let width = MemoMarkDesignTokens.Layout.compactPrimaryActionWidth
    static let height = MemoMarkDesignTokens.Layout.compactPrimaryActionHeight
    static let cornerRadius = MemoMarkDesignTokens.Layout.compactPrimaryActionCornerRadius
}

struct CompactPrimaryActionButtonStyle:
    ButtonStyle {

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @Environment(\.isEnabled)
    private var isEnabled

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .opacity(
                isEnabled
                ? (configuration.isPressed ? 0.78 : 1)
                : 0.56
            )
            .scaleEffect(
                configuration.isPressed && !reduceMotion
                ? 0.97
                : 1
            )
            .animation(
                reduceMotion
                ? nil
                : .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}

extension View {

    func v1CompactBottomPrimaryAction() -> some View {
        self
            .foregroundStyle(MemoMarkDesignTokens.Semantic.onAccent)
            .padding(.horizontal, 14)
            .frame(
                width: CompactBottomActionMetrics.width,
                height: CompactBottomActionMetrics.height
            )
            .background(
                RoundedRectangle(
                    cornerRadius:
                        CompactBottomActionMetrics.cornerRadius,
                    style: .continuous
                )
                .fill(
                    Color.accentColor.opacity(
                        MemoMarkDesignTokens
                            .Layout
                            .compactPrimaryActionTintOpacity
                    )
                )
            )
            .shadow(
                color: Color.accentColor.opacity(
                    MemoMarkDesignTokens
                        .Layout
                        .compactPrimaryActionShadowOpacity
                ),
                radius: MemoMarkDesignTokens
                    .Layout
                    .compactPrimaryActionShadowRadius,
                y: MemoMarkDesignTokens
                    .Layout
                    .compactPrimaryActionShadowOffsetY
            )
    }
}

struct ConfigurationCardSurface<Content: View>: View {

    let title: String
    let systemImage: String?
    let tint: Color
    @ViewBuilder var content: Content

    init(
        title: String,
        systemImage: String? = nil,
        tint: Color = .accentColor,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        ConfigurationCardContainer {
            VStack(alignment: .leading, spacing: 14) {
                if !title.isEmpty {
                    HStack(spacing: 10) {
                        if let systemImage {
                            CompactHeadingIcon(
                                systemImage: systemImage,
                                tint: tint
                            )
                        }

                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Spacer(minLength: 0)
                    }
                }

                content
            }
        }
    }
}

struct CompactHeadingIcon: View {

    let systemImage: String
    let tint: Color

    var body: some View {
        Image(systemName: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .frame(
                width: CompactInformationRowMetrics.iconSize,
                height: CompactInformationRowMetrics.iconSize
            )
            .background(
                RoundedRectangle(
                    cornerRadius:
                        CompactInformationRowMetrics.iconCornerRadius,
                    style: .continuous
                )
                .fill(tint.opacity(0.11))
            )
            .accessibilityHidden(true)
    }
}

struct ConfigurationCardContainer<Content: View>: View {

    let background: Color

    @ViewBuilder
    let content: Content

    init(
        background: Color = ConfigurationUI.panelBackground,
        @ViewBuilder content: () -> Content
    ) {
        self.background = background
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(ConfigurationUI.cardPadding)
            .v1CardChrome(background: background)
    }
}

struct ConfigurationTitledSectionCard<
    TrailingAccessory: View,
    Content: View
>: View {

    let title: String
    let subtitle: String?

    @ViewBuilder
    let trailingAccessory: TrailingAccessory

    @ViewBuilder
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailingAccessory: () -> TrailingAccessory,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailingAccessory = trailingAccessory()
        self.content = content()
    }

    var body: some View {
        ConfigurationTitledSectionSurface(
            title: title,
            subtitle: subtitle,
            trailingAccessory: { trailingAccessory },
            content: { content }
        )
        .padding(.horizontal, 14)
        .padding(.vertical, ConfigurationSectionCardMetrics.cardVerticalPadding)
        .v1CardChrome()
    }
}

struct ConfigurationTitledSectionSurface<
    TrailingAccessory: View,
    Content: View
>: View {

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    let title: String
    let subtitle: String?

    @ViewBuilder
    let trailingAccessory: TrailingAccessory

    @ViewBuilder
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailingAccessory: () -> TrailingAccessory,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailingAccessory = trailingAccessory()
        self.content = content()
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: ConfigurationSectionCardMetrics.cardHeaderContentSpacing
        ) {
            HStack(alignment: .center, spacing: 12) {
                titleGroup

                Spacer(minLength: 0)

                trailingAccessory
            }
            .frame(
                minHeight:
                    ConfigurationSectionCardMetrics.cardHeaderMinimumHeight
            )

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var titleGroup: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 3) {
                titleText
                subtitleText
            }
        } else {
            HStack(alignment: .center, spacing: 8) {
                titleText
                subtitleText
            }
        }
    }

    private var titleText: some View {
        Text(localized(title))
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private var subtitleText: some View {
        if let subtitle,
           !subtitle.isEmpty {
            Text(localized(subtitle))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func localized(_ value: String) -> String {
        MemoMarkLanguage.interfaceStored.localized(
            key: value,
            fallback: value
        )
    }
}

extension ConfigurationTitledSectionSurface where TrailingAccessory == EmptyView {

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            trailingAccessory: { EmptyView() },
            content: content
        )
    }
}

extension View {

    func v1SectionSurfaceLayout() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
    }
}

struct ConfigurationCardHeaderIconButton: View {

    let systemImage: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(
                            Color(
                                uiColor: .secondarySystemFill
                            )
                        )
                )
                .overlay(
                    Circle()
                        .stroke(ConfigurationUI.faintHairline)
                )
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Keep the interactive region on the Button itself. Relying only on
        // the label's frame can produce a zero-sized hit target when this
        // accessory is hosted in a lazily materialized section header.
        .frame(width: 44, height: 44)
        .accessibilityLabel(accessibilityLabel)
    }
}

extension ConfigurationTitledSectionCard where TrailingAccessory == EmptyView {

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            trailingAccessory: { EmptyView() },
            content: content
        )
    }
}

#endif
