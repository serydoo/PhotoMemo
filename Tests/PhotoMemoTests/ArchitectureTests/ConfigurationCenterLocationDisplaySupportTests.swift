#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Configuration center location display support")
struct ConfigurationCenterLocationDisplaySupportTests {

    @Test("summary value falls back to the unavailable copy when the location module is missing")
    func summaryValueFallsBackToUnavailableCopy() {
        let presentation =
            LocationDisplayInspectorPresenter.presentation

        #expect(
            ConfigurationCenterLocationDisplaySupport
                .summaryValue(
                    module: nil,
                    presentation: presentation
                )
            == presentation.unavailableValue
        )
        #expect(
            ConfigurationCenterLocationDisplaySupport
                .summaryDetail(
                    module: nil,
                    selectedValue: presentation.unavailableValue
                )
                .contains("还没有插入位置模块")
        )
    }

    @Test("summary value can show a preselected display mode before the location module is inserted")
    func summaryValueShowsPreselectedModeBeforeModuleInsertion() {
        let presentation =
            LocationDisplayInspectorPresenter.presentation
        let configuration =
            LocationDisplayInspectorPresenter
            .configuration(for: "cityDistrict")

        #expect(
            ConfigurationCenterLocationDisplaySupport
                .summaryValue(
                    module: nil,
                    presentation: presentation,
                    selectedConfiguration: configuration
                )
            == "城市 · 区县"
        )
        #expect(
            ConfigurationCenterLocationDisplaySupport
                .summaryDetail(
                    module: nil,
                    selectedValue: "城市 · 区县"
                )
                .contains("还没有插入位置模块")
        )
    }

    @Test("selection change keeps the requested region and updates the location module configuration")
    func selectionChangeKeepsRequestedRegion() throws {
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
                value: "河南 · 商丘",
                systemImage: IOSInsertableModule.location.systemImage
            )
        store.setText("", for: .slotC)
        store.setModules([insertedModule], for: .slotC)

        let adapter =
            ConfigurationCenterRegionBindingAdapter(
                region: .slotC,
                subject: subject,
                store: store,
                coordinator:
                    .init(previewHelper: helper)
            )

        let change = try #require(
            ConfigurationCenterLocationDisplaySupport
                .selectionChange(
                    optionID: "provinceCityDistrict",
                    region: .slotC,
                    module: insertedModule,
                    adapter: adapter
                )
        )
        let updatedModule = try #require(
            change.mutation.store.modules(for: .slotC).first
        )

        #expect(change.region == CardRegion.slotC)
        #expect(
            updatedModule.expressionConfiguration
            == LocationDisplayInspectorPresenter
                .configuration(for: "provinceCityDistrict")
        )
        #expect(updatedModule.value == "河南 · 商丘 · 永城")
    }
}
#endif
