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
                resolvedText: "宝宝已经 1 岁 2 个月"
            )

        #expect(
            presentation.toggleTitle
            == "添加自定义内容"
        )
        #expect(
            presentation.toggleDescription
            == "开启后，将下方内容补充到智能模块结果之后。"
        )
        #expect(
            presentation.inputPlaceholder
            == "输入补充到智能模块结果后的内容"
        )
        #expect(
            presentation.resolvedTitle
            == "完整写入（智能模块 + 自定义）"
        )
        #expect(
            presentation.resolvedDescription
            == "宝宝已经 1 岁 2 个月"
        )
        #expect(
            presentation.fallbackNote
            == "自定义内容不会覆盖智能模块结果。"
        )
    }

    @Test("uses smart-module wording when memory write is enabled")
    func customEntryDisabledCopy() {
        let presentation =
            MemoryWriteOptionPresenter
            .presentation(
                usesCustomText: false,
                resolvedText: "记录于｜2026.07.01｜还有 86 天"
            )

        #expect(
            presentation.toggleTitle
            == "添加自定义内容"
        )
        #expect(
            presentation.toggleDescription
            == "默认仅写入当前智能模块结果。"
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
            == "智能模块会结合拍摄时间、记忆对象和时间锚点生成说明。"
        )
    }
}
#endif
