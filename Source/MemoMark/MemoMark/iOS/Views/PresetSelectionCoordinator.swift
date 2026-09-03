#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct PresetSelectionUpdate {

    let preset: MemoryPreset
}

enum PresetSelectionCoordinator {

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
    ) -> PresetSelectionUpdate? {
        guard presetID != currentPreset?.id else {
            return nil
        }

        guard let preset = presets.first(where: {
            $0.id == presetID
        }) else {
            return nil
        }

        return PresetSelectionUpdate(
            preset: preset
        )
    }
}
#endif
