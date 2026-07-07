import SwiftUI

enum MainFieldSlot: String, CaseIterable, Hashable {

    case leftTop

    case rightTop

    case leftBottom

    case rightBottom

    var title: String {

        switch self {

        case .leftTop:
            return "左上区域"

        case .rightTop:
            return "右上区域"

        case .leftBottom:
            return "左下区域"

        case .rightBottom:
            return "右下区域"
        }
    }

    var placeholder: String {

        switch self {

        case .leftTop:
            return "例如：他爹手持型号记录"

        case .rightTop:
            return "例如：35mm焦距 光圈 快门 ISO"

        case .leftBottom:
            return "例如：记录于完整时间"

        case .rightBottom:
            return "例如：今天途途1岁2个月"
        }
    }
}

enum MinimalPalette {

    static let background =
        Color(
            red: 246 / 255,
            green: 247 / 255,
            blue: 249 / 255
        )

    static let surface = Color.white

    static let border =
        Color.black.opacity(0.05)

    static let accent =
        Color(
            red: 111 / 255,
            green: 125 / 255,
            blue: 166 / 255
        )
}

struct MinimalCardGroupBoxStyle: GroupBoxStyle {

    func makeBody(
        configuration: Configuration
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            configuration.label
                .font(.headline)
                .foregroundStyle(.primary)

            configuration.content
        }
        .padding(18)
        .background(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .fill(
                MinimalPalette.surface
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(
                MinimalPalette.border
            )
        )
        .shadow(
            color: .black.opacity(0.04),
            radius: 20,
            y: 10
        )
    }
}

struct MinimalChipStyle: ButtonStyle {

    func makeBody(
        configuration: Configuration
    ) -> some View {

        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(
                .primary.opacity(
                    configuration.isPressed ? 0.7 : 1
                )
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(
                        Color.gray.opacity(
                            configuration.isPressed
                            ? 0.14
                            : 0.1
                        )
                    )
            )
    }
}

struct MinimalInsetCard<Content: View>: View {

    @ViewBuilder
    let content: Content

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            content
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(
                Color.gray.opacity(0.08)
            )
        )
    }
}
