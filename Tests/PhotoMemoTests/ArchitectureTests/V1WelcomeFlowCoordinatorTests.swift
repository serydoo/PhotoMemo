#if !PHOTOMEMO_SHARE_EXTENSION
import Testing
@testable import PhotoMemo

@Suite("V1 welcome flow coordinator")
struct V1WelcomeFlowCoordinatorTests {

    @Test("showing workflow from welcome closes the welcome sheet first")
    func showingWorkflowFromWelcomeClosesWelcomeSheetFirst() {
        let state = V1WelcomeFlowState(
            hasSeenWelcome: false,
            showsWelcomePage: true,
            showsWorkflowGuide: false
        )

        let nextState =
            V1WelcomeFlowCoordinator
            .showWorkflow(from: state)

        #expect(nextState.hasSeenWelcome == true)
        #expect(nextState.showsWelcomePage == false)
        #expect(nextState.showsWorkflowGuide == true)
    }

    @Test("starting welcome marks it seen and dismisses all onboarding sheets")
    func startingWelcomeMarksItSeenAndDismissesAllOnboardingSheets() {
        let state = V1WelcomeFlowState(
            hasSeenWelcome: false,
            showsWelcomePage: true,
            showsWorkflowGuide: true
        )

        let nextState =
            V1WelcomeFlowCoordinator
            .startUsingApp(from: state)

        #expect(nextState.hasSeenWelcome == true)
        #expect(nextState.showsWelcomePage == false)
        #expect(nextState.showsWorkflowGuide == false)
    }

    @Test("the workflow guide keeps Apple Photos Share as the primary entry")
    func workflowGuideKeepsApplePhotosShareAsPrimaryEntry() {
        let steps = V1WelcomePresentation.workflowSteps(for: .simplifiedChinese)

        let shareStep = steps.first(where: { $0.id == "share" })

        #expect(shareStep?.title == "分享给时光记")
        #expect(shareStep?.detail == "在系统相册点分享，选择时光记。")
    }
}
#endif
