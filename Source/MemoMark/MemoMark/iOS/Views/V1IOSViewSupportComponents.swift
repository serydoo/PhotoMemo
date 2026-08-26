#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import UIKit

struct V1PageHeader: View {

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

struct V1ConfigurationSheetSubtitle: View {

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

struct V1CompactSelectionLabel: View {

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

enum V1SectionCardMetrics {

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
struct V1ConfigurationResultLabel: View {

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
struct V1ConfigurationCompactSectionRow: View {

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
                    V1SectionCardMetrics.compactConfigurationRowMinimumHeight,
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
        V1ConfigurationResultLabel(
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

enum V1CompactInformationRowMetrics {

    static let iconSize = ConfigurationUI.compactIconSize
    static let iconCornerRadius = ConfigurationUI.compactIconCornerRadius
    static let horizontalPadding: CGFloat = ConfigurationUI.innerPanelPadding
    static let verticalPadding = ConfigurationUI.compactRowVerticalPadding
    static let contentSpacing: CGFloat = 12
}

struct V1SectionHeading: View {

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
                V1CompactHeadingIcon(
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

struct V1CardChrome: ViewModifier {

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

struct V1ConfigurationSheetPanelChrome: ViewModifier {

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
            V1CardChrome(
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
            V1ConfigurationSheetPanelChrome(
                cornerRadius: cornerRadius
            )
        )
    }
}

enum V1CompactBottomActionMetrics {

    static let width = MemoMarkDesignTokens.Layout.compactPrimaryActionWidth
    static let height = MemoMarkDesignTokens.Layout.compactPrimaryActionHeight
    static let cornerRadius = MemoMarkDesignTokens.Layout.compactPrimaryActionCornerRadius
}

struct V1CompactPrimaryActionButtonStyle:
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
                width: V1CompactBottomActionMetrics.width,
                height: V1CompactBottomActionMetrics.height
            )
            .background(
                RoundedRectangle(
                    cornerRadius:
                        V1CompactBottomActionMetrics.cornerRadius,
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

struct V1CardSurface<Content: View>: View {

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
        V1ConfigurationCardContainer {
            VStack(alignment: .leading, spacing: 14) {
                if !title.isEmpty {
                    HStack(spacing: 10) {
                        if let systemImage {
                            V1CompactHeadingIcon(
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

struct V1CompactHeadingIcon: View {

    let systemImage: String
    let tint: Color

    var body: some View {
        Image(systemName: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .frame(
                width: V1CompactInformationRowMetrics.iconSize,
                height: V1CompactInformationRowMetrics.iconSize
            )
            .background(
                RoundedRectangle(
                    cornerRadius:
                        V1CompactInformationRowMetrics.iconCornerRadius,
                    style: .continuous
                )
                .fill(tint.opacity(0.11))
            )
            .accessibilityHidden(true)
    }
}

struct V1ConfigurationCardContainer<Content: View>: View {

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

struct V1TitledSectionCard<
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
        V1TitledSectionSurface(
            title: title,
            subtitle: subtitle,
            trailingAccessory: { trailingAccessory },
            content: { content }
        )
        .padding(.horizontal, 14)
        .padding(.vertical, V1SectionCardMetrics.cardVerticalPadding)
        .v1CardChrome()
    }
}

struct V1TitledSectionSurface<
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
            spacing: V1SectionCardMetrics.cardHeaderContentSpacing
        ) {
            HStack(alignment: .center, spacing: 12) {
                titleGroup

                Spacer(minLength: 0)

                trailingAccessory
            }
            .frame(
                minHeight:
                    V1SectionCardMetrics.cardHeaderMinimumHeight
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

extension V1TitledSectionSurface where TrailingAccessory == EmptyView {

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

struct V1CardHeaderIconButton: View {

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
        .accessibilityLabel(accessibilityLabel)
    }
}

extension V1TitledSectionCard where TrailingAccessory == EmptyView {

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

struct V1PreviewCard: View {

    let presentationStyle: RecordCardPresentationStyle
    let logoMode: V1LogoMode
    let customLogoImagePath: String?
    let subjectAvatarLogoImagePath: String?
    let regionText: String
    let timeText: String
    let contextText: String
    let memoryText: String

    @ViewBuilder
    var body: some View {
        previewSurface
            .clipShape(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.cornerRadius,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.cornerRadius,
                    style: .continuous
                )
                    .stroke(ConfigurationUI.faintHairline)
            )
            .shadow(
                color: ConfigurationUI.cardShadow,
                radius: 8,
                y: 3
            )
    }

    @ViewBuilder
    private var previewSurface: some View {
        switch presentationStyle {
        case .classicWhite:
            Color.clear
                .aspectRatio(compactPreviewAspectRatio, contentMode: .fit)
                .overlay {
                    GeometryReader { proxy in
                        compactPreviewCard(size: proxy.size)
                    }
                }
        case .minimal:
            Color.clear
                .aspectRatio(
                    1 / MinimalCardLayoutSpecification
                        .compactPreview.imageSliceHeightToWidth,
                    contentMode: .fit
                )
                .overlay {
                    GeometryReader { proxy in
                        minimalPreviewCard(size: proxy.size)
                    }
                }
        }
    }

    private func minimalPreviewCard(size: CGSize) -> some View {
        let layout = MinimalRenderer.layout(for: .landscape)
        let barHeight = size.width * layout.barHeightToImageWidth

        return ZStack(alignment: .bottomTrailing) {
            minimalLandscapeSlice(
                width: size.width,
                height: size.height
            )
            .frame(
                width: size.width,
                height: size.height
            )

            minimalPreviewInformationBar(
                width: size.width,
                height: barHeight,
                layout: layout
            )
            .padding(
                .trailing,
                size.width * (1 - layout.trailingAnchorX)
            )
            .padding(
                .bottom,
                size.width * layout.overlayBottomInsetToImageWidth
            )
        }
        .frame(
            width: size.width,
            height: size.height
        )
        .clipped()
    }

    private func minimalPreviewInformationBar(
        width: CGFloat,
        height: CGFloat,
        layout: MinimalRenderer.Layout
    ) -> some View {
        let capsuleHeight = height * layout.capsuleHeightToBarHeight
        let avatarSize = min(
            height * layout.avatarSizeToBarHeight,
            capsuleHeight
        )
        return HStack(spacing: height * layout.avatarTextSpacingToBarHeight) {
            minimalLogo(
                size: avatarSize
            )
            .frame(
                width: height * layout.avatarAreaWidthToBarHeight,
                height: capsuleHeight,
                alignment: .leading
            )

            Text(regionText.isEmpty ? " " : regionText)
                .font(
                    .system(
                        size: height * layout.textSizeToBarHeight,
                        weight: .medium
                    )
                )
                .monospacedDigit()
                .foregroundStyle(MinimalRenderer.foreground)
                .lineLimit(layout.textLineLimit)
                .allowsTightening(true)
                .minimumScaleFactor(0.78)
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding(
            .trailing,
            height * layout.capsuleHorizontalPaddingToBarHeight
        )
        .padding(
            .leading,
            height * layout.avatarLeadingInsetToBarHeight
        )
        .padding(
            .vertical,
            height * layout.capsuleVerticalPaddingToBarHeight
        )
        .background {
            RoundedRectangle(
                cornerRadius: capsuleHeight / 2,
                style: .continuous
            )
            .fill(MinimalRenderer.capsuleSurface)
            .overlay {
                RoundedRectangle(
                    cornerRadius: capsuleHeight / 2,
                    style: .continuous
                )
                .stroke(
                    MinimalRenderer.hairline,
                    lineWidth: max(1, height * 0.006)
                )
            }
        }
        .frame(
            maxWidth: width * layout.maximumModuleWidth,
            minHeight: capsuleHeight,
            alignment: .trailing
        )
    }

    private func minimalLandscapeSlice(
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.73, green: 0.84, blue: 0.88),
                    Color(red: 0.93, green: 0.84, blue: 0.69)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(Color.white.opacity(0.68))
                .frame(width: height * 0.34)
                .position(
                    x: width * 0.78,
                    y: height * 0.26
                )

            Path { path in
                path.move(to: CGPoint(x: 0, y: height * 0.80))
                path.addLine(to: CGPoint(x: width * 0.22, y: height * 0.30))
                path.addLine(to: CGPoint(x: width * 0.43, y: height * 0.79))
                path.addLine(to: CGPoint(x: width * 0.63, y: height * 0.46))
                path.addLine(to: CGPoint(x: width, y: height * 0.82))
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: 0, y: height))
                path.closeSubpath()
            }
            .fill(
                Color(
                    red: 0.38,
                    green: 0.48,
                    blue: 0.45
                )
                .opacity(0.88)
            )

            LinearGradient(
                colors: [
                    Color(red: 0.42, green: 0.56, blue: 0.50),
                    Color(red: 0.26, green: 0.38, blue: 0.35)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: height * 0.31)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(width: width, height: height)
        .clipped()
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func minimalLogo(size: CGFloat) -> some View {
        switch logoMode {
        case .appleMini:
            Image(systemName: "apple.logo")
                .font(.system(size: size, weight: .semibold))
        case .customUpload:
            if let customLogoImagePath,
               let image = UIImage(contentsOfFile: customLogoImagePath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "apple.logo")
                    .font(.system(size: size * 0.82, weight: .semibold))
            }
        case .subjectAvatar:
            if let subjectAvatarLogoImagePath,
               let image = UIImage(contentsOfFile: subjectAvatarLogoImagePath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "apple.logo")
                    .font(.system(size: size * 0.82, weight: .semibold))
            }
        }
    }

    private var compactSpec: CompactInformationBarSpec {
        RendererConstants.CompactInformationBar.landscape
    }

    private var compactPreviewAspectRatio: CGFloat {
        1 / compactSpec.barHeightToWidth
    }

    private func compactPreviewCard(size: CGSize) -> some View {
        let barHeight =
            size.width
            * compactSpec.barHeightToWidth

        return compactInformationBar(
            width: size.width,
            height: barHeight
        )
        .frame(height: barHeight)
    }

    private func compactInformationBar(
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        let spec = compactSpec

        return ZStack(alignment: .topLeading) {
            RendererConstants.CompactInformationBar.background

            compactTextPair(
                primary: regionText,
                secondary: timeText,
                spec: spec,
                barHeight: height,
                emphasizesPrimary: false,
                primaryMinimumScaleFactor: 0.94,
                secondaryMinimumScaleFactor: 0.90
            )
            .frame(
                width:
                    width
                    * compactPreviewLeftTextWidth(
                        spec: spec
                    ),
                height: height * 0.62,
                alignment: .leading
            )
            .position(
                x:
                    width * spec.leftX
                    + width
                    * compactPreviewLeftTextWidth(
                        spec: spec
                    ) / 2,
                y: height * spec.contentCenterY
            )

            compactLogo(
                spec: spec,
                barHeight: height
            )
            .position(
                x: width * spec.logoCenterX,
                y: height * spec.contentCenterY
            )

            Rectangle()
                .fill(RendererConstants.CompactInformationBar.divider)
                .frame(
                    width:
                        min(
                            max(
                                height
                                * spec.dividerWidthToBarHeight,
                                2
                            ),
                            8
                        ),
                    height: height * spec.dividerHeight
                )
                .position(
                    x: width * spec.dividerCenterX,
                    y:
                        height * spec.dividerTopY
                        + height * spec.dividerHeight / 2
                )

            compactTextPair(
                primary: formattedCaptureSummaryText,
                secondary: memoryText,
                spec: spec,
                barHeight: height,
                primaryFontToBarHeight:
                    spec.rightPrimaryFontToBarHeight,
                primaryMinimumScaleFactor: 0.72,
                secondaryMinimumScaleFactor: 0.82
            )
            .frame(
                width: width * spec.rightWidth,
                height: height * 0.62,
                alignment: .leading
            )
            .position(
                x:
                    width * spec.rightX
                    + width * spec.rightWidth / 2,
                y: height * spec.contentCenterY
            )
        }
    }

    private func compactPreviewLeftTextWidth(
        spec: CompactInformationBarSpec
    ) -> CGFloat {

        min(
            max(
                spec.leftWidth,
                0.46
            ),
            spec.logoCenterX
            - spec.leftX
            - 0.10
        )
    }

    private func compactTextPair(
        primary: String,
        secondary: String,
        spec: CompactInformationBarSpec,
        barHeight: CGFloat,
        emphasizesPrimary: Bool = false,
        primaryFontToBarHeight: CGFloat? = nil,
        primaryMinimumScaleFactor: CGFloat = 0.84,
        secondaryMinimumScaleFactor: CGFloat = 0.84
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: barHeight * spec.groupSpacingToBarHeight
        ) {
            compactTextLine(
                primary,
                fontSize:
                    barHeight
                    * (
                        primaryFontToBarHeight
                        ?? spec.primaryFontToBarHeight
                    )
                    * (emphasizesPrimary ? 1.08 : 1),
                weight: emphasizesPrimary ? .bold : .semibold,
                tracking: spec.primaryTracking,
                color:
                    emphasizesPrimary
                    ? Color.black.opacity(0.98)
                    :
                    RendererConstants
                    .CompactInformationBar
                    .primaryText,
                minimumScaleFactor: primaryMinimumScaleFactor
            )
            .offset(
                y:
                    barHeight
                    * spec.primaryYOffsetToBarHeight
            )

            compactTextLine(
                secondary,
                fontSize:
                    barHeight
                    * spec.secondaryFontToBarHeight,
                weight: .regular,
                tracking: spec.secondaryTracking,
                color:
                    emphasizesPrimary
                    ? Color.black.opacity(0.70)
                    :
                    RendererConstants
                    .CompactInformationBar
                    .secondaryText,
                minimumScaleFactor: secondaryMinimumScaleFactor
            )
            .offset(
                y:
                    barHeight
                    * spec.secondaryYOffsetToBarHeight
            )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .center
        )
    }

    private func compactTextLine(
        _ value: String,
        fontSize: CGFloat,
        weight: Font.Weight,
        tracking: CGFloat,
        color: Color,
        minimumScaleFactor: CGFloat
    ) -> some View {
        Text(value.isEmpty ? " " : value)
            .font(
                .system(
                    size: fontSize,
                    weight: weight
                )
            )
            .kerning(tracking)
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(minimumScaleFactor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func compactLogo(
        spec: CompactInformationBarSpec,
        barHeight: CGFloat
    ) -> some View {
        let logoSize =
            barHeight
            * spec.logoSizeToBarHeight

        return Group {
            switch logoMode {
            case .appleMini:
                Image(systemName: "apple.logo")
                    .font(.system(size: logoSize, weight: .semibold))
            case .customUpload:
                if let customLogoImagePath,
                   let image = UIImage(contentsOfFile: customLogoImagePath) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width:
                                logoSize
                                * spec.customLogoScale,
                            height:
                                logoSize
                                * spec.customLogoScale
                        )
                        .clipShape(Circle())
                } else {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: logoSize * 0.78, weight: .semibold))
                }
            case .subjectAvatar:
                if let subjectAvatarLogoImagePath,
                   let image = UIImage(contentsOfFile: subjectAvatarLogoImagePath) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width:
                                logoSize
                                * spec.customLogoScale,
                            height:
                                logoSize
                                * spec.customLogoScale
                        )
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: logoSize * 0.82, weight: .semibold))
                }
            }
        }
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(RendererConstants.CompactInformationBar.logoTint)
        .frame(width: logoSize * 1.25, height: logoSize * 1.25)
    }

    private var formattedCaptureSummaryText: String {
        let facts =
            contextText
            .split(separator: " ")
            .map(String.init)
            .prefix(RendererConstants.CaptureSummary.allowedFactCount)

        guard !facts.isEmpty else {
            return contextText
        }

        return facts.joined(separator: " ")
    }
}

struct V1RegionEditorCard: View {

    let region: CardRegion
    let showsDivider: Bool
    let draft: V1EditorDraft
    let onFocus: () -> Void
    let onFocusTextItem: (V1ContentItem) -> Void
    let onFocusTrailingText: () -> Void
    let onUpdateTextItem: (V1ContentItem, String) -> Void
    let onPrependText: (String) -> Void
    let onAppendText: (String) -> Void
    let onRemoveItem: (V1ContentItem) -> Void
    let onRemovePreviousComposedItem: (UUID) -> Bool
    let insertionMarkerID: UUID?
    let showsInsertionMarkerAtEnd: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(region.editorTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle = region.editorSubtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }

            compositionField
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, ConfigurationUI.sheetPanelPadding)
        .padding(.vertical, 5)
        .overlay(alignment: .bottom) {
            if showsDivider {
                V1HorizontalDivider()
                    .padding(.horizontal, ConfigurationUI.sheetPanelPadding)
            }
        }
    }

    private var compositionField: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 1) {
                ForEach(draft.items) { item in
                    if item.id == insertionMarkerID,
                       insertionAnchorBelongsBefore(item) {
                        insertionAnchor
                    }

                    switch item.kind {
                    case .text:
                        editableTextField(item)

                    case .token,
                         .separator,
                         .lineBreak:
                        moduleChip(item)
                    }

                    if item.id == insertionMarkerID,
                       !insertionAnchorBelongsBefore(item) {
                        insertionAnchor
                    }
                }

                if draft.items.last?.kind != .text {
                    if showsInsertionMarkerAtEnd {
                        insertionAnchor
                    }
                    transientTextField(
                        placeholder: "",
                        minWidth: 58,
                        onChange: onAppendText,
                        onFocus: onFocusTrailingText
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .frame(minHeight: 42)
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded { _ in
                onFocus()
            }
        )
        .background(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.smallCornerRadius,
                style: .continuous
            )
            .fill(Color(uiColor: .systemBackground))
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.smallCornerRadius,
                style: .continuous
            )
            .stroke(Color.primary.opacity(0.08))
        )
    }

    private func moduleChip(
        _ item: V1ContentItem
    ) -> some View {
        HStack(spacing: V1EditorCapsuleMetrics.contentSpacing) {
            Image(systemName: item.editorModuleSystemImage)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)

            Text(item.editorModuleTitle)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .font(.footnote.weight(.semibold))
        .padding(.horizontal, 6)
        .frame(height: V1EditorCapsuleMetrics.height)
        .background(
            RoundedRectangle(
                cornerRadius: V1EditorCapsuleMetrics.cornerRadius,
                style: .continuous
            )
            .fill(
                Color(
                    uiColor: item.isUnresolvedModule
                        ? .systemOrange
                        : .systemBlue
                )
                .opacity(0.12)
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: V1EditorCapsuleMetrics.cornerRadius,
                style: .continuous
            )
            .stroke(
                (item.isUnresolvedModule
                    ? Color.orange
                    : Color.accentColor
                )
                .opacity(0.22),
                lineWidth: V1EditorCapsuleMetrics.borderWidth
            )
        )
    }

    private var insertionAnchor: some View {
        Capsule(style: .continuous)
            .fill(Color.primary.opacity(0.42))
            .frame(width: 2, height: 20)
            .padding(.horizontal, 2)
            .accessibilityLabel("模块插入位置")
    }

    private func insertionAnchorBelongsBefore(
        _ item: V1ContentItem
    ) -> Bool {
        item.kind == .text
            && item.value
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
    }

    private func editableTextField(
        _ item: V1ContentItem
    ) -> some View {
        V1InlineTextField(
            text: Binding(
                get: { item.value },
                set: {
                    onUpdateTextItem(item, $0)
                }
            ),
            placeholder: "",
            minWidth: textFieldWidth(for: item.value),
            onFocus: {
                onFocusTextItem(item)
            },
            onBackspaceAtBeginning: {
                onRemovePreviousComposedItem(item.id)
            }
        )
        .frame(minWidth: textFieldWidth(for: item.value))
    }

    private func transientTextField(
        placeholder: String,
        minWidth: CGFloat,
        onChange: @escaping (String) -> Void,
        onFocus: @escaping () -> Void
    ) -> some View {
        V1InlineTextField(
            text: Binding(
                get: { "" },
                set: onChange
            ),
            placeholder: placeholder,
            minWidth: minWidth,
            onFocus: onFocus,
            onBackspaceAtBeginning: { false }
        )
        .frame(minWidth: minWidth)
    }

    private func textFieldWidth(
        for value: String
    ) -> CGFloat {
        let trimmed =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
            return 52
        }

        return min(
            max(CGFloat(trimmed.count) * 18, 42),
            180
        )
    }
}

struct V1SlotATextKitEditor: View {
    let draft: V1EditorDraft
    @Binding var pendingInsertion: V1ContentItem?
    let onFocus: () -> Void
    let onDraftChange: (V1EditorDraft) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(CardRegion.slotA.displayTitle)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)

            V1SlotATextView(
                draft: draft,
                pendingInsertion: $pendingInsertion,
                onFocus: onFocus,
                onDraftChange: onDraftChange
            )
            .frame(minHeight: 42, maxHeight: 42)
            .background(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.smallCornerRadius,
                    style: .continuous
                )
                .fill(Color(uiColor: .systemBackground))
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.smallCornerRadius,
                    style: .continuous
                )
                .stroke(Color.primary.opacity(0.08))
            )
        }
        .padding(.horizontal, ConfigurationUI.sheetPanelPadding)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            V1HorizontalDivider()
                .padding(.horizontal, ConfigurationUI.sheetPanelPadding)
        }
    }
}

private struct V1SlotATextView: UIViewRepresentable {
    let draft: V1EditorDraft
    @Binding var pendingInsertion: V1ContentItem?
    let onFocus: () -> Void
    let onDraftChange: (V1EditorDraft) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let storage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer(
            size: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 36)
        )
        container.maximumNumberOfLines = 1
        container.lineBreakMode = .byClipping
        layoutManager.addTextContainer(container)
        storage.addLayoutManager(layoutManager)
        let view = UITextView(frame: .zero, textContainer: container)
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        view.font = .preferredFont(forTextStyle: .subheadline)
        view.adjustsFontForContentSizeCategory = true
        view.textContainerInset = UIEdgeInsets(top: 10, left: 4, bottom: 10, right: 4)
        view.textContainer.lineFragmentPadding = 0
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.isScrollEnabled = true
        view.accessibilityLabel = "左上内容"
        context.coordinator.apply(draft, to: view, restoring: nil)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.parent = self
        if let item = pendingInsertion {
            // Consume the one-shot command before writing the resulting draft
            // back through SwiftUI. Otherwise updateUIView can observe the
            // same pending item again and insert it repeatedly.
            pendingInsertion = nil
            context.coordinator.insert(item, in: view)
            return
        }
        guard view.markedTextRange == nil,
              !context.coordinator.hasSameEditingContent(
                  context.coordinator.projectedDraft(from: view),
                  as: draft
              ) else { return }
        context.coordinator.apply(draft, to: view, restoring: view.selectedRange)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: V1SlotATextView
        private var isApplying = false
        private var savedSelection = NSRange(location: 0, length: 0)

        init(_ parent: V1SlotATextView) { self.parent = parent }

        func textViewDidBeginEditing(_ textView: UITextView) { parent.onFocus() }
        func textViewDidChangeSelection(_ textView: UITextView) { savedSelection = textView.selectedRange }
        func textViewDidChange(_ textView: UITextView) {
            guard !isApplying, textView.markedTextRange == nil else { return }
            parent.onDraftChange(projectedDraft(from: textView))
        }

        func apply(_ draft: V1EditorDraft, to view: UITextView, restoring range: NSRange?) {
            isApplying = true
            let result = NSMutableAttributedString()
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.preferredFont(forTextStyle: .subheadline),
                .foregroundColor: UIColor.label
            ]
            for item in draft.items {
                if item.kind == .text {
                    result.append(NSAttributedString(string: item.value, attributes: attributes))
                } else {
                    let attachment = V1TextKitModuleAttachment(item: item)
                    result.append(NSAttributedString(attachment: attachment))
                }
            }
            view.textStorage.setAttributedString(result)
            let candidate = range ?? savedSelection
            view.selectedRange = NSRange(location: min(candidate.location, result.length), length: 0)
            savedSelection = view.selectedRange
            isApplying = false
        }

        func insert(_ item: V1ContentItem, in view: UITextView) {
            let range = NSIntersectionRange(savedSelection, NSRange(location: 0, length: view.textStorage.length))
            let attachment = V1TextKitModuleAttachment(item: item)
            view.textStorage.replaceCharacters(in: range, with: NSAttributedString(attachment: attachment))
            view.selectedRange = NSRange(location: range.location + 1, length: 0)
            savedSelection = view.selectedRange
            parent.onDraftChange(projectedDraft(from: view))
        }

        func projectedDraft(from view: UITextView) -> V1EditorDraft {
            var items: [V1ContentItem] = []
            let full = NSRange(location: 0, length: view.textStorage.length)
            view.textStorage.enumerateAttributes(in: full) { attributes, range, _ in
                if let attachment = attributes[.attachment] as? V1TextKitModuleAttachment {
                    items.append(attachment.item)
                } else {
                    let text = (view.textStorage.string as NSString).substring(with: range)
                    if !text.isEmpty {
                        if let last = items.last, last.kind == .text {
                            items[items.count - 1].value += text
                            items[items.count - 1].savedValue += text
                        } else {
                            items.append(.text(text))
                        }
                    }
                }
            }
            if items.isEmpty { items = [.text("")] }
            return V1EditorDraft(items: items)
        }

        func hasSameEditingContent(
            _ projected: V1EditorDraft,
            as draft: V1EditorDraft
        ) -> Bool {
            guard projected.items.count == draft.items.count else { return false }
            return zip(projected.items, draft.items).allSatisfy { lhs, rhs in
                lhs.kind == rhs.kind
                    && lhs.value == rhs.value
                    && lhs.savedValue == rhs.savedValue
                    && lhs.title == rhs.title
                    && lhs.systemImage == rhs.systemImage
            }
        }
    }
}

final class V1TextKitModuleAttachment: NSTextAttachment {
    let item: V1ContentItem

    init(item: V1ContentItem) {
        self.item = item
        super.init(data: nil, ofType: nil)
        let font = UIFont.preferredFont(forTextStyle: .footnote)
        let title = item.editorModuleTitle as NSString
        let titleWidth = ceil(title.size(withAttributes: [.font: font]).width)
        let size = CGSize(
            width: min(
                max(
                    titleWidth + V1EditorCapsuleMetrics.titleAdvance,
                    V1EditorCapsuleMetrics.minimumWidth
                ),
                V1EditorCapsuleMetrics.maximumWidth
            ),
            height: V1EditorCapsuleMetrics.height
        )
        let tintColor = item.isUnresolvedModule
            ? UIColor.systemOrange
            : UIColor.systemBlue
        image = UIGraphicsImageRenderer(size: size).image { context in
            tintColor.withAlphaComponent(0.12).setFill()
            UIBezierPath(
                roundedRect: CGRect(origin: .zero, size: size),
                cornerRadius: V1EditorCapsuleMetrics.cornerRadius
            ).fill()
            tintColor.withAlphaComponent(0.22).setStroke()
            let border = UIBezierPath(
                roundedRect: CGRect(
                    x: V1EditorCapsuleMetrics.borderWidth / 2,
                    y: V1EditorCapsuleMetrics.borderWidth / 2,
                    width: size.width - V1EditorCapsuleMetrics.borderWidth,
                    height: size.height - V1EditorCapsuleMetrics.borderWidth
                ),
                cornerRadius: V1EditorCapsuleMetrics.cornerRadius
                    - V1EditorCapsuleMetrics.borderWidth / 2
            )
            border.lineWidth = V1EditorCapsuleMetrics.borderWidth
            border.stroke()
            let contentY = floor(
                (size.height - V1EditorCapsuleMetrics.iconSize) / 2
            )
            UIImage(systemName: item.editorModuleSystemImage)?
                .withTintColor(tintColor, renderingMode: .alwaysOriginal)
                .draw(
                    in: CGRect(
                        x: V1EditorCapsuleMetrics.iconLeading,
                        y: contentY,
                        width: V1EditorCapsuleMetrics.iconSize,
                        height: V1EditorCapsuleMetrics.iconSize
                    )
                )
            let titleY = floor((size.height - font.lineHeight) / 2)
            title.draw(
                at: CGPoint(
                    x: V1EditorCapsuleMetrics.titleLeading,
                    y: titleY
                ),
                withAttributes: [
                    .font: font,
                    .foregroundColor: UIColor.label
                ]
            )
            _ = context
        }
        // Align the capsule's visual center with the subheadline line rather
        // than using a fixed offset that drifts as Dynamic Type changes.
        let editorFont = UIFont.preferredFont(forTextStyle: .subheadline)
        let baselineOffset = floor((editorFont.capHeight - size.height) / 2)
        // Keep a small native-looking insertion gap after the capsule. The
        // transparent trailing advance prevents the caret from visually
        // merging into the capsule while preserving the attachment itself.
        let trailingAdvance: CGFloat = 4
        bounds = CGRect(
            x: 0,
            y: baselineOffset,
            width: size.width + trailingAdvance,
            height: size.height
        )
        accessibilityLabel = item.editorModuleAccessibilityLabel
    }

    required init?(coder: NSCoder) { nil }
}

private struct V1InlineTextField: UIViewRepresentable {

    @Binding var text: String
    let placeholder: String
    let minWidth: CGFloat
    let onFocus: () -> Void
    let onBackspaceAtBeginning: () -> Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> V1InlineTextFieldView {
        let textField = V1InlineTextFieldView()
        textField.onBackspaceAtBeginning = {
            context.coordinator.parent.onBackspaceAtBeginning()
        }
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange(_:)),
            for: .editingChanged
        )
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.editingDidBegin(_:)),
            for: .editingDidBegin
        )
        configure(textField)
        return textField
    }

    func updateUIView(
        _ textField: V1InlineTextFieldView,
        context: Context
    ) {
        context.coordinator.parent = self
        textField.onBackspaceAtBeginning = {
            context.coordinator.parent.onBackspaceAtBeginning()
        }
        configure(textField)
        if textField.text != text {
            textField.text = text
        }
    }

    private func configure(
        _ textField: V1InlineTextFieldView
    ) {
        textField.placeholder = placeholder
        textField.font = UIFont.preferredFont(
            forTextStyle: .subheadline
        )
        textField.adjustsFontForContentSizeCategory = true
        textField.textColor = .label
        textField.tintColor = .tintColor
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.clearButtonMode = .never
        textField.returnKeyType = .default
        textField.setContentHuggingPriority(
            .defaultLow,
            for: .horizontal
        )
        textField.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )
    }

    final class Coordinator: NSObject {
        var parent: V1InlineTextField

        init(_ parent: V1InlineTextField) {
            self.parent = parent
        }

        @objc func textDidChange(_ sender: UITextField) {
            parent.text = sender.text ?? ""
        }

        @objc func editingDidBegin(_ sender: UITextField) {
            parent.onFocus()
        }
    }
}

private final class V1InlineTextFieldView: UITextField {
    var onBackspaceAtBeginning: (() -> Bool)?

    override func deleteBackward() {
        guard let selectedTextRange,
              selectedTextRange.isEmpty,
              offset(
                  from: beginningOfDocument,
                  to: selectedTextRange.start
              ) == 0,
              onBackspaceAtBeginning?() == true
        else {
            super.deleteBackward()
            return
        }
    }
}

private extension CardRegion {
    var systemImage: String {
        switch self {
        case .slotA:
            return "record.circle"
        case .slotB:
            return "calendar"
        case .slotC:
            return "camera.aperture"
        case .slotD:
            return "text.quote"
        case .subject:
            return "person.text.rectangle"
        case .icon:
            return "app.badge"
        case .badge:
            return "seal"
        }
    }
}
#endif
