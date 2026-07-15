#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct IOSCompactEntryListGroup<Content: View>: View {

    @ViewBuilder var content: Content

    init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.cornerRadius,
                style: .continuous
            )
            .fill(ConfigurationUI.panelBackground)
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.cornerRadius,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
    }
}

struct IOSCompactEntryDisclosureRow<Content: View>: View {

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    let title: String
    let subtitle: String
    let value: String
    let detail: String?
    let systemImage: String
    let showsDivider: Bool

    @Binding var isExpanded: Bool
    @ViewBuilder var content: Content

    init(
        title: String,
        subtitle: String,
        value: String,
        detail: String? = nil,
        systemImage: String,
        showsDivider: Bool = true,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.detail = detail
        self.systemImage = systemImage
        self.showsDivider = showsDivider
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
                HStack(alignment: .center, spacing: 12) {
                    leadingIcon

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

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(value)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        if let detail,
                           !detail.isEmpty {
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(
                            isExpanded
                            ? Color.accentColor
                            : Color.secondary.opacity(0.55)
                        )
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
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
                Rectangle()
                    .fill(ConfigurationUI.faintHairline)
                    .frame(height: 0.5)
                    .padding(.leading, 50)

                VStack(alignment: .leading, spacing: 12) {
                    content
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
            }

            if showsDivider {
                Rectangle()
                    .fill(ConfigurationUI.faintHairline)
                    .frame(height: 0.5)
                    .padding(.leading, 50)
            }
        }
    }

    private var leadingIcon: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 10,
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
