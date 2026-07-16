#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Configuration center region binding adapter")
struct ConfigurationCenterRegionBindingAdapterTests {

    @Test("setText updates the draft store and recomputes preview text")
    func setTextUpdatesStoreAndPreviewText() {
        let subject = ConfigurationCenterState.mock.selectedSubject
        let helper =
            ConfigurationCenterPreviewCompositionHelper(
                context: .init(subject: subject)
            )
        let adapter =
            ConfigurationCenterRegionBindingAdapter(
                region: .slotD,
                subject: subject,
                store: .init(),
                coordinator:
                    .init(previewHelper: helper)
            )

        let mutation =
            adapter.setText("新的记忆内容")

        #expect(
            mutation.store.text(
                for: .slotD,
                subject: subject
            ) == "新的记忆内容"
        )
        #expect(
            mutation.previewText
            == helper.composedPreviewText(
                for: .slotD,
                store: mutation.store
            )
        )
    }

    @Test("setConfigurationName updates only store state")
    func setConfigurationNameUpdatesOnlyStoreState() {
        let subject = ConfigurationCenterState.mock.selectedSubject
        let adapter =
            ConfigurationCenterRegionBindingAdapter(
                region: .slotA,
                subject: subject,
                store: .init(),
                coordinator:
                    .init(
                        previewHelper:
                            .init(context: .init(subject: subject))
                    )
            )

        let mutation =
            adapter.setConfigurationName("配置 1：旅行记录")

        #expect(
            mutation.store.configurationName(for: .slotA)
            == "配置 1：旅行记录"
        )
        #expect(mutation.previewText == nil)
    }

    @Test("setRenamingConfiguration toggles rename state without preview recomposition")
    func setRenamingConfigurationUpdatesOnlyStoreState() {
        let subject = ConfigurationCenterState.mock.selectedSubject
        let adapter =
            ConfigurationCenterRegionBindingAdapter(
                region: .slotB,
                subject: subject,
                store: .init(),
                coordinator:
                    .init(
                        previewHelper:
                            .init(context: .init(subject: subject))
                    )
            )

        let mutation =
            adapter.setRenamingConfiguration(true)

        #expect(
            mutation.store.isRenamingConfiguration(for: .slotB)
        )
        #expect(mutation.previewText == nil)
    }

    @Test("insertModule returns nil for non-memory-card regions")
    func insertModuleSkipsNonMemoryCardRegions() {
        let subject = ConfigurationCenterState.mock.selectedSubject
        let adapter =
            ConfigurationCenterRegionBindingAdapter(
                region: .icon,
                subject: subject,
                store: .init(),
                coordinator:
                    .init(
                        previewHelper:
                            .init(context: .init(subject: subject))
                    )
            )

        let mutation =
            adapter.insertModule(.captureDate)

        #expect(mutation == nil)
    }

    @Test("insertModule forwards expression configuration into the stored inserted module")
    func insertModuleForwardsExpressionConfigurationIntoStoredInsertedModule() throws {
        let subject = ConfigurationCenterState.mock.selectedSubject
        let helper =
            ConfigurationCenterPreviewCompositionHelper(
                context: .init(subject: subject)
            )
        let adapter =
            ConfigurationCenterRegionBindingAdapter(
                region: .slotC,
                subject: subject,
                store: .init(),
                coordinator:
                    .init(previewHelper: helper)
            )
        let configuration =
            ExpressionModuleConfiguration(
                token: LocationExpressionProvider.locationToken,
                options: [
                    "allowsCoordinateFallback": "true"
                ]
            )

        let mutation =
            try #require(
                adapter.insertModule(
                    .location,
                    expressionConfiguration: configuration
                )
            )

        #expect(
            mutation.store.modules(for: .slotC).first?
                .expressionConfiguration == configuration
        )
        #expect(
            mutation.previewText
            == helper.composedPreviewText(
                for: .slotC,
                store: mutation.store
            )
        )
    }

    @Test("updateInsertedModule writes location display configuration and recomputes preview")
    func updateInsertedModuleWritesLocationDisplayConfigurationAndRecomputesPreview() throws {
        let subject = ConfigurationCenterState.mock.selectedSubject
        let helper =
            ConfigurationCenterPreviewCompositionHelper(
                context: .init(subject: subject)
            )
        var store =
            ConfigurationCenterRegionDraftStore()
        let insertedModule =
            IOSInsertedModule(
                title: IOSInsertableModule.location.title,
                value: "示例省 · 示例市",
                systemImage: IOSInsertableModule.location.systemImage
            )
        store.setText("", for: .slotC)
        store.setModules(
            [insertedModule],
            for: .slotC
        )
        let adapter =
            ConfigurationCenterRegionBindingAdapter(
                region: .slotC,
                subject: subject,
                store: store,
                coordinator:
                    .init(previewHelper: helper)
            )
        let configuration =
            LocationDisplayInspectorPresenter
            .configuration(
                for: "provinceCityDistrict"
            )

        let mutation =
            adapter.updateInsertedModule(
                insertedModule,
                expressionConfiguration:
                    configuration
            )
        let updatedModule =
            try #require(
                mutation.store.modules(for: .slotC).first
            )

        #expect(
            updatedModule.expressionConfiguration == configuration
        )
        #expect(updatedModule.value == "示例省 · 示例市 · 示例区")
        #expect(
            mutation.previewText
            == helper.composedPreviewText(
                for: .slotC,
                store: mutation.store
            )
        )
    }

    @Test("updateInsertedModule ignores non-location modules")
    func updateInsertedModuleIgnoresNonLocationModules() throws {
        let subject = ConfigurationCenterState.mock.selectedSubject
        let helper =
            ConfigurationCenterPreviewCompositionHelper(
                context: .init(subject: subject)
            )
        var store =
            ConfigurationCenterRegionDraftStore()
        let insertedModule =
            IOSInsertedModule(
                title: IOSInsertableModule.smartTime.title,
                value: "1岁2个月18天",
                systemImage: IOSInsertableModule.smartTime.systemImage
            )
        store.setText("", for: .slotD)
        store.setModules(
            [insertedModule],
            for: .slotD
        )
        let adapter =
            ConfigurationCenterRegionBindingAdapter(
                region: .slotD,
                subject: subject,
                store: store,
                coordinator:
                    .init(previewHelper: helper)
            )
        let configuration =
            LocationDisplayInspectorPresenter
            .configuration(
                for: "provinceCityDistrict"
            )

        let mutation =
            adapter.updateInsertedModule(
                insertedModule,
                expressionConfiguration:
                    configuration
            )
        let updatedModule =
            try #require(
                mutation.store.modules(for: .slotD).first
            )

        #expect(updatedModule == insertedModule)
        #expect(
            mutation.previewText
            == helper.composedPreviewText(
                for: .slotD,
                store: store
            )
        )
    }

    @Test("removeInsertedModule recomputes preview text from the updated store")
    func removeInsertedModuleRecomputesPreviewText() {
        let subject = ConfigurationCenterState.mock.selectedSubject
        let helper =
            ConfigurationCenterPreviewCompositionHelper(
                context: .init(subject: subject)
            )
        var store =
            ConfigurationCenterRegionDraftStore()
        let insertedModule =
            IOSInsertedModule(
                title: "拍摄日期",
                value: "2026.06.01",
                systemImage: "calendar"
            )
        store.setText("记录于", for: .slotB)
        store.setModules([insertedModule], for: .slotB)

        let adapter =
            ConfigurationCenterRegionBindingAdapter(
                region: .slotB,
                subject: subject,
                store: store,
                coordinator:
                    .init(previewHelper: helper)
            )

        let mutation =
            adapter.removeInsertedModule(insertedModule)

        #expect(
            mutation.store.modules(for: .slotB).isEmpty
        )
        #expect(
            mutation.previewText
            == helper.composedPreviewText(
                for: .slotB,
                store: mutation.store
            )
        )
    }
}
#endif
