#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct TokenPicker: View {

    @ObservedObject
    var session: ConfigurationSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Token Library")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(session.state.tokenLibrary.categories) { category in
                tokenSection(
                    category: category,
                    blocks:
                        session.state.tokenLibrary
                        .blocks(for: category)
                )
            }
        }
    }

    private func tokenSection(
        category: TokenCategory,
        blocks: [MemoryBlock]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.displayTitle)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 92), spacing: 8)
                ],
                spacing: 8
            ) {
                ForEach(blocks) { block in
                    Button {
                        guard !block.isReserved else {
                            return
                        }
                        session.insertBlock(block)
                    } label: {
                        Text(block.value)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 30
                            )
                    }
                    .buttonStyle(.bordered)
                    .disabled(block.isReserved)
                }
            }
        }
    }
}
#endif
