#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct InteractiveMemoryCardRegionStrip: View {

    let selectedRegion: CardRegion
    let onSelectRegion: (CardRegion) -> Void

    var body: some View {
        HStack(spacing: 0) {
            regionStripButton(
                .slotA,
                title: "记录",
                systemImage: "camera.fill"
            )

            regionStripButton(
                .slotB,
                title: "时间线",
                systemImage: "calendar"
            )

            regionStripButton(
                .slotC,
                title: "拍摄参数",
                systemImage: "scope"
            )

            regionStripButton(
                .slotD,
                title: "记忆",
                systemImage: "text.quote"
            )
        }
        .padding(4)
        .frame(width: 590)
        .background(Color.white.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(ConfigurationUI.hairline)
        )
    }

    private func regionStripButton(
        _ region: CardRegion,
        title: String,
        systemImage: String
    ) -> some View {
        Button {
            onSelectRegion(region)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)

                Text(title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(
                region == selectedRegion
                ? Color.accentColor
                : Color.secondary
            )
            .frame(maxWidth: .infinity, minHeight: 38)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        region == selectedRegion
                        ? ConfigurationUI.selectedBackground
                        : Color.clear
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(
            "\(region.accessibilityIdentifier).strip"
        )
        .accessibilityLabel(
            "\(title), \(region.semanticTitle)"
        )
    }
}
#endif
