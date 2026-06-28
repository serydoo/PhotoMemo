#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

enum ConfigurationUI {

    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 10
    static let contentSpacing: CGFloat = 16
    static let sectionSpacing: CGFloat = 20

    #if os(iOS)
    static let appBackground =
        Color(uiColor: .systemGroupedBackground)

    static let panelBackground =
        Color(uiColor: .secondarySystemGroupedBackground)

    static let controlBackground =
        Color(uiColor: .tertiarySystemGroupedBackground)
    #elseif os(macOS)
    static let appBackground =
        Color(nsColor: .windowBackgroundColor)

    static let panelBackground =
        Color(nsColor: .underPageBackgroundColor)

    static let controlBackground =
        Color(nsColor: .controlBackgroundColor)
    #else
    static let appBackground = Color.primary.opacity(0.04)
    static let panelBackground = Color.primary.opacity(0.025)
    static let controlBackground = Color.primary.opacity(0.04)
    #endif

    static let selectedBackground =
        Color.accentColor.opacity(0.075)

    static let hoverBackground =
        Color.primary.opacity(0.018)

    static let hairline =
        Color.primary.opacity(0.07)

    static let faintHairline =
        Color.primary.opacity(0.038)

    static let cardShadow =
        Color.primary.opacity(0.022)

}

struct InspectorSectionView<Content: View>: View {

    let title: String
    let systemImage: String?
    @ViewBuilder var content: Content

    init(
        _ title: String,
        systemImage: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 7) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                }

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 2)
    }
}

struct InspectorPropertyRow: View {

    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

struct ConfigurationFieldChrome: ViewModifier {

    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.smallCornerRadius,
                    style: .continuous
                )
                .fill(ConfigurationUI.panelBackground)
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.smallCornerRadius,
                    style: .continuous
                )
                    .stroke(
                        isActive
                        ? Color.accentColor.opacity(0.28)
                        : ConfigurationUI.faintHairline,
                        lineWidth: isActive ? 1 : 0.75
                    )
            )
    }
}

struct ConfigurationPanelChrome: ViewModifier {

    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.cornerRadius,
                    style: .continuous
                )
                    .fill(
                        isSelected
                        ? ConfigurationUI.selectedBackground
                        : ConfigurationUI.controlBackground.opacity(0.72)
                    )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.cornerRadius,
                    style: .continuous
                )
                    .stroke(
                        isSelected
                        ? Color.accentColor.opacity(0.2)
                        : ConfigurationUI.faintHairline
                    )
            )
    }
}

extension View {

    func configurationFieldChrome(
        isActive: Bool = false
    ) -> some View {
        modifier(
            ConfigurationFieldChrome(
                isActive: isActive
            )
        )
    }

    func configurationPanelChrome(
        isSelected: Bool = false
    ) -> some View {
        modifier(
            ConfigurationPanelChrome(
                isSelected: isSelected
            )
        )
    }
}
#endif
