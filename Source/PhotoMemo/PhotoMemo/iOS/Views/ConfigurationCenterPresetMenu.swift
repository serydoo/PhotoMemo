#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct ConfigurationCenterPresetMenu: View {

    let presets: [MemoryPreset]
    let selectedPreset: MemoryPreset?
    let currentTitle: String
    let onSelectPreset: (MemoryPreset) -> Void

    var body: some View {
        Menu {
            ForEach(presets) { preset in
                Button {
                    onSelectPreset(preset)
                } label: {
                    HStack {
                        Text(preset.title)

                        if ConfigurationCenterPresetSelectionPresenter
                            .isSelectedPreset(
                                preset,
                                selectedPreset: selectedPreset
                            ) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text("配置组合")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                HStack(spacing: 6) {
                    Text(currentTitle)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(ConfigurationUI.selectedBackground)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.smallCornerRadius,
                    style: .continuous
                )
            )
        }
    }
}
#endif
