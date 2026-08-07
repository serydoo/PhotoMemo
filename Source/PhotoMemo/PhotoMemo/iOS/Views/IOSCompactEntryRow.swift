#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct IOSCompactEntryListGroup<Content: View>: View {

    let cornerRadius: CGFloat
    @ViewBuilder var content: Content

    init(
        cornerRadius: CGFloat = ConfigurationUI.cornerRadius,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .v1ConfigurationSheetPanelChrome(
            cornerRadius: cornerRadius
        )
    }
}

struct IOSCompactEntryDisclosureRow<Content: View>: View {

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    let title: String
    let subtitle: String
    let value: String
    let detail: String?
    let systemImage: String?
    let showsDivider: Bool
    let usesWideTrailingPreview: Bool

    @Binding var isExpanded: Bool
    @ViewBuilder var content: Content

    init(
        title: String,
        subtitle: String,
        value: String,
        detail: String? = nil,
        systemImage: String?,
        showsDivider: Bool = true,
        usesWideTrailingPreview: Bool = false,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.detail = detail
        self.systemImage = systemImage
        self.showsDivider = showsDivider
        self.usesWideTrailingPreview = usesWideTrailingPreview
        self._isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(
                    reduceMotion
                    ? nil
                    : .interactiveSpring(
                        response: 0.32,
                        dampingFraction: 1,
                        blendDuration: 0.08
                    )
                ) {
                    isExpanded.toggle()
                }
            } label: {
                adaptiveDisclosureLabel
                    .contentShape(Rectangle())
                    .padding(.horizontal, ConfigurationUI.sheetPanelPadding)
                    .padding(.vertical, ConfigurationUI.sheetPanelPadding)
                    .frame(minHeight: ConfigurationUI.minimumInteractiveHeight)
                    .background(
                        isExpanded
                        ? ConfigurationUI.selectedBackground
                        : Color.clear
                    )
            }
            .buttonStyle(.plain)
            .accessibilityValue(
                isExpanded
                ? "已展开"
                : "已折叠"
            )

            if isExpanded {
                V1HorizontalDivider(
                    horizontalInset: ConfigurationUI.sheetDividerInset
                )

                VStack(alignment: .leading, spacing: 12) {
                    content
                }
                .padding(.horizontal, ConfigurationUI.sheetPanelPadding)
                .padding(.vertical, ConfigurationUI.sheetPanelPadding)
            }

            if showsDivider {
                V1HorizontalDivider(
                    horizontalInset: ConfigurationUI.sheetDividerInset
                )
            }
        }
    }

    @ViewBuilder
    private var adaptiveDisclosureLabel: some View {
        if dynamicTypeSize.isAccessibilitySize {
            verticalDisclosureLabel
        } else {
            horizontalDisclosureLabel
        }
    }

    @ViewBuilder
    private var horizontalDisclosureLabel: some View {
        if usesWideTrailingPreview {
            GeometryReader { proxy in
                let availableWidth = proxy.size.width

                horizontalDisclosureLabelContent(
                    maxPreviewWidth:
                        availableWidth * 0.75
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            }
            .frame(
                minHeight:
                    ConfigurationUI.minimumInteractiveHeight
            )
        } else {
            horizontalDisclosureLabelContent(
                maxPreviewWidth: nil
            )
        }
    }

    private func horizontalDisclosureLabelContent(
        maxPreviewWidth: CGFloat?
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            if let systemImage {
                leadingIcon(systemImage)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer(minLength: 12)

            if let maxPreviewWidth {
                trailingValueColumn
                    .frame(
                        maxWidth: maxPreviewWidth,
                        alignment: .trailing
                    )
            } else {
                trailingValueColumn
                    .frame(
                        width:
                            ConfigurationUI
                            .compactTrailingControlWidth,
                        alignment: .trailing
                    )
            }

            disclosureChevron
        }
    }

    private var trailingValueColumn: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(value)
                .font(
                    usesWideTrailingPreview
                    ? .body.weight(.semibold)
                    : .subheadline.weight(.medium)
                )
                .foregroundStyle(.primary)
                .lineLimit(1)
                .multilineTextAlignment(.trailing)
                .truncationMode(.tail)

            if let detail,
               !detail.isEmpty {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .multilineTextAlignment(.trailing)
                    .truncationMode(.tail)
            }
        }
    }

    private var verticalDisclosureLabel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                if let systemImage {
                    leadingIcon(systemImage)
                }

                accessibilityHeadingText

                Spacer(minLength: 8)

                disclosureChevron
            }

            accessibilityValueText
        }
    }

    private var accessibilityHeadingText: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var accessibilityValueText: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if let detail,
               !detail.isEmpty {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var disclosureChevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .rotationEffect(.degrees(isExpanded ? 90 : 0))
    }

    private func leadingIcon(
        _ systemImage: String
    ) -> some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: ConfigurationUI.smallCornerRadius,
                style: .continuous
            )
            .fill(
                isExpanded
                ? Color.accentColor.opacity(0.12)
                : ConfigurationUI.controlBackground
            )

            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        }
        .frame(width: 34, height: 34)
    }
}
#endif
