#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Configuration center insertable module policy")
struct ConfigurationCenterInsertableModulePolicyTests {

    @Test("module picker is only shown for memory-card regions")
    func modulePickerIsOnlyShownForMemoryCardRegions() {
        #expect(
            ConfigurationCenterInsertableModulePolicy
            .shouldShowModules(
                for: .slotA
            )
        )
        #expect(
            !ConfigurationCenterInsertableModulePolicy
            .shouldShowModules(
                for: .badge
            )
        )
    }

    @Test("all card regions can insert the smart module alongside capture modules")
    func allCardRegionsExposeSmartModule() {
        let slotDModules =
            ConfigurationCenterInsertableModulePolicy
            .visibleModules(
                for: .slotD
            )
        let slotAModules =
            ConfigurationCenterInsertableModulePolicy
            .visibleModules(
                for: .slotA
            )

        #expect(
            slotDModules.contains(.subjectNickname)
        )
        #expect(
            slotDModules.contains(.smartTime)
        )
        #expect(
            slotDModules.contains(.cameraModel)
        )

        #expect(
            slotAModules.contains(.subjectNickname)
        )
        #expect(
            slotAModules.contains(.smartTime)
        )
        #expect(
            slotAModules.contains(.cameraModel)
        )
        #expect(
            slotAModules.contains(.captureSummary)
        )
    }

    @Test("additional modules never overlap with visible modules")
    func additionalModulesNeverOverlapWithVisibleModules() {
        let visible =
            Set(
                ConfigurationCenterInsertableModulePolicy
                .visibleModules(
                    for: .slotB
                )
            )
        let additional =
            Set(
                ConfigurationCenterInsertableModulePolicy
                .additionalModules(
                    for: .slotB
                )
            )

        #expect(
            visible.isDisjoint(
                with: additional
            )
        )
        #expect(
            visible.union(additional)
            == Set(IOSInsertableModule.allCases)
        )
    }
}
#endif
