#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Configuration center preview composition helper")
struct ConfigurationCenterPreviewCompositionHelperTests {

    @MainActor
    @Test("insertModule seeds the region draft and appends a projected module value")
    func insertModuleSeedsTheRegionDraftAndAppendsAProjectedModuleValue() {
        let subject =
            previewSubject()
        let helper =
            ConfigurationCenterPreviewCompositionHelper(
                context: .init(
                    subject: subject
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
                subject: subject
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
        let helper =
            ConfigurationCenterPreviewCompositionHelper(
                context: .init(
                    subject: previewSubject()
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
        let helper =
            ConfigurationCenterPreviewCompositionHelper(
                context: .init(
                    subject: previewSubject()
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
            ) == "记录这一天，途途11个月28天记得那一天"
        )
    }

    @MainActor
    @Test("moduleDisplayText and smartTimeResult preserve subject-aware smart-module projection")
    func moduleDisplayTextAndSmartTimeResultPreserveCurrentLocalFallbackProjection() {
        let subject =
            previewSubject()
        let helper =
            ConfigurationCenterPreviewCompositionHelper(
                context: .init(
                    subject: subject
                )
            )
        let fallbackHelper =
            ConfigurationCenterPreviewCompositionHelper(
                context: .init(subject: nil)
            )

        #expect(
            helper.moduleDisplayText(.subjectNickname)
            == subject.identity.shortName
        )
        #expect(
            helper.moduleDisplayText(.smartTime)
            == "这一天，途途11个月28天"
        )
        #expect(
            helper.moduleDisplayText(.location)
            == "河南 · 商丘"
        )
        #expect(
            fallbackHelper.smartTimeResult
            == "未设置时间"
        )
    }
}

private func previewSubject() -> MemorySubject {
    let birthday =
        Calendar.current.date(
            from: DateComponents(
                year: 2025,
                month: 5,
                day: 26
            )
        ) ?? Date()

    return MemorySubject(
        identity: .init(
            displayName: "王途途",
            shortName: "途途"
        ),
        relationship: .init(
            role: "宝宝",
            label: "妈妈眼里的宝宝"
        ),
        definition: "测试对象",
        referenceDate: birthday,
        timeAnchors: [
            .init(
                title: "生日",
                date: birthday,
                note: "出生日期",
                anchorType: .birthday
            )
        ],
        activeTimeAnchorID: nil,
        expressionSubjectSource: .shortName,
        behavior: MemoryBehavior(
            primaryAnchor: "生日",
            iconStrategy: .autoMatch,
            badgeStrategy: .autoMatch,
            memoryExpression: MemoryExpression(
                title: "生日记忆",
                blocks: [.text("生日智能模块")]
            )
        ),
        decorations: []
    )
}
#endif
