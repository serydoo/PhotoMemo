#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct MemoryBlockInspectorSystemFieldDisplayItem:
    Identifiable,
    Hashable {

    let id: String
    let label: String
    let symbolName: String
    let value: String
}

struct MemoryBlockInspectorSystemModulesSection: View {

    let fields: [MemoryBlockInspectorSystemFieldDisplayItem]
    let onDelete: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if fields.isEmpty {
                Text("此区域由用户自定义。可以在下方添加字段，并插入照片信息、记忆或系统模块。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .configurationPanelChrome()
            } else {
                ForEach(fields) { field in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: field.symbolName)
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 22)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(field.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(field.value)
                                .font(.subheadline)
                                .foregroundStyle(Color.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)

                        Button(role: .destructive) {
                            onDelete(field.id)
                        } label: {
                            Label("删除", systemImage: "trash")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.borderless)
                        .help("删除默认模块")
                    }
                    .padding(10)
                    .configurationPanelChrome()
                }
            }
        }
    }
}
#endif
