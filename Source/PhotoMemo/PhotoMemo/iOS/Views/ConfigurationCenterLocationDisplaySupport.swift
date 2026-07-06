#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct ConfigurationCenterLocationDisplaySelectionChange {

    let region: CardRegion
    let mutation: ConfigurationCenterRegionBindingMutation
}

enum ConfigurationCenterLocationDisplaySupport {

    static func summaryValue(
        module: IOSInsertedModule?,
        presentation: LocationDisplayInspectorPresentation
    ) -> String {
        guard let module else {
            return presentation.unavailableValue
        }

        return LocationDisplayInspectorPresenter
            .selectedValue(from: module)
    }

    static func summaryDetail(
        module: IOSInsertedModule?,
        selectedValue: String
    ) -> String {
        guard module != nil else {
            return "当前生效配置里还没有插入位置模块，可在 C 区加入后再切换展示方式。"
        }

        return "当前使用 \(selectedValue) 作为位置展示方式。"
    }

    static func selectionChange(
        optionID: String,
        region: CardRegion,
        module: IOSInsertedModule?,
        adapter: ConfigurationCenterRegionBindingAdapter
    ) -> ConfigurationCenterLocationDisplaySelectionChange? {
        guard let module else {
            return nil
        }

        return ConfigurationCenterLocationDisplaySelectionChange(
            region: region,
            mutation: adapter.updateInsertedModule(
                module,
                expressionConfiguration:
                    LocationDisplayInspectorPresenter
                    .configuration(for: optionID)
            )
        )
    }
}
#endif
