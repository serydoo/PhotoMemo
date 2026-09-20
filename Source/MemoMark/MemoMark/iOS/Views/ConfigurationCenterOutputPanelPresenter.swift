#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct ConfigurationCenterOutputPanelPresentation:
    Equatable {

    let outputTitle: String
    let outputNote: String
    let metadataTitle: String
    let metadataNote: String
    let storageTitle: String
    let storageNote: String
    let memoryWriteTitle: String
    let memoryWriteDescription: String
    let memoryWriteNote: String
    let memoryWriteActionTitle: String
}

enum ConfigurationCenterOutputPanelPresenter {

    static func presentation(
        outputOption: ConfigurationOutputOption,
        storageOption: ConfigurationStorageOption,
        memoryWritePresentation: MemoryWriteOptionPresentation,
        presentationStyle: RecordCardPresentationStyle = .classicWhite,
        language: MemoMarkLanguage = .interfaceStored
    ) -> ConfigurationCenterOutputPanelPresentation {
        ConfigurationCenterOutputPanelPresentation(
            outputTitle: outputOption.title,
            outputNote: outputOption.note,
            metadataTitle: language.localized(
                key: "configuration.output.metadata",
                fallback: "保留照片信息"
            ),
            metadataNote: metadataNote(
                for: presentationStyle,
                language: language
            ),
            storageTitle: storageOption.title,
            storageNote: storageOption.note,
            memoryWriteTitle: memoryWritePresentation.resolvedTitle,
            memoryWriteDescription: memoryWritePresentation.resolvedDescription,
            memoryWriteNote: memoryWritePresentation.fallbackNote,
            memoryWriteActionTitle: language.localized(
                key: "configuration.output.memory_write_action",
                fallback: "编辑卡片内容"
            )
        )
    }

    private static func metadataNote(
        for presentationStyle: RecordCardPresentationStyle,
        language: MemoMarkLanguage
    ) -> String {
        let key: String
        let fallback: String

        switch presentationStyle {
        case .classicWhite:
            key = "configuration.output.metadata.note.classic_white"
            fallback = "尽可能保留可用的 EXIF 与拍摄信息；基础白会增加白色信息栏，输出画布尺寸会随之调整。RAW 等源格式会生成新的照片结果，原始照片不被修改。"
        case .minimal:
            key = "configuration.output.metadata.note.minimal"
            fallback = "尽可能保留可用的 EXIF 与拍摄信息；极简样式在原照片画布内叠加信息，不增加底部白边。RAW 等源格式会生成新的照片结果，原始照片不被修改。"
        case .filmMark:
            key = "configuration.output.metadata.note.film_mark"
            fallback = "尽可能保留可用的 EXIF 与拍摄信息；胶片样式会在原照片画布内叠加文字，字体、位置与衬底按当前设置写入。RAW 等源格式会生成新的照片结果，原始照片不被修改。"
        }

        return language.localized(
            key: key,
            fallback: fallback
        )
    }
}
#endif
