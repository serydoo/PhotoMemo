#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1PresetSelectionUpdate {

    let preset: MemoryPreset

    let pendingActivationPresetTitle: String

    let activeConfigurationMessage: String

    let showsPresetActivationConfirmation: Bool
}

enum V1PresetSelectionCoordinator {

    static let fallbackPresetID =
        UUID(
            uuidString: "00000000-0000-0000-0000-000000000000"
        )!

    static func selectedPresetID(
        selectedPreset: MemoryPreset?,
        presets: [MemoryPreset]
    ) -> MemoryPreset.ID {
        selectedPreset?.id
        ?? presets.first?.id
        ?? fallbackPresetID
    }

    static func selectionUpdate(
        for presetID: MemoryPreset.ID,
        currentPreset: MemoryPreset?,
        presets: [MemoryPreset]
    ) -> V1PresetSelectionUpdate? {
        guard presetID != currentPreset?.id else {
            return nil
        }

        guard let preset = presets.first(where: {
            $0.id == presetID
        }) else {
            return nil
        }

        return V1PresetSelectionUpdate(
            preset: preset,
            pendingActivationPresetTitle:
                preset.title,
            activeConfigurationMessage:
                "有未保存修改",
            showsPresetActivationConfirmation:
                true
        )
    }
}
#endif
