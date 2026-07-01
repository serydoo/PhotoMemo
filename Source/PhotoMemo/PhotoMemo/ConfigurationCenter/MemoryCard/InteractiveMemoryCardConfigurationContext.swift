#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct InteractiveMemoryCardConfigurationContext: View {

    let memoryPresets: [MemoryPreset]
    let selectedMemoryPresetID: Binding<MemoryPreset.ID>
    let currentTimeAnchorDescription: String
    let selectedMemoryPresetIsApplied: Bool
    let memoryPresetTitle: Binding<String>
    let isRenamingMemoryPreset: Binding<Bool>
    let onReset: () -> Void
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 18) {
                contextPresetControl

                Divider()
                    .frame(height: 34)

                contextStatusItem(
                    title: "时间锚点",
                    value: currentTimeAnchorDescription,
                    systemImage: "flag.fill"
                )

                Spacer(minLength: 0)

                contextPresetActions
            }

            if isRenamingMemoryPreset.wrappedValue {
                TextField(
                    "记忆预设名称",
                    text: memoryPresetTitle
                )
                .textFieldStyle(.plain)
                .font(.subheadline)
                .configurationFieldChrome(isActive: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 590, alignment: .leading)
        .configurationPanelChrome()
    }

    private var contextPresetControl: some View {
        HStack(spacing: 10) {
            Image(systemName: "rectangle.stack.fill")
                .font(.caption.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text("总体配置")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Picker(
                    "记忆预设",
                    selection: selectedMemoryPresetID
                ) {
                    ForEach(memoryPresets) { preset in
                        Text(preset.title)
                            .tag(preset.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(width: 142, alignment: .leading)
            }

            Button {
                isRenamingMemoryPreset.wrappedValue.toggle()
            } label: {
                Image(systemName: "pencil")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help("重命名记忆预设")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("总体配置")
        .accessibilityValue(memoryPresetTitle.wrappedValue)
    }

    private var contextPresetActions: some View {
        HStack(spacing: 8) {
            Button(action: onReset) {
                Label("重置", systemImage: "arrow.counterclockwise")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .help("重置当前总体配置")

            Button(action: onApply) {
                Label(
                    selectedMemoryPresetIsApplied
                    ? "已生效"
                    : "保存并生效",
                    systemImage:
                        selectedMemoryPresetIsApplied
                        ? "checkmark.circle.fill"
                        : "checkmark.circle"
                )
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("将当前总体配置设为生效配置")
        }
        .font(.caption.weight(.semibold))
    }

    private func contextStatusItem(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
        }
    }
}
#endif
