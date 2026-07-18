#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct ConfigurationCenterLocationDisplaySelectionChange {

    let region: CardRegion
    let configuration: ExpressionModuleConfiguration
    let mutation: ConfigurationCenterRegionBindingMutation?
}

enum ConfigurationCenterLocationDisplaySupport {

    static func summaryValue(
        module: IOSInsertedModule?,
        presentation: LocationDisplayInspectorPresentation,
        selectedConfiguration:
            ExpressionModuleConfiguration? = nil
    ) -> String {
        if let module {
            return LocationDisplayInspectorPresenter
                .selectedValue(from: module)
        }

        if selectedConfiguration != nil {
            return LocationDisplayInspectorPresenter
                .selectedValue(
                    fromConfiguration:
                        selectedConfiguration
                )
        }

        return presentation.selectedValue
    }

    static func summaryDetail(
        module: IOSInsertedModule?,
        selectedValue: String
    ) -> String {
        guard module != nil else {
            return "当前未插入位置模块；已预选 \(selectedValue)，插入后生效。"
        }

        return "当前使用 \(selectedValue) 作为位置展示方式。"
    }

    static func selectionChange(
        optionID: String,
        region: CardRegion,
        module: IOSInsertedModule?,
        adapter: ConfigurationCenterRegionBindingAdapter
    ) -> ConfigurationCenterLocationDisplaySelectionChange {
        let configuration =
            LocationDisplayInspectorPresenter
            .configuration(for: optionID)

        return ConfigurationCenterLocationDisplaySelectionChange(
            region: region,
            configuration: configuration,
            mutation:
                module.map {
                    adapter.updateInsertedModule(
                        $0,
                        expressionConfiguration:
                            configuration
                    )
                }
        )
    }
}
#endif
