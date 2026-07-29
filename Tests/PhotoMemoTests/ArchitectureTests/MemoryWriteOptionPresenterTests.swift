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
            == "补充一句话"
        )
        #expect(
            presentation.toggleDescription
            == "把想补充的话，写在照片说明里。"
        )
        #expect(presentation.defaultContentTitle == "照片说明")
        #expect(
            presentation.defaultContentDescription
            == "把这段回忆写进照片说明，方便之后在 Apple Photos 中找到它。"
        )
        #expect(
            presentation.inputPlaceholder
            == "写下想补充的话"
        )
        #expect(
            presentation.resolvedTitle
            == "即将写下的内容"
        )
        #expect(
            presentation.resolvedDescription
            == "宝宝已经 1 岁 2 个月"
        )
        #expect(
            presentation.fallbackNote
            == "包含这段回忆和你补充的话。"
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
            == "补充一句话"
        )
        #expect(
            presentation.toggleDescription
            == "把想补充的话，写在照片说明里。"
        )
        #expect(presentation.defaultContentTitle == "照片说明")
        #expect(
            presentation.defaultContentDescription
            == "把这段回忆写进照片说明，方便之后在 Apple Photos 中找到它。"
        )
        #expect(
            presentation.resolvedTitle
            == "即将写下的内容"
        )
        #expect(
            presentation.resolvedDescription
            == "记录于｜2026.07.01｜还有 86 天"
        )
        #expect(
            presentation.fallbackNote
            == "会根据照片拍摄时间、记忆对象和时间锚点写下这段回忆。"
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

        #expect(presentation.toggleTitle == "Add a Personal Note")
        #expect(presentation.defaultContentTitle == "Photo Description")
        #expect(presentation.resolvedTitle == "What Will Be Written")
        #expect(presentation.resolvedDescription == resolvedText)
        #expect(
            presentation.fallbackNote
            == "Includes this memory and your added words."
        )
    }
}
#endif
