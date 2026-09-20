#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Configuration center output panel presenter")
struct ConfigurationCenterOutputPanelPresenterTests {

    @Test("builds output and renderer-specific metadata copy")
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
                    memoryWritePresentation,
                language: .simplifiedChinese
            )

        #expect(presentation.outputTitle == "处理过的图片")
        #expect(presentation.outputNote == "生成新图片，不修改原始照片。")
        #expect(presentation.metadataTitle == "保留照片信息")
        #expect(
            presentation.metadataNote
                .contains("基础白会增加白色信息栏")
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
            == "会根据拍摄日期与时间锚点的差值，结合记忆对象，写入对应的记忆表达。"
        )
        #expect(presentation.memoryWriteActionTitle == "编辑卡片内容")
    }

    @Test("uses a different metadata explanation for Minimal")
    func presentationUsesMinimalMetadataCopy() {
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
                storageOption: .appFolder,
                memoryWritePresentation: memoryWritePresentation,
                presentationStyle: .minimal,
                language: .simplifiedChinese
            )

        #expect(presentation.metadataTitle == "保留照片信息")
        #expect(
            presentation.metadataNote
                .contains("不增加底部白边")
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
                    memoryWritePresentation,
                language: .simplifiedChinese
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
