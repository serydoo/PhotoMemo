#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Configuration center preview composition helper")
struct ConfigurationCenterPreviewCompositionHelperTests {

    @MainActor
    @Test("insertModule seeds the region draft and appends a projected module value")
    func insertModuleSeedsTheRegionDraftAndAppendsAProjectedModuleValue() {
        let session =
            ConfigurationSession()
        let helper =
            ConfigurationCenterPreviewCompositionHelper(
                context: .init(
                    subject: session.state.selectedSubject
                )
            )
        let initialStore =
            ConfigurationCenterRegionDraftStore()

        let update =
            helper.insertModule(
                .cameraModel,
                into: .slotA,
                store: initialStore
            )

        #expect(
            update.store.text(
                for: .slotA,
                subject: session.state.selectedSubject
            ) == "记录 iPhone 17 Pro Max"
        )
        #expect(
            update.store.modules(for: .slotA).count
            == 1
        )
        #expect(
            update.store.modules(for: .slotA).first?.title
            == IOSInsertableModule.cameraModel.title
        )
        #expect(
            update.store.modules(for: .slotA).first?.value
            == "iPhone 17 Pro Max"
        )
        #expect(
            update.store.modules(for: .slotA).first?.systemImage
            == IOSInsertableModule.cameraModel.systemImage
        )
        #expect(
            update.previewText
            == "记录 iPhone 17 Pro MaxiPhone 17 Pro Max"
        )
    }

    @MainActor
    @Test("removeInsertedModule recomposes the preview without the removed module")
    func removeInsertedModuleRecomposesThePreviewWithoutTheRemovedModule() {
        let session =
            ConfigurationSession()
        let helper =
            ConfigurationCenterPreviewCompositionHelper(
                context: .init(
                    subject: session.state.selectedSubject
                )
            )
        var store =
            ConfigurationCenterRegionDraftStore()
        let keptModule =
            IOSInsertedModule(
                title: "拍摄日期",
                value: "2026.05.24",
                systemImage: "calendar"
            )
        let removedModule =
            IOSInsertedModule(
                title: "拍摄时间",
                value: "14:33:13",
                systemImage: "clock"
            )

        store.setSelectedConfigurationID(
            "timeline.configuration3",
            for: .slotB
        )
        store.setText(
            "记录于",
            for: .slotB
        )
        store.setModules(
            [keptModule, removedModule],
            for: .slotB
        )
        store.setContinuationText(
            "在夏天",
            for: .slotB
        )

        let update =
            helper.removeInsertedModule(
                removedModule,
                from: .slotB,
                store: store
            )

        #expect(
            update.store.modules(for: .slotB)
            == [keptModule]
        )
        #expect(
            update.previewText
            == "记录于2026.05.24在夏天"
        )
    }

    @MainActor
    @Test("composedPreviewText trims whitespace around base and continuation text while preserving full smart-module projection")
    func composedPreviewTextTrimsWhitespaceAroundBaseAndContinuationText() {
        let session =
            ConfigurationSession()
        let helper =
            ConfigurationCenterPreviewCompositionHelper(
                context: .init(
                    subject: session.state.selectedSubject
                )
            )
        var store =
            ConfigurationCenterRegionDraftStore()
        let smartTimeModule =
            IOSInsertedModule(
                title: IOSInsertableModule.smartTime.title,
                value: helper.smartTimeResult,
                systemImage: IOSInsertableModule.smartTime.systemImage
            )

        store.setSelectedConfigurationID(
            "recorder.configuration3",
            for: .slotA
        )
        store.setText(
            "  记录  ",
            for: .slotA
        )
        store.setModules(
            [smartTimeModule],
            for: .slotA
        )
        store.setContinuationText(
            "  记得那一天  ",
            for: .slotA
        )

        #expect(
            helper.composedPreviewText(
                for: .slotA,
                store: store
            ) == "记录途途今天11个月28天啦！记得那一天"
        )
    }

    @MainActor
    @Test("moduleValue and smartTimeResult preserve subject-aware smart-module projection")
    func moduleValueAndSmartTimeResultPreserveCurrentLocalFallbackProjection() {
        let session =
            ConfigurationSession()
        let helper =
            ConfigurationCenterPreviewCompositionHelper(
                context: .init(
                    subject: session.state.selectedSubject
                )
            )
        let fallbackHelper =
            ConfigurationCenterPreviewCompositionHelper(
                context: .init(subject: nil)
            )

        #expect(
            helper.moduleValue(.subjectNickname)
            == (
                session.state.selectedSubject?.identity.shortName
                ?? session.state.selectedSubject?.identity.displayName
                ?? "途途"
            )
        )
        #expect(
            helper.moduleValue(.smartTime)
            == "途途今天11个月28天啦！"
        )
        #expect(
            helper.moduleValue(.location)
            == "河南 · 商丘"
        )
        #expect(
            fallbackHelper.smartTimeResult
            == "未设置时间"
        )
    }
}
#endif
