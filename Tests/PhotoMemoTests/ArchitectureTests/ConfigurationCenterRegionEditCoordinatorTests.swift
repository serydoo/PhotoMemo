#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Configuration center region edit coordinator")
struct ConfigurationCenterRegionEditCoordinatorTests {

    @Test("setText updates the region draft store and recomputes preview text")
    func setTextUpdatesStoreAndRecomputesPreviewText() {
        let coordinator =
            ConfigurationCenterRegionEditCoordinator(
                previewHelper:
                    ConfigurationCenterPreviewCompositionHelper(
                        context: .init(subject: nil)
                    )
            )

        let update =
            coordinator.setText(
                "记录者",
                for: .slotA,
                store: .init()
            )

        #expect(
            update.store.text(
                for: .slotA,
                subject: nil
            ) == "记录者"
        )
        #expect(update.previewText == "记录者")
    }

    @Test("setModules keeps the written modules and recomputes preview text from the updated store")
    func setModulesKeepsWrittenModulesAndRecomputesPreviewText() {
        let coordinator =
            ConfigurationCenterRegionEditCoordinator(
                previewHelper:
                    ConfigurationCenterPreviewCompositionHelper(
                        context: .init(subject: nil)
                    )
            )
        let module =
            IOSInsertedModule(
                title: "拍摄日期",
                value: "2026.05.24",
                systemImage: "calendar"
            )
        var store =
            ConfigurationCenterRegionDraftStore()
        store.setText(
            "记录于",
            for: .slotB
        )

        let update =
            coordinator.setModules(
                [module],
                for: .slotB,
                store: store
            )

        #expect(
            update.store.modules(
                for: .slotB
            ) == [module]
        )
        #expect(
            update.previewText.contains("记录于")
        )
        #expect(
            update.previewText.contains("2026.05.24")
        )
    }

    @Test("setSelectedConfigurationID recomputes preview text from the chosen configuration state")
    func setSelectedConfigurationIDRecomputesPreviewFromChosenConfigurationState() {
        let coordinator =
            ConfigurationCenterRegionEditCoordinator(
                previewHelper:
                    ConfigurationCenterPreviewCompositionHelper(
                        context: .init(subject: nil)
                    )
            )
        let module =
            IOSInsertedModule(
                title: "地点",
                value: "河南 · 商丘",
                systemImage: "location"
            )
        var store =
            ConfigurationCenterRegionDraftStore()

        store.setText(
            "配置一",
            for: .slotC
        )
        store.setSelectedConfigurationID(
            "context.configuration2",
            for: .slotC
        )
        store.setText(
            "配置二",
            for: .slotC
        )
        store.setModules(
            [module],
            for: .slotC
        )
        store.setContinuationText(
            "旅程中",
            for: .slotC
        )

        let update =
            coordinator.setSelectedConfigurationID(
                "context.configuration1",
                for: .slotC,
                store: store
            )
        let switchedBack =
            coordinator.setSelectedConfigurationID(
                "context.configuration2",
                for: .slotC,
                store: update.store
            )

        #expect(update.previewText == "配置一")
        #expect(
            switchedBack.previewText.contains("配置二")
        )
        #expect(
            switchedBack.previewText.contains("河南 · 商丘")
        )
        #expect(
            switchedBack.previewText.contains("旅程中")
        )
    }
}
#endif
