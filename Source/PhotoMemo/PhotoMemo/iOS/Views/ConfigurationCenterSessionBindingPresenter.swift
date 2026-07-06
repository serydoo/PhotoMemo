#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

@MainActor
enum ConfigurationCenterSessionBindingPresenter {

    static let memoryWriteToggleTitle =
        "单独录入相册说明"

    static let customMemoryWritePlaceholder =
        "输入要单独写入图库说明的文字"

    private static let presetStatusFormatter:
        DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale =
                Locale(identifier: "zh_CN")
            formatter.dateFormat =
                "yyyy.MM.dd HH:mm"
            return formatter
        }()

    static func profileTitle(
        session: ConfigurationSession
    ) -> String {
        session.currentMemoryPresetTitle
    }

    static func setProfileTitle(
        _ title: String,
        session: ConfigurationSession
    ) {
        session.updateSelectedMemoryPresetTitle(title)
    }

    static func selectedStorageOption(
        session: ConfigurationSession
    ) -> ConfigurationStorageOption {
        session.selectedStorageOption
    }

    static func setSelectedStorageOption(
        _ option: ConfigurationStorageOption,
        session: ConfigurationSession
    ) {
        session.selectedStorageOption = option
    }

    static func usesCustomMemoryWriteText(
        session: ConfigurationSession
    ) -> Bool {
        session.usesCustomMemoryWriteText
    }

    static func setUsesCustomMemoryWriteText(
        _ usesCustomText: Bool,
        session: ConfigurationSession
    ) {
        session.usesCustomMemoryWriteText = usesCustomText
    }

    static func customMemoryWriteText(
        session: ConfigurationSession
    ) -> String {
        session.customMemoryWriteText
    }

    static func setCustomMemoryWriteText(
        _ text: String,
        session: ConfigurationSession
    ) {
        session.customMemoryWriteText = text
    }

    static func memoryWriteDescription(
        session: ConfigurationSession
    ) -> String {
        if session.usesCustomMemoryWriteText {
            return "开启后，会把你单独录入的文字写入相册说明。关闭时，默认写入当前生成的智能模块完整结果。"
        }

        return "当前未单独录入文字，默认会把当前生成的智能模块完整结果写入相册说明。"
    }

    static func memoryWritePreviewTitle(
        session: ConfigurationSession
    ) -> String {
        session.usesCustomMemoryWriteText
        ? "实际写入"
        : "默认写入（当前智能模块）"
    }

    static func presetStatusText(
        session: ConfigurationSession,
        savedAtFormatter: ((Date) -> String)? = nil
    ) -> String {
        guard let savedAt =
            session.state
            .selectedMemoryPreset?
            .savedAt else {
            return "当前生效配置尚未保存"
        }

        let formattedSavedAt =
            savedAtFormatter?(savedAt)
            ?? presetStatusFormatter.string(
                from: savedAt
            )

        return "最近保存于 \(formattedSavedAt)"
    }
}
#endif
