#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct ConfigurationCenterPresetSelectionPresenter {

    static func selectedPresetID(
        selectedPreset: MemoryPreset?,
        presets: [MemoryPreset]
    ) -> MemoryPreset.ID? {
        selectedPreset?.id ?? presets.first?.id
    }

    static func preset(
        matching presetID: MemoryPreset.ID,
        in presets: [MemoryPreset]
    ) -> MemoryPreset? {
        presets.first { $0.id == presetID }
    }

    static func isSelectedPreset(
        _ preset: MemoryPreset,
        selectedPreset: MemoryPreset?
    ) -> Bool {
        preset.id == selectedPreset?.id
    }
}
#endif
