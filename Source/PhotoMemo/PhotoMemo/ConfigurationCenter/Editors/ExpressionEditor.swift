#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct ExpressionEditor: View {

    @ObservedObject
    var session: ConfigurationSession

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            InspectorSectionView(
                "记忆表达",
                systemImage: "text.quote"
            ) {
                expressionPreview
            }

            InspectorSectionView(
                "属性",
                systemImage: "slider.horizontal.3"
            ) {
                selectedBlockControls
            }

            InspectorSectionView(
                "模块库",
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
        .padding(12)
        .configurationPanelChrome()
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
                .help("上移")

                Button {
                    session.moveBlock(block, direction: 1)
                } label: {
                    Image(systemName: "chevron.down")
                }
                .buttonStyle(.borderless)
                .disabled(blocks.last?.id == block.id)
                .help("下移")

                Button(role: .destructive) {
                    session.removeBlock(block)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("删除")
            }
            .padding(10)
            .configurationPanelChrome(isSelected: true)
        } else {
            Text("请选择一个记忆模块。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(12)
                .configurationPanelChrome()
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
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.085))
        }
    }

    @ViewBuilder
    private var selectionStroke: some View {
        if isSelected, block.type != .text {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.accentColor.opacity(0.55))
        }
    }
}
#endif
