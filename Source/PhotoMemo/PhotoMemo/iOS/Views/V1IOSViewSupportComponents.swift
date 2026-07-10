#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import UIKit

struct V1PageHeader: View {

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
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

            if let subtitle,
               !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(minHeight: 52, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum V1CompactInformationRowMetrics {

    static let iconSize: CGFloat = 36
    static let iconCornerRadius: CGFloat = 11
    static let horizontalPadding: CGFloat = 12
    static let verticalPadding: CGFloat = 9
    static let contentSpacing: CGFloat = 12
}

struct V1SectionHeading: View {

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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct V1CardChrome: ViewModifier {

    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let shadowY: CGFloat

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
                .stroke(ConfigurationUI.faintHairline)
            )
            .shadow(
                color: ConfigurationUI.cardShadow,
                radius: shadowRadius,
                y: shadowY
            )
    }
}

extension View {

    func v1CardChrome(
        cornerRadius: CGFloat = 18,
        shadowRadius: CGFloat = 8,
        shadowY: CGFloat = 3
    ) -> some View {
        modifier(
            V1CardChrome(
                cornerRadius: cornerRadius,
                shadowRadius: shadowRadius,
                shadowY: shadowY
            )
        )
    }
}

enum V1CompactBottomActionMetrics {

    static let width: CGFloat = 184
    static let height: CGFloat = 40
    static let cornerRadius: CGFloat = 12
}

extension View {

    func v1CompactBottomPrimaryAction() -> some View {
        self
            .foregroundStyle(Color.white)
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
                .fill(Color.accentColor)
            )
            .shadow(
                color: Color.accentColor.opacity(0.20),
                radius: 12,
                y: 5
            )
    }
}

struct V1CardSurface<Content: View>: View {

    let title: String
    @ViewBuilder var content: Content

    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .v1CardChrome()
    }
}

struct V1PreviewCard: View {

    let logoMode: V1LogoMode
    let customLogoImagePath: String?
    let subjectAvatarLogoImagePath: String?
    let regionText: String
    let timeText: String
    let contextText: String
    let memoryText: String

    var body: some View {
        Color.clear
            .aspectRatio(compactPreviewAspectRatio, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    compactPreviewCard(size: proxy.size)
                }
            }
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
            .padding(12)
            .v1CardChrome()
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
                        .scaledToFit()
                        .frame(
                            width:
                                logoSize
                                * spec.customLogoScale,
                            height:
                                logoSize
                                * spec.customLogoScale
                        )
                } else {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: logoSize * 0.78, weight: .semibold))
                }
            case .subjectAvatar:
                if let subjectAvatarLogoImagePath,
                   let image = UIImage(contentsOfFile: subjectAvatarLogoImagePath) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
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
    @Binding var isExpanded: Bool
    let showsDivider: Bool
    let draft: V1EditorDraft
    let resolvedText: String
    let onFocus: () -> Void
    let onFocusTextItem: (V1ContentItem) -> Void
    let onUpdateTextItem: (V1ContentItem, String) -> Void
    let onPrependText: (String) -> Void
    let onAppendText: (String) -> Void
    let onRemoveItem: (V1ContentItem) -> Void
    let onShowModules: () -> Void

    var body: some View {
        IOSCompactEntryDisclosureRow(
            title: region.displayTitle,
            subtitle: region.semanticTitle,
            value: rowValueText,
            detail: rowDetailText,
            systemImage: region.systemImage,
            showsDivider: showsDivider,
            isExpanded: $isExpanded
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Text("模块与文字")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Spacer()

                    Button("添加模块") {
                        onShowModules()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 3) {
                        if draft.items.first?.kind != .text {
                            transientTextField(
                                placeholder: "短语",
                                minWidth: 46,
                                onChange: onPrependText
                            )
                            .onTapGesture(perform: onFocus)
                        }

                        ForEach(draft.items) { item in
                            switch item.kind {
                            case .text:
                                editableTextField(item)

                            case .token,
                                 .separator,
                                 .lineBreak:
                                HStack(spacing: 4) {
                                    Image(systemName: item.systemImage)
                                    Text(item.title)
                                    Button {
                                        onRemoveItem(item)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(.secondary)
                                }
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(Color.accentColor.opacity(0.09))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.accentColor.opacity(0.16))
                                )
                            }
                        }

                        if draft.items.last?.kind != .text {
                            transientTextField(
                                placeholder: "短语",
                                minWidth: 58,
                                onChange: onAppendText
                            )
                            .onTapGesture(perform: onFocus)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                }
                .background(
                    RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                    .fill(Color(uiColor: .secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                    .stroke(Color.primary.opacity(0.08))
                )

                if !resolvedText.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("组合结果")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Text(resolvedText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
    }

    private var rowValueText: String {
        let trimmed =
            resolvedText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty ? "点击编辑" : trimmed
    }

    private var rowDetailText: String {
        let itemCount =
            draft.items.filter { item in
                switch item.kind {
                case .text:
                    return !item.value
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        .isEmpty
                case .token,
                     .separator,
                     .lineBreak:
                    return true
                }
            }
            .count

        return itemCount == 0
            ? "尚未添加内容"
            : "\(itemCount) 个内容项"
    }

    private func editableTextField(
        _ item: V1ContentItem
    ) -> some View {
        TextField(
            "短语",
            text: Binding(
                get: { item.value },
                set: {
                    onUpdateTextItem(
                        item,
                        $0
                    )
                }
            ),
            axis: .horizontal
        )
        .textFieldStyle(.plain)
        .font(.subheadline)
        .frame(minWidth: textFieldWidth(for: item.value))
        .lineLimit(1)
        .onTapGesture {
            onFocusTextItem(item)
        }
    }

    private func transientTextField(
        placeholder: String,
        minWidth: CGFloat,
        onChange: @escaping (String) -> Void
    ) -> some View {
        TextField(
            placeholder,
            text: Binding(
                get: { "" },
                set: onChange
            ),
            axis: .horizontal
        )
        .textFieldStyle(.plain)
        .font(.subheadline)
        .frame(minWidth: minWidth)
        .lineLimit(1)
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
