#if !PHOTOMEMO_SHARE_EXTENSION
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
        memoryWritePresentation: MemoryWriteOptionPresentation
    ) -> ConfigurationCenterOutputPanelPresentation {
        ConfigurationCenterOutputPanelPresentation(
            outputTitle: outputOption.title,
            outputNote: outputOption.note,
            metadataTitle: "保留全部元数据",
            metadataNote: "默认尽可能保留原图中的可用元数据，再生成 1 张新的处理结果图片。",
            storageTitle: storageOption.title,
            storageNote: storageOption.note,
            memoryWriteTitle: memoryWritePresentation.resolvedTitle,
            memoryWriteDescription: memoryWritePresentation.resolvedDescription,
            memoryWriteNote: memoryWritePresentation.fallbackNote,
            memoryWriteActionTitle: "进入智能模块"
        )
    }
}
#endif
