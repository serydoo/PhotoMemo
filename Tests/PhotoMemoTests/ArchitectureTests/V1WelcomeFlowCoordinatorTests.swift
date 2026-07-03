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
}
#endif
