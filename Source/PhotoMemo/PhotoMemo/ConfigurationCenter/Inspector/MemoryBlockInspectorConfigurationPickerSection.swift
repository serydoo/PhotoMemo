#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct MemoryBlockInspectorConfigurationOption:
    Identifiable,
    Hashable {

    let id: String
    let title: String
}

struct MemoryBlockInspectorConfigurationPickerSection: View {

    let options: [MemoryBlockInspectorConfigurationOption]

    @Binding
    var selectedTemplateID: String

    let currentTemplateSummary: String
    let isSaved: Bool

    @Binding
    var renamingConfigurationID: String?

    let renameText: Binding<String>
    let onSaveConfiguration: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker(
                "配置",
                selection: $selectedTemplateID
            ) {
                ForEach(options) { option in
                    Text(option.title)
                        .tag(option.id)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(currentTemplateSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2.weight(.semibold))

                Text("当前记忆预设使用中")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.accentColor.opacity(0.08))
            )

            HStack(spacing: 8) {
                Button(action: onSaveConfiguration) {
                    Label(
                        isSaved
                        ? "已保存"
                        : "保存配置",
                        systemImage:
                            isSaved
                            ? "checkmark.circle.fill"
                            : "tray.and.arrow.down"
                    )
                }
                .buttonStyle(.borderless)

                Button {
                    renamingConfigurationID =
                        renamingConfigurationID == selectedTemplateID
                        ? nil
                        : selectedTemplateID
                } label: {
                    Label("重命名", systemImage: "pencil")
                }
                .buttonStyle(.borderless)
            }
            .font(.caption.weight(.medium))

            if renamingConfigurationID == selectedTemplateID {
                TextField(
                    "配置名称",
                    text: renameText
                )
                .textFieldStyle(.plain)
                .font(.subheadline)
                .configurationFieldChrome(isActive: true)
            }
        }
        .padding(12)
        .configurationPanelChrome(isSelected: true)
    }
}
#endif
