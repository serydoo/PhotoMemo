#if !PHOTOMEMO_SHARE_EXTENSION
import Testing
@testable import PhotoMemo

@Suite("V1 iOS quick actions")
struct V1IOSHomeQuickActionsTests {

    @Test("uses the approved four actions")
    func usesApprovedActions() {
        let actions = V1IOSHomeQuickAction.defaultActions

        #expect(
            actions.map(\.title)
            == [
                "处理照片",
                "配置中心",
                "时间锚点",
                "使用说明"
            ]
        )

        #expect(
            actions.map(\.subtitle)
            == [
                "需要时可在时光记中选择照片；日常记录请从 Apple Photos 分享",
                "继续查看当前生效配置",
                "查看记忆对象与生效锚点",
                "查看 Apple Photos 使用流程与说明"
            ]
        )

        #expect(
            actions.map(\.compactDetail)
            == [
                "备用选图",
                "查看当前配置",
                "切换生效锚点",
                "查看使用流程"
            ]
        )

        #expect(
            actions.map(\.systemImage)
            == [
                MemoMarkSymbol.applePhotos.name,
                MemoMarkSymbol.configurationCenter.name,
                MemoMarkSymbol.timeAnchor.name,
                "book.pages"
            ]
        )
    }
}
#endif
