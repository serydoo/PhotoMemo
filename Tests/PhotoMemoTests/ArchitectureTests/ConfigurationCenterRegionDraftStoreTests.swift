#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Configuration center region draft store")
struct ConfigurationCenterRegionDraftStoreTests {

    @Test("uses region defaults until local overrides are written")
    func usesRegionDefaultsUntilLocalOverridesAreWritten() {
        var store =
            ConfigurationCenterRegionDraftStore()

        #expect(
            store.selectedConfigurationID(
                for: .slotA
            ) == "recorder.configuration1"
        )
        #expect(
            store.configurationName(
                for: .slotA
            ) == "配置 1：记录者信息"
        )
        #expect(
            !store.text(
                for: .slotA,
                subject: nil
            )
            .isEmpty
        )

        store.setSelectedConfigurationID(
            "recorder.configuration3",
            for: .slotA
        )
        store.setConfigurationName(
            "配置 3：旅行记录",
            for: .slotA
        )
        store.setText(
            "记录者",
            for: .slotA
        )
        store.setContinuationText(
            "在旅途中",
            for: .slotA
        )

        #expect(
            store.selectedConfigurationID(
                for: .slotA
            ) == "recorder.configuration3"
        )
        #expect(
            store.configurationName(
                for: .slotA
            ) == "配置 3：旅行记录"
        )
        #expect(
            store.text(
                for: .slotA,
                subject: nil
            ) == "记录者"
        )
        #expect(
            store.continuationText(
                for: .slotA
            ) == "在旅途中"
        )
    }

    @Test("tracks modules rename state and saved state by active configuration")
    func tracksModulesRenameStateAndSavedStateByActiveConfiguration() {
        var store =
            ConfigurationCenterRegionDraftStore()
        let module =
            IOSInsertedModule(
                title: "拍摄日期",
                value: "2026.05.24",
                systemImage: "calendar"
            )

        store.setSelectedConfigurationID(
            "timeline.configuration2",
            for: .slotB
        )
        store.setModules(
            [module],
            for: .slotB
        )
        store.setRenamingConfiguration(
            true,
            for: .slotB
        )
        store.markSaved(
            for: .slotB
        )

        #expect(
            store.modules(
                for: .slotB
            ) == [module]
        )
        #expect(
            store.isRenamingConfiguration(
                for: .slotB
            )
        )
        #expect(
            store.isSaved(
                for: .slotB
            )
        )

        store.setRenamingConfiguration(
            false,
            for: .slotB
        )

        #expect(
            !store.isRenamingConfiguration(
                for: .slotB
            )
        )
    }

    @Test("configuration options reflect renamed titles for the matching region")
    func configurationOptionsReflectRenamedTitlesForTheMatchingRegion() {
        var store =
            ConfigurationCenterRegionDraftStore()

        store.regionConfigurationNames[
            "memory.configuration2"
        ] = "配置 2：纪念日"

        let options =
            store.configurationOptions(
                for: .slotD
            )

        #expect(
            options == [
                IOSRegionConfigurationOption(
                    id: "memory.configuration1",
                    title: "配置 1：生日年龄智能模块"
                ),
                IOSRegionConfigurationOption(
                    id: "memory.configuration2",
                    title: "配置 2：纪念日"
                ),
                IOSRegionConfigurationOption(
                    id: "memory.configuration3",
                    title: "配置 3：自定义记忆"
                )
            ]
        )
    }

    @Test("switching configurations restores the region-local draft state for each configuration ID")
    func switchingConfigurationsRestoresRegionLocalDraftStatePerConfigurationID() {
        var store =
            ConfigurationCenterRegionDraftStore()
        let firstModule =
            IOSInsertedModule(
                title: "拍摄日期",
                value: "2026.05.24",
                systemImage: "calendar"
            )
        let secondModule =
            IOSInsertedModule(
                title: "地点",
                value: "上海",
                systemImage: "location"
            )

        store.setText(
            "默认配置文本",
            for: .slotA
        )
        store.setModules(
            [firstModule],
            for: .slotA
        )
        store.setContinuationText(
            "默认续写",
            for: .slotA
        )
        store.markSaved(
            for: .slotA
        )

        store.setSelectedConfigurationID(
            "recorder.configuration2",
            for: .slotA
        )
        store.setText(
            "第二配置文本",
            for: .slotA
        )
        store.setModules(
            [secondModule],
            for: .slotA
        )
        store.setContinuationText(
            "第二续写",
            for: .slotA
        )

        #expect(
            store.text(
                for: .slotA,
                subject: nil
            ) == "第二配置文本"
        )
        #expect(
            store.modules(
                for: .slotA
            ) == [secondModule]
        )
        #expect(
            store.continuationText(
                for: .slotA
            ) == "第二续写"
        )
        #expect(
            !store.isSaved(
                for: .slotA
            )
        )

        store.setSelectedConfigurationID(
            "recorder.configuration1",
            for: .slotA
        )

        #expect(
            store.text(
                for: .slotA,
                subject: nil
            ) == "默认配置文本"
        )
        #expect(
            store.modules(
                for: .slotA
            ) == [firstModule]
        )
        #expect(
            store.continuationText(
                for: .slotA
            ) == "默认续写"
        )
        #expect(
            store.isSaved(
                for: .slotA
            )
        )
    }

    @Test("changing one region selection keeps another region's active configuration and draft state intact")
    func changingOneRegionSelectionKeepsOtherRegionStateIntact() {
        var store =
            ConfigurationCenterRegionDraftStore()

        store.setSelectedConfigurationID(
            "recorder.configuration2",
            for: .slotA
        )
        store.setText(
            "记录者配置二",
            for: .slotA
        )

        store.setSelectedConfigurationID(
            "timeline.configuration3",
            for: .slotB
        )
        store.setText(
            "时间线配置三",
            for: .slotB
        )
        store.setContinuationText(
            "继续记录",
            for: .slotB
        )

        store.setSelectedConfigurationID(
            "recorder.configuration1",
            for: .slotA
        )

        #expect(
            store.selectedConfigurationID(
                for: .slotA
            ) == "recorder.configuration1"
        )
        #expect(
            store.selectedConfigurationID(
                for: .slotB
            ) == "timeline.configuration3"
        )
        #expect(
            store.text(
                for: .slotB,
                subject: nil
            ) == "时间线配置三"
        )
        #expect(
            store.continuationText(
                for: .slotB
            ) == "继续记录"
        )
    }

    @Test("rename state follows the active configuration ID instead of leaking across selections")
    func renameStateFollowsActiveConfigurationID() {
        var store =
            ConfigurationCenterRegionDraftStore()

        store.setSelectedConfigurationID(
            "memory.configuration2",
            for: .slotD
        )
        store.setRenamingConfiguration(
            true,
            for: .slotD
        )

        #expect(
            store.isRenamingConfiguration(
                for: .slotD
            )
        )

        store.setSelectedConfigurationID(
            "memory.configuration1",
            for: .slotD
        )

        #expect(
            !store.isRenamingConfiguration(
                for: .slotD
            )
        )

        store.setSelectedConfigurationID(
            "memory.configuration2",
            for: .slotD
        )

        #expect(
            store.isRenamingConfiguration(
                for: .slotD
            )
        )
    }
}
#endif
