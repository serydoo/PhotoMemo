#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

enum ConfigurationUI {

    static let appBackground =
        Color(red: 0.965, green: 0.967, blue: 0.972)

    static let panelBackground =
        Color(red: 0.988, green: 0.988, blue: 0.992)

    static let controlBackground =
        Color(red: 0.948, green: 0.950, blue: 0.956)

    static let selectedBackground =
        Color.accentColor.opacity(0.105)

    static let hoverBackground =
        Color.black.opacity(0.025)

    static let hairline =
        Color.black.opacity(0.075)

    static let faintHairline =
        Color.black.opacity(0.045)

    static let cardShadow =
        Color.black.opacity(0.055)
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
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.84))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isActive
                        ? Color.accentColor.opacity(0.34)
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
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected
                        ? ConfigurationUI.selectedBackground
                        : ConfigurationUI.controlBackground.opacity(0.72)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected
                        ? Color.accentColor.opacity(0.28)
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
