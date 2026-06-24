#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct TokenPicker: View {

    @ObservedObject
    var session: ConfigurationSession

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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
        VStack(alignment: .leading, spacing: 9) {
            Text(category.displayTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            FlowLayout(spacing: 7) {
                ForEach(blocks) { block in
                    Button {
                        guard !block.isReserved else {
                            return
                        }
                        session.insertBlock(block)
                    } label: {
                        LibraryTokenChip(block: block)
                    }
                    .buttonStyle(.plain)
                    .disabled(block.isReserved)
                }
            }
        }
    }
}

private struct LibraryTokenChip: View {

    let block: MemoryBlock

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbolName)
                .font(.caption2.weight(.semibold))

            Text(block.value)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(
            block.isReserved
            ? Color.secondary
            : Color.accentColor
        )
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(
                    block.isReserved
                    ? Color.gray.opacity(0.08)
                    : Color.accentColor.opacity(0.10)
                )
        )
        .overlay(
            Capsule()
                .stroke(Color.black.opacity(0.05))
        )
    }

    private var symbolName: String {
        switch block.type {
        case .text:
            return "textformat"
        case .memory:
            return "person.fill"
        case .photo:
            return "camera.fill"
        case .system:
            return "lock.fill"
        }
    }
}

private struct FlowLayout<Content: View>: View {

    let spacing: CGFloat
    @ViewBuilder var content: Content

    init(
        spacing: CGFloat,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 82), spacing: spacing)
            ],
            alignment: .leading,
            spacing: spacing
        ) {
            content
        }
    }
}
#endif
