#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct ExpressionEditor: View {

    @ObservedObject
    var session: ConfigurationSession

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            InspectorSectionView(
                "Memory Expression",
                systemImage: "text.quote"
            ) {
                expressionPreview
            }

            InspectorSectionView(
                "Properties",
                systemImage: "slider.horizontal.3"
            ) {
                selectedBlockControls
            }

            InspectorSectionView(
                "Token Library",
                systemImage: "tag.fill"
            ) {
                TokenPicker(session: session)
            }
        }
    }

    private var expressionPreview: some View {
        HStack(spacing: 6) {
            ForEach(blocks) { block in
                Button {
                    session.selectBlock(block)
                } label: {
                    AppleTokenView(
                        block: block,
                        isSelected:
                            block.id
                            == session.state.selectedBlockID
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var selectedBlockControls: some View {
        if let block = selectedBlock {
            HStack(spacing: 10) {
                Label(
                    block.title,
                    systemImage: symbolName(for: block)
                )
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.primary)

                Spacer(minLength: 0)

                Button {
                    session.moveBlock(block, direction: -1)
                } label: {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.borderless)
                .disabled(blocks.first?.id == block.id)
                .help("Move Up")

                Button {
                    session.moveBlock(block, direction: 1)
                } label: {
                    Image(systemName: "chevron.down")
                }
                .buttonStyle(.borderless)
                .disabled(blocks.last?.id == block.id)
                .help("Move Down")

                Button(role: .destructive) {
                    session.removeBlock(block)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Remove")
            }
            .padding(.vertical, 4)
        } else {
            Text("Select a token in the expression.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var blocks: [MemoryBlock] {
        session.state.selectedSubject?
            .behavior.memoryExpression.blocks ?? []
    }

    private var selectedBlock: MemoryBlock? {
        guard let selectedBlockID =
                session.state.selectedBlockID
        else {
            return nil
        }

        return blocks.first {
            $0.id == selectedBlockID
        }
    }

    private func symbolName(
        for block: MemoryBlock
    ) -> String {
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

struct AppleTokenView: View {

    let block: MemoryBlock
    let isSelected: Bool

    var body: some View {
        Text(block.value)
            .font(font)
            .foregroundStyle(foregroundStyle)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(background)
            .overlay(selectionStroke)
    }

    private var font: Font {
        block.type == .text
        ? .subheadline
        : .caption.weight(.semibold)
    }

    private var foregroundStyle: Color {
        block.type == .text
        ? Color.primary
        : Color.accentColor
    }

    private var horizontalPadding: CGFloat {
        block.type == .text ? 0 : 9
    }

    private var verticalPadding: CGFloat {
        block.type == .text ? 0 : 5
    }

    @ViewBuilder
    private var background: some View {
        if block.type == .text {
            Color.clear
        } else {
            Capsule()
                .fill(Color.accentColor.opacity(0.10))
        }
    }

    @ViewBuilder
    private var selectionStroke: some View {
        if isSelected, block.type != .text {
            Capsule()
                .stroke(Color.accentColor.opacity(0.55))
        }
    }
}
#endif
