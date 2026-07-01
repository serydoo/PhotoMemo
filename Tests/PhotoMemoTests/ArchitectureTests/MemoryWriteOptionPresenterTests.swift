#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Memory write option presenter")
struct MemoryWriteOptionPresenterTests {

    @Test("uses custom text wording when separate entry is enabled")
    func customEntryEnabledCopy() {
        let presentation =
            MemoryWriteOptionPresenter
            .presentation(
                usesCustomText: true,
                resolvedText: "宝宝已经 1 岁 2 个月"
            )

        #expect(
            presentation.toggleTitle
            == "单独录入相册说明"
        )
        #expect(
            presentation.toggleDescription
            == "开启后，优先写入你单独录入的内容；关闭后，默认写入当前生成的智能模块结果。"
        )
        #expect(
            presentation.inputPlaceholder
            == "输入想单独写入 Apple Photos 说明栏的文字"
        )
        #expect(
            presentation.resolvedTitle
            == "实际写入"
        )
        #expect(
            presentation.resolvedDescription
            == "宝宝已经 1 岁 2 个月"
        )
        #expect(
            presentation.fallbackNote
            == "关闭后，默认写入当前生成的智能模块完整结果。"
        )
    }

    @Test("uses smart-module fallback wording when separate entry is disabled")
    func customEntryDisabledCopy() {
        let presentation =
            MemoryWriteOptionPresenter
            .presentation(
                usesCustomText: false,
                resolvedText: "记录于｜2026.07.01｜还有 86 天"
            )

        #expect(
            presentation.toggleTitle
            == "单独录入相册说明"
        )
        #expect(
            presentation.resolvedTitle
            == "默认写入（当前智能模块）"
        )
        #expect(
            presentation.resolvedDescription
            == "记录于｜2026.07.01｜还有 86 天"
        )
        #expect(
            presentation.fallbackNote
            == "未开启单独录入时，将默认写入当前生成的智能模块完整结果。"
        )
    }
}
#endif
