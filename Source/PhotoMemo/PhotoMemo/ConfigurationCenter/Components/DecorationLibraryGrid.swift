#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct DecorationLibraryGrid: View {

    let title: String
    let decorations: [DecorationAsset]
    let onSelect: (DecorationAsset) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 92), spacing: 9)
                ],
                spacing: 9
            ) {
                ForEach(decorations) { decoration in
                    Button {
                        onSelect(decoration)
                    } label: {
                        VStack(spacing: 8) {
                            Image(
                                systemName:
                                    decoration.systemSymbolName
                            )
                            .font(.title2.weight(.semibold))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Color.accentColor)

                            Text(decoration.title)
                                .font(.caption.weight(.medium))
                                .lineLimit(1)

                            Text(decoration.strategy.displayTitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 82
                        )
                    }
                    .buttonStyle(.plain)
                        .padding(10)
                        .configurationPanelChrome()
                }
            }
        }
    }
}

private extension DecorationStrategy {

    var displayTitle: String {
        switch self {
        case .autoMatch:
            return "自动匹配"
        case .fixed:
            return "固定"
        case .none:
            return "无"
        case .overrideCurrentExport:
            return "覆盖当前输出"
        }
    }
}
#endif
