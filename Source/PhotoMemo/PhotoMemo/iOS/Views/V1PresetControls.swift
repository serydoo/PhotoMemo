#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1PresetPicker: View {

    let currentTitle: String
    let presets: [MemoryPreset]
    @Binding
    var selectedPresetID: MemoryPreset.ID

    var body: some View {
        Menu {
            Picker(
                "当前生效配置",
                selection: $selectedPresetID
            ) {
                ForEach(presets) { preset in
                    Text(preset.title).tag(preset.id)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.caption.weight(.semibold))

                Text(currentTitle)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentColor.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.accentColor.opacity(0.18))
            )
        }
    }
}

struct V1PresetOperationsMenu: View {

    let onRename: () -> Void
    let onRestoreDefaults: () -> Void

    var body: some View {
        Menu {
            Button("重命名配置") {
                onRename()
            }

            Button("恢复默认内容") {
                onRestoreDefaults()
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "ellipsis.circle")
                    .font(.caption.weight(.semibold))

                Text("管理")
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(ConfigurationUI.controlBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(ConfigurationUI.faintHairline)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .accessibilityLabel("更多配置操作")
    }
}
#endif
