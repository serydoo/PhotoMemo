#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1IOSHomeInsetGroup<Content: View>: View {

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
            .fill(
                ConfigurationUI
                    .controlBackground
                    .opacity(0.82)
            )
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

struct V1IOSHomeStatusBadge: View {

    enum Tone: Equatable {
        case accent
        case warning
        case neutral

        fileprivate var tint: Color {
            switch self {
            case .accent:
                return .accentColor
            case .warning:
                return .orange
            case .neutral:
                return .secondary
            }
        }

        fileprivate var background: Color {
            switch self {
            case .neutral:
                return ConfigurationUI.controlBackground
            case .accent,
                 .warning:
                return tint.opacity(0.12)
            }
        }
    }

    let text: String
    let tone: Tone

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tone.tint)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(tone.background)
            )
    }
}

struct V1IOSHomeSemanticRow: View {

    let title: String
    let value: String
    let detail: String?
    let systemImage: String
    let showsDivider: Bool

    init(
        title: String,
        value: String,
        detail: String? = nil,
        systemImage: String,
        showsDivider: Bool = true
    ) {
        self.title = title
        self.value = value
        self.detail = detail
        self.systemImage = systemImage
        self.showsDivider = showsDivider
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                V1IOSHomeTonalIcon(
                    systemImage: systemImage
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let detail,
                       !detail.isEmpty {
                        Text(detail)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 12)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)

            if showsDivider {
                Rectangle()
                    .fill(ConfigurationUI.faintHairline)
                    .frame(height: 0.5)
                    .padding(.leading, 60)
            }
        }
    }
}

struct V1IOSHomeNavigationRowButton: View {

    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void
    let showsDivider: Bool

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        showsDivider: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.showsDivider = showsDivider
        self.action = action
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(alignment: .center, spacing: 12) {
                    V1IOSHomeTonalIcon(
                        systemImage: systemImage
                    )

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 12)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)

            if showsDivider {
                Rectangle()
                    .fill(ConfigurationUI.faintHairline)
                    .frame(height: 0.5)
                    .padding(.leading, 60)
            }
        }
    }
}

private struct V1IOSHomeTonalIcon: View {

    let systemImage: String

    var body: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
            .fill(ConfigurationUI.panelBackground)

            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        }
        .frame(width: 36, height: 36)
    }
}

#endif
