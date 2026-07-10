#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Memory write option presenter")
struct MemoryWriteOptionPresenterTests {

    @Test("uses replacement wording when smart memory write is disabled")
    func customEntryEnabledCopy() {
        let presentation =
            MemoryWriteOptionPresenter
            .presentation(
                usesCustomText: true,
                resolvedText: "宝宝已经 1 岁 2 个月"
            )

        #expect(
            presentation.toggleTitle
            == "写入记忆信息"
        )
        #expect(
            presentation.toggleDescription
            == "关闭后，将使用下方录入内容替换图片说明。"
        )
        #expect(
            presentation.inputPlaceholder
            == "输入准备替换写入到图片说明框的信息"
        )
        #expect(
            presentation.resolvedTitle
            == "替换写入"
        )
        #expect(
            presentation.resolvedDescription
            == "宝宝已经 1 岁 2 个月"
        )
        #expect(
            presentation.fallbackNote
            == "重新打开后，将恢复写入当前智能模块结果。"
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
            == "写入记忆信息"
        )
        #expect(
            presentation.toggleDescription
            == "开启后，默认将当前智能模块结果写入图片说明。"
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
