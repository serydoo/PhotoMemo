#if !MEMOMARK_SHARE_EXTENSION
import Testing
@testable import MemoMark

@Suite("V1 welcome flow coordinator")
struct WelcomeFlowCoordinatorTests {

    @Test("showing workflow from welcome closes the welcome sheet first")
    func showingWorkflowFromWelcomeClosesWelcomeSheetFirst() {
        let state = WelcomeFlowState(
            hasSeenWelcome: false,
            showsWelcomePage: true,
            showsWorkflowGuide: false
        )

        let nextState =
            WelcomeFlowCoordinator
            .showWorkflow(from: state)

        #expect(nextState.hasSeenWelcome == true)
        #expect(nextState.showsWelcomePage == false)
        #expect(nextState.showsWorkflowGuide == true)
    }

    @Test("starting welcome marks it seen and dismisses all onboarding sheets")
    func startingWelcomeMarksItSeenAndDismissesAllOnboardingSheets() {
        let state = WelcomeFlowState(
            hasSeenWelcome: false,
            showsWelcomePage: true,
            showsWorkflowGuide: true
        )

        let nextState =
            WelcomeFlowCoordinator
            .startUsingApp(from: state)

        #expect(nextState.hasSeenWelcome == true)
        #expect(nextState.showsWelcomePage == false)
        #expect(nextState.showsWorkflowGuide == false)
    }

    @Test("the workflow guide keeps Apple Photos Share as the primary entry")
    func workflowGuideKeepsApplePhotosShareAsPrimaryEntry() {
        let steps = WelcomePresentation.workflowSteps(for: .simplifiedChinese)

        let shareStep = steps.first(where: { $0.id == "share" })

        #expect(shareStep?.title == "分享给时光记")
        #expect(
            shareStep?.detail
                == "在 Apple Photos 点分享。如果时光记没有出现在前面，请向左滑应用栏，点“更多”或“编辑”，长按时光记并拖到前面。以后选好照片后，就能更快找到时光记。"
        )
    }
}
#endif
