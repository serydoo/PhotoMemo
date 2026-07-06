#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct LocationDisplayInspectorOption:
    Identifiable,
    Hashable {

    let id: String
    let title: String
    let note: String?
    let configuration:
        ExpressionModuleConfiguration
}

struct LocationDisplayInspectorPresentation:
    Equatable {

    let title: String
    let unavailableValue: String
    let selectedValue: String
    let systemImage: String
    let options: [LocationDisplayInspectorOption]
}

enum LocationDisplayInspectorPresenter {

    static let presentation =
        LocationDisplayInspectorPresentation(
            title: "位置显示",
            unavailableValue: "位置模块未插入",
            selectedValue: "自动兼容",
            systemImage: "location",
            options: [
                option(
                    id: "legacyDisplay",
                    title: "自动兼容",
                    note:
                        "根据照片中的位置数据自动选择最佳显示方式。"
                ),
                option(
                    id: "provinceCity",
                    title: "省份 · 城市"
                ),
                option(
                    id: "cityDistrict",
                    title: "城市 · 区县"
                ),
                option(
                    id: "provinceCityDistrict",
                    title: "省份 · 城市 · 区县"
                ),
                option(
                    id: "coordinate",
                    title: "经纬度"
                )
            ]
        )

    static func selectedOptionID(
        from module: IOSInsertedModule?
    ) -> String {
        selectedOptionID(
            fromConfiguration:
                module?
                .expressionConfiguration
        )
    }

    static func selectedOptionID(
        fromConfiguration configuration:
            ExpressionModuleConfiguration?
    ) -> String {
        let mode =
            configuration?
            .options["presentationMode"]

        guard
            let mode,
            presentation
                .options
                .contains(where: { $0.id == mode })
        else {
            return "legacyDisplay"
        }

        return mode
    }

    static func selectedValue(
        from module: IOSInsertedModule?
    ) -> String {
        selectedValue(
            fromConfiguration:
                module?
                .expressionConfiguration
        )
    }

    static func selectedValue(
        fromConfiguration configuration:
            ExpressionModuleConfiguration?
    ) -> String {
        let selectedID =
            selectedOptionID(
                fromConfiguration:
                    configuration
            )

        return presentation
            .options
            .first(where: { $0.id == selectedID })?
            .title
        ?? presentation.selectedValue
    }

    static func configuration(
        for optionID: String
    ) -> ExpressionModuleConfiguration {
        presentation
            .options
            .first(where: { $0.id == optionID })?
            .configuration
        ?? presentation.options[0].configuration
    }

    private static func option(
        id: String,
        title: String,
        note: String? = nil
    ) -> LocationDisplayInspectorOption {
        LocationDisplayInspectorOption(
            id: id,
            title: title,
            note: note,
            configuration:
                ExpressionModuleConfiguration(
                    token:
                        LocationExpressionProvider.locationToken,
                    options: [
                        "presentationMode": id
                    ]
                )
        )
    }
}
#endif
