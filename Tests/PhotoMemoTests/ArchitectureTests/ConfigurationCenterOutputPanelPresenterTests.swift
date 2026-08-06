#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Configuration center output panel presenter")
struct ConfigurationCenterOutputPanelPresenterTests {

    @Test("builds fixed output and metadata copy while carrying the selected storage and smart-module summary")
    func presentationCarriesOutputStorageAndSmartModuleSummary() {
        let memoryWritePresentation =
            MemoryWriteOptionPresenter
            .presentation(
                usesCustomText: false,
                resolvedText: "记录于｜2026.07.01｜还有 86 天",
                language: .simplifiedChinese
            )

        let presentation =
            ConfigurationCenterOutputPanelPresenter
            .presentation(
                outputOption: .processedImage,
                storageOption: .targetAlbum,
                memoryWritePresentation:
                    memoryWritePresentation
            )

        #expect(presentation.outputTitle == "处理过的图片")
        #expect(presentation.outputNote == "生成新图片，不修改原始照片。")
        #expect(presentation.metadataTitle == "保留全部元数据")
        #expect(
            presentation.metadataNote
                .contains("可用元数据")
        )
        #expect(presentation.storageTitle == "目标相册")
        #expect(
            presentation.storageNote
            == "后续写入指定 Apple Photos 相册。"
        )
        #expect(
            presentation.memoryWriteTitle
            == "即将写下的内容"
        )
        #expect(
            presentation.memoryWriteDescription
            == "记录于｜2026.07.01｜还有 86 天"
        )
        #expect(
            presentation.memoryWriteNote
            == "会根据拍摄时间、记忆对象和时间锚点，写入对应的记忆表达。"
        )
        #expect(
            presentation.memoryWriteActionTitle
            == "进入智能模块"
        )
    }

    @Test("custom memory-write copy flows through the output panel summary")
    func presentationReflectsCustomMemoryWriteState() {
        let memoryWritePresentation =
            MemoryWriteOptionPresenter
            .presentation(
                usesCustomText: true,
                resolvedText: "宝宝周岁纪念说明",
                language: .simplifiedChinese
            )

        let presentation =
            ConfigurationCenterOutputPanelPresenter
            .presentation(
                outputOption: .processedImage,
                storageOption: .appFolder,
                memoryWritePresentation:
                    memoryWritePresentation
            )

        #expect(presentation.storageTitle == "时光记文件夹")
        #expect(
            presentation.memoryWriteTitle
            == "即将写下的内容"
        )
        #expect(
            presentation.memoryWriteDescription
            == "宝宝周岁纪念说明"
        )
        #expect(
            presentation.memoryWriteNote
            == "包含这段回忆和你补充的话。"
        )
    }
}
#endif
