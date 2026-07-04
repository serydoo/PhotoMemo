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
    }
}
#endif
