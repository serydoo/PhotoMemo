#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Configuration center location display support")
struct ConfigurationCenterLocationDisplaySupportTests {

    @Test("summary value defaults to automatic compatibility before module insertion")
    func summaryValueDefaultsBeforeModuleInsertion() {
        let presentation =
            LocationDisplayInspectorPresenter.presentation

        #expect(
            ConfigurationCenterLocationDisplaySupport
                .summaryValue(
                    module: nil,
                    presentation: presentation
                )
            == presentation.selectedValue
        )
        #expect(
            ConfigurationCenterLocationDisplaySupport
                .summaryDetail(
                    module: nil,
                    selectedValue: presentation.selectedValue
                )
                .contains("插入后生效")
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
                .contains("插入后生效")
        )
    }

    @Test("active configuration root persists selected location display configuration")
    func activeConfigurationRootPersistsSelectedLocationDisplayConfiguration() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView.swift"
        )
        let pagesSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView+Pages.swift"
        )
        let bindingsSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView+Bindings.swift"
        )
        let combinedSource = source + pagesSource + bindingsSource
        let bindingStart = try #require(
            bindingsSource.range(of: "var locationDisplayOptionBinding")?
                .lowerBound
        )
        let bindingEnd = try #require(
            bindingsSource.range(
                of: "var timeDisplayOptionBinding",
                range: bindingStart..<bindingsSource.endIndex
            )?.lowerBound
        )
        let bindingSource = String(bindingsSource[bindingStart..<bindingEnd])

        #expect(
            combinedSource.contains(
                "selectedLocationOptionID:\n                locationDisplayOptionBinding"
            )
        )
        #expect(
            bindingSource.contains(
                ".selectedOptionID(\n                        fromConfiguration:\n                            locationDisplayConfiguration"
            )
        )
        #expect(bindingSource.contains("locationDisplayConfiguration ="))
        #expect(combinedSource.contains(".saveLocationDisplayConfiguration("))
        #expect(combinedSource.contains("activeConfigurationStatus = .dirty"))
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
                value: "示例省 · 示例市",
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

        let change =
            ConfigurationCenterLocationDisplaySupport
                .selectionChange(
                    optionID: "provinceCityDistrict",
                    region: .slotC,
                    module: insertedModule,
                    adapter: adapter
                )
        let mutation = try #require(change.mutation)
        let updatedModule = try #require(
            mutation.store.modules(for: .slotC).first
        )

        #expect(change.region == CardRegion.slotC)
        #expect(
            change.configuration
            == LocationDisplayInspectorPresenter
                .configuration(for: "provinceCityDistrict")
        )
        #expect(
            mutation.store.modules(for: .slotC)
                .first?
                .expressionConfiguration
            == LocationDisplayInspectorPresenter
                .configuration(for: "provinceCityDistrict")
        )
        #expect(updatedModule.value == "示例省 · 示例市 · 示例区")
    }

    @Test("selection change preserves a display preselection before the location module is inserted")
    func selectionChangePreselectsWithoutLocationModule() throws {
        let subject = ConfigurationCenterState.mock.selectedSubject
        let helper =
            ConfigurationCenterPreviewCompositionHelper(
                context: .init(subject: subject)
            )
        let adapter =
            ConfigurationCenterRegionBindingAdapter(
                region: .slotC,
                subject: subject,
                store: ConfigurationCenterRegionDraftStore(),
                coordinator:
                    .init(previewHelper: helper)
            )

        let change = ConfigurationCenterLocationDisplaySupport
            .selectionChange(
                optionID: "cityDistrict",
                region: .slotC,
                module: nil,
                adapter: adapter
            )

        #expect(change.region == CardRegion.slotC)
        #expect(
            change.configuration
            == LocationDisplayInspectorPresenter
                .configuration(for: "cityDistrict")
        )
        #expect(change.mutation == nil)
    }

    @Test("configuration center location pickers stay enabled before module insertion")
    func locationPickersStayEnabledBeforeModuleInsertion() throws {
        let summarySource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterSummarySection.swift"
        )
        let detailSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterDetailSupportPanels.swift"
        )
        let activeRootSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView.swift"
        )
        let pagesSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView+Pages.swift"
        )
        let bindingsSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView+Bindings.swift"
        )
        let combinedSource = activeRootSource + pagesSource + bindingsSource

        #expect(!summarySource.contains(".disabled(isLocationSelectable == false)"))
        #expect(!detailSource.contains(".disabled(locationModule == nil)"))
        #expect(!activeRootSource.contains(".disabled(!isLocationSelectable)"))
        #expect(combinedSource.contains("selectedLocationOptionID:"))
        #expect(combinedSource.contains("locationDisplayOptionBinding"))
        #expect(combinedSource.contains(".saveLocationDisplayConfiguration("))
    }
}

private extension ConfigurationCenterLocationDisplaySupportTests {

    func sourceText(_ relativePath: String) throws -> String {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf:
                repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}
#endif
