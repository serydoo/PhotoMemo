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

struct TimeDisplayInspectorOption: Identifiable, Hashable {
    let id: String
    let title: String
    let preview: String
    let configuration: TimeDisplayConfiguration
}

struct TimeDisplayInspectorPresentation: Equatable {
    let title: String
    let selectedValue: String
    let options: [TimeDisplayInspectorOption]
}

enum TimeDisplayInspectorPresenter {
    static let presentation = TimeDisplayInspectorPresentation(title: "时间显示", selectedValue: "日常记录", options: [
        option(.daily, "日常记录", "2026年7月29日 星期三 下午3:24"),
        option(.precise, "精确记录", "2026.07.29 15:24:36"),
        option(.minimal, "极简记录", "2026.07.29"),
        option(.photography, "摄影风格", "29 JUL 2026\n15:24"),
        option(.weekdayContext, "星期上下文", "2026年7月29日 周三")
    ])
    static func configuration(baseStyle: TimeDisplayConfiguration.BaseStyle, supplement: TimeDisplayConfiguration.Supplement) -> ExpressionModuleConfiguration {
        ExpressionModuleConfiguration(token: TimeExpressionProvider.timeToken, options: ["baseStyle": baseStyle.rawValue, "supplement": supplement.rawValue])
    }
    static func compose(base: String, lunar: String?, solarTerm: String?, holiday: String?, statutoryHoliday: String?, separator: String = " · ") -> String {
        TimeExpressionProvider.compose(base: base, lunar: lunar, solarTerm: solarTerm, holiday: holiday, statutoryHoliday: statutoryHoliday, separator: separator)
    }
    private static func option(_ style: TimeDisplayConfiguration.BaseStyle, _ title: String, _ preview: String) -> TimeDisplayInspectorOption {
        TimeDisplayInspectorOption(id: style.rawValue, title: title, preview: preview, configuration: TimeDisplayConfiguration(baseStyle: style))
    }
}
#endif
