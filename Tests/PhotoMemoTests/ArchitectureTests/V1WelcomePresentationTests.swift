#if !PHOTOMEMO_SHARE_EXTENSION
import Testing
@testable import PhotoMemo

@Suite("V1 welcome presentation")
struct V1WelcomePresentationTests {

    @Test("uses the approved title subtitle features and actions")
    func usesApprovedCopy() {
        let presentation = V1WelcomePresentation.default

        #expect(presentation.title == "PhotoMemo")
        #expect(presentation.subtitle == "记录人生，珍藏记忆")
        #expect(presentation.features.count == 4)
        #expect(
            presentation.features.map(\.title)
            == [
                "本地优先",
                "保留原图",
                "时间锚点",
                "一次配置，长期受益"
            ]
        )
        #expect(presentation.primaryActionTitle == "开始使用")
        #expect(presentation.secondaryActionTitle == "查看使用流程")
        #expect(presentation.workflowSteps.count == 4)
    }
}
#endif
