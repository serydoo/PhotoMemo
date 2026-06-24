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
                    GridItem(.adaptive(minimum: 92), spacing: 10)
                ],
                spacing: 10
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

                            Text(decoration.title)
                                .font(.caption.weight(.medium))
                                .lineLimit(1)

                            Text(decoration.strategy.rawValue)
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
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black.opacity(0.06))
                        )
	                }
	            }
        }
    }
}
#endif
