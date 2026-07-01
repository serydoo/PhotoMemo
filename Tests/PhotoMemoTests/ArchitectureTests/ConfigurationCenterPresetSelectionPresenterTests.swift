#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Configuration center preset selection presenter")
struct ConfigurationCenterPresetSelectionPresenterTests {

    @Test("selectedPresetID falls back to the first preset when nothing is selected")
    func selectedPresetIDFallsBackToFirstPreset() {
        let first =
            makePreset(title: "默认")
        let second =
            makePreset(title: "旅行")

        #expect(
            ConfigurationCenterPresetSelectionPresenter
            .selectedPresetID(
                selectedPreset: nil,
                presets: [first, second]
            ) == first.id
        )
    }

    @Test("preset(matching:in:) resolves the matching preset and returns nil for missing IDs")
    func presetMatchingResolvesOrReturnsNil() {
        let first =
            makePreset(title: "默认")
        let second =
            makePreset(title: "旅行")

        #expect(
            ConfigurationCenterPresetSelectionPresenter
            .preset(
                matching: second.id,
                in: [first, second]
            ) == second
        )
        #expect(
            ConfigurationCenterPresetSelectionPresenter
            .preset(
                matching: UUID(),
                in: [first, second]
            ) == nil
        )
    }

    @Test("isSelectedPreset compares by preset ID")
    func isSelectedPresetComparesByPresetID() {
        let first =
            makePreset(title: "默认")
        let second =
            makePreset(title: "旅行")

        #expect(
            ConfigurationCenterPresetSelectionPresenter
            .isSelectedPreset(
                first,
                selectedPreset: first
            )
        )
        #expect(
            !ConfigurationCenterPresetSelectionPresenter
            .isSelectedPreset(
                second,
                selectedPreset: first
            )
        )
    }
}

private func makePreset(
    title: String
) -> MemoryPreset {
    MemoryPreset(
        title: title,
        summary: "\(title)摘要",
        regionTemplateIDs: [:]
    )
}
#endif
