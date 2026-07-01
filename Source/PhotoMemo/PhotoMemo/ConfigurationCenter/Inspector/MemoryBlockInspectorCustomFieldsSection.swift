#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct MemoryBlockInspectorCustomFieldsSection: View {

    let fields: [CustomBlockFieldDraft]
    let selectedFieldID: UUID?
    let focusedField: FocusState<BlockFocusedField?>.Binding
    let textBinding: (CustomBlockFieldDraft) -> Binding<String>
    let indexProvider: (UUID) -> Int?
    let onSelectField: (UUID) -> Void
    let onMoveField: (UUID, Int) -> Void
    let onMoveBefore: (UUID, UUID) -> Void
    let onRemoveInsertedModule: (UUID, UUID) -> Void
    let onDeleteField: (UUID) -> Void
    let onAddField: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(fields) { field in
                customFieldCard(field)
            }

            Button(action: onAddField) {
                Label("新增内容", systemImage: "plus.circle")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .configurationPanelChrome()
        }
    }

    private func customFieldCard(
        _ field: CustomBlockFieldDraft
    ) -> some View {
        let index = indexProvider(field.id)

        return VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("自定义内容 \(index.map { $0 + 1 } ?? 1)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Button {
                    onMoveField(field.id, -1)
                } label: {
                    Label("上移", systemImage: "chevron.up")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .disabled(index == nil || index == 0)
                .help("上移")

                Button {
                    onMoveField(field.id, 1)
                } label: {
                    Label("下移", systemImage: "chevron.down")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .disabled(
                    index == nil
                    || index == fields.count - 1
                )
                .help("下移")
            }

            customFieldContentEditor(for: field)
        }
        .padding(10)
        .configurationPanelChrome(
            isSelected: selectedFieldID == field.id
        )
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            onSelectField(field.id)
        }
        .draggable(field.id.uuidString)
        .dropDestination(for: String.self) { items, _ in
            guard
                let dragged = items.first,
                let draggedID = UUID(uuidString: dragged)
            else {
                return false
            }

            onMoveBefore(draggedID, field.id)
            return true
        }
    }

    private func customFieldContentEditor(
        for field: CustomBlockFieldDraft
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                TextField(
                    "输入自定义内容，或从下方插入模块",
                    text: textBinding(field),
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .font(.subheadline)
                .lineLimit(1...3)
                .focused(
                    focusedField,
                    equals: .customField(field.id)
                )

                if !field.displayText.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("组合预览")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        if !field.text.isEmpty {
                            Text(field.text)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.primary.opacity(0.82))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if !field.modules.isEmpty {
                            LazyVGrid(
                                columns: [
                                    GridItem(.adaptive(minimum: 96), spacing: 6)
                                ],
                                alignment: .leading,
                                spacing: 6
                            ) {
                                ForEach(field.modules) { insertedModule in
                                    MemoryBlockInspectorInsertedTokenChip(
                                        insertedModule: insertedModule
                                    ) {
                                        onRemoveInsertedModule(
                                            insertedModule.id,
                                            field.id
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(8)
                    .configurationPanelChrome()
                }
            }

            Button(role: .destructive) {
                onDeleteField(field.id)
            } label: {
                Image(systemName: "trash.fill")
                    .font(.body.weight(.semibold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.borderless)
            .help("删除自定义内容")
        }
        .padding(10)
        .configurationFieldChrome(
            isActive:
                focusedField.wrappedValue == .customField(field.id)
        )
    }
}

private struct MemoryBlockInspectorInsertedTokenChip: View {

    let insertedModule: InsertedModuleDraft
    let onDelete: () -> Void

    var body: some View {
        let module = insertedModule.module

        HStack(spacing: 5) {
            Image(systemName: module.systemImage)
                .font(.caption2.weight(.semibold))

            Text(module.title)
                .font(.caption.weight(.medium))
                .lineLimit(1)

            if let previewValue = module.previewValue {
                Text(previewValue)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("移除此模块")
        }
        .foregroundStyle(Color.primary.opacity(0.78))
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(ConfigurationUI.controlBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(ConfigurationUI.hairline)
        )
        .accessibilityLabel(module.title)
    }
}
#endif
