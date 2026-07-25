#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Memory write option presenter")
struct MemoryWriteOptionPresenterTests {

    @Test("uses supplemental wording when custom content is enabled")
    func customEntryEnabledCopy() {
        let presentation =
            MemoryWriteOptionPresenter
            .presentation(
                usesCustomText: true,
                resolvedText: "宝宝已经 1 岁 2 个月",
                language: .simplifiedChinese
            )

        #expect(
            presentation.toggleTitle
            == "添加自定义内容"
        )
        #expect(
            presentation.toggleDescription
            == "开启后，将用户自定义内容追加写入生成照片的说明文本，不会覆盖智能模块输出。"
        )
        #expect(presentation.defaultContentTitle == "默认写入内容")
        #expect(
            presentation.defaultContentDescription
            == "将当前智能模块输出写入生成照片的说明文本，便于在 Apple Photos 中检索。"
        )
        #expect(
            presentation.inputPlaceholder
            == "输入补充到智能模块结果后的内容"
        )
        #expect(
            presentation.resolvedTitle
            == "写入预览"
        )
        #expect(
            presentation.resolvedDescription
            == "宝宝已经 1 岁 2 个月"
        )
        #expect(
            presentation.fallbackNote
            == "包含当前智能模块输出与自定义内容。"
        )
    }

    @Test("uses smart-module wording when memory write is enabled")
    func customEntryDisabledCopy() {
        let presentation =
            MemoryWriteOptionPresenter
            .presentation(
                usesCustomText: false,
                resolvedText: "记录于｜2026.07.01｜还有 86 天",
                language: .simplifiedChinese
            )

        #expect(
            presentation.toggleTitle
            == "添加自定义内容"
        )
        #expect(
            presentation.toggleDescription
            == "开启后，将用户自定义内容追加写入生成照片的说明文本，不会覆盖智能模块输出。"
        )
        #expect(presentation.defaultContentTitle == "默认写入内容")
        #expect(
            presentation.defaultContentDescription
            == "将当前智能模块输出写入生成照片的说明文本，便于在 Apple Photos 中检索。"
        )
        #expect(
            presentation.resolvedTitle
            == "写入预览"
        )
        #expect(
            presentation.resolvedDescription
            == "记录于｜2026.07.01｜还有 86 天"
        )
        #expect(
            presentation.fallbackNote
            == "由当前智能模块根据拍摄时间、记忆对象和时间锚点生成。"
        )
    }

    @Test("localizes interface copy without translating resolved content")
    func englishInterfaceCopy() {
        let resolvedText = "宝宝已经 1 岁 2 个月"
        let presentation = MemoryWriteOptionPresenter.presentation(
            usesCustomText: true,
            resolvedText: resolvedText,
            language: .english
        )

        #expect(presentation.toggleTitle == "Add Custom Text")
        #expect(presentation.defaultContentTitle == "Default Content")
        #expect(presentation.resolvedTitle == "Description Preview")
        #expect(presentation.resolvedDescription == resolvedText)
        #expect(
            presentation.fallbackNote
            == "Includes the current smart-module output and your custom text."
        )
    }
}
#endif
