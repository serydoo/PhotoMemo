#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 preset selection coordinator")
struct V1PresetSelectionCoordinatorTests {

    @Test("selectedPresetID falls back from current preset to first preset to sentinel UUID")
    func selectedPresetIDFallbacks() {
        let first =
            MemoryPreset(
                title: "配置 1",
                summary: "概览 1",
                regionTemplateIDs: [:]
            )
        let second =
            MemoryPreset(
                title: "配置 2",
                summary: "概览 2",
                regionTemplateIDs: [:]
            )

        #expect(
            V1PresetSelectionCoordinator
                .selectedPresetID(
                    selectedPreset: second,
                    presets: [first, second]
                )
            == second.id
        )

        #expect(
            V1PresetSelectionCoordinator
                .selectedPresetID(
                    selectedPreset: nil,
                    presets: [first, second]
                )
            == first.id
        )

        #expect(
            V1PresetSelectionCoordinator
                .selectedPresetID(
                    selectedPreset: nil,
                    presets: []
                )
            == V1PresetSelectionCoordinator
                .fallbackPresetID
        )
    }

    @Test("selectionUpdate ignores the already-selected preset and unknown IDs")
    func selectionUpdateSkipsNoOpAndUnknownPresetIDs() {
        let preset =
            MemoryPreset(
                title: "当前配置",
                summary: "概览",
                regionTemplateIDs: [:]
            )

        #expect(
            V1PresetSelectionCoordinator
                .selectionUpdate(
                    for: preset.id,
                    currentPreset: preset,
                    presets: [preset]
                ) == nil
        )

        #expect(
            V1PresetSelectionCoordinator
                .selectionUpdate(
                    for: UUID(),
                    currentPreset: nil,
                    presets: [preset]
                ) == nil
        )
    }

    @Test("selectionUpdate returns the immediate activation payload for a valid preset switch")
    func selectionUpdateBuildsActivationPayload() throws {
        let first =
            MemoryPreset(
                title: "当前配置",
                summary: "概览 1",
                regionTemplateIDs: [:]
            )
        let second =
            MemoryPreset(
                title: "旅行配置",
                summary: "概览 2",
                regionTemplateIDs: [:]
            )

        let update =
            try #require(
                V1PresetSelectionCoordinator
                    .selectionUpdate(
                        for: second.id,
                        currentPreset: first,
                        presets: [first, second]
                    )
            )

        #expect(update.preset.id == second.id)
        #expect(
            update.activeConfigurationStatus
            == .saving
        )
    }
}
#endif
