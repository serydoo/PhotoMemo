#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct ExpressionEditor: View {

    @ObservedObject
    var session: ConfigurationSession

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            expressionBlocks

            TokenPicker(session: session)
        }
    }

    private var expressionBlocks: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Apple Tokens")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(blocks) { block in
                HStack(spacing: 8) {
                    Button {
                        session.selectBlock(block)
                    } label: {
                        HStack(spacing: 8) {
                            Image(
                                systemName:
                                    symbolName(for: block)
                            )
                            .frame(width: 18)

                            Text(block.value)
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
                                )
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        session.moveBlock(block, direction: -1)
                    } label: {
                        Image(systemName: "chevron.up")
                    }
                    .buttonStyle(.borderless)
                    .disabled(blocks.first?.id == block.id)

                    Button {
                        session.moveBlock(block, direction: 1)
                    } label: {
                        Image(systemName: "chevron.down")
                    }
                    .buttonStyle(.borderless)
                    .disabled(blocks.last?.id == block.id)

                    Button(role: .destructive) {
                        session.removeBlock(block)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            block.id == session.state.selectedBlockID
                            ? Color.accentColor.opacity(0.10)
                            : Color.gray.opacity(0.06)
                        )
                )
            }
        }
    }

    private var blocks: [MemoryBlock] {
        session.state.selectedSubject?
            .behavior.memoryExpression.blocks ?? []
    }

    private func symbolName(
        for block: MemoryBlock
    ) -> String {
        switch block.type {
        case .text:
            return "textformat"
        case .memory:
            return "heart.text.square"
        case .photo:
            return "camera"
        case .system:
            return "lock"
        }
    }
}
#endif
