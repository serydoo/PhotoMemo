#if !MEMOMARK_SHARE_EXTENSION
import Testing
@testable import MemoMark

@Suite("V1 welcome presentation")
struct V1WelcomePresentationTests {

    @Test("uses the approved title subtitle features and actions")
    func usesApprovedCopy() {
        let presentation = V1WelcomePresentation.default

        #expect(presentation.title == "时光记")
        #expect(presentation.subtitle == "让照片记得，它在人生里的位置。")
        #expect(presentation.features.count == 4)
        #expect(
            presentation.features.map(\.title)
            == [
                "本地优先",
                "保留原图",
                "时间锚点",
                "一次设好，之后继续记录"
            ]
        )
        #expect(presentation.primaryActionTitle == "开始使用")
        #expect(presentation.secondaryActionTitle == "查看使用流程")
        #expect(presentation.workflowSteps.count == 4)
    }

    @Test("welcome information follows the interface language")
    func localizedPresentationUsesEnglishCopy() {
        let presentation =
            V1WelcomePresentation.localized(
                for: .english
            )

        #expect(presentation.title == "MemoMark")
        #expect(presentation.primaryActionTitle == "Get Started")
        #expect(presentation.secondaryActionTitle == "See the Daily Flow")
        #expect(presentation.features.first?.title == "Local First")
    }
}
#endif
