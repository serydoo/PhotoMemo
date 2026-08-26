#if !MEMOMARK_SHARE_EXTENSION
import Foundation

@MainActor
enum ConfigurationCenterSessionBindingPresenter {

    static let memoryWriteToggleTitle =
        "补充一段话"

    static let customMemoryWritePlaceholder =
        "写下想补充的话"

    private static func presetStatusFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale =
            MemoMarkLanguage.interfaceStored.locale
        formatter.dateFormat =
            MemoMarkLanguage.interfaceStored == .english
            ? "MMM d, yyyy HH:mm"
            : "yyyy年M月d日 HH:mm"
        return formatter
    }

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
            return "会把这段回忆和你补充的话一起写进照片说明。"
        }

        return "会把照片中的记忆表达完整写进照片说明。"
    }

    static func memoryWritePreviewTitle(
        session: ConfigurationSession
    ) -> String {
        "即将写下的内容"
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
            ?? presetStatusFormatter().string(
                from: savedAt
            )

        return "最近保存于 \(formattedSavedAt)"
    }
}
#endif
