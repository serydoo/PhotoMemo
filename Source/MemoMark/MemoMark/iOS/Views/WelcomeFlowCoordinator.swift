#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct WelcomeFlowState: Equatable {
    var hasSeenWelcome: Bool
    var showsWelcomePage: Bool
    var showsWorkflowGuide: Bool
}

enum WelcomeFlowCoordinator {

    static func presentWelcome(
        hasSeenWelcome: Bool
    ) -> WelcomeFlowState {
        WelcomeFlowState(
            hasSeenWelcome: hasSeenWelcome,
            showsWelcomePage: !hasSeenWelcome,
            showsWorkflowGuide: false
        )
    }

    static func showWorkflow(
        from state: WelcomeFlowState
    ) -> WelcomeFlowState {
        var nextState = state
        nextState.hasSeenWelcome = true
        nextState.showsWelcomePage = false
        nextState.showsWorkflowGuide = true
        return nextState
    }

    static func startUsingApp(
        from state: WelcomeFlowState
    ) -> WelcomeFlowState {
        var nextState = state
        nextState.hasSeenWelcome = true
        nextState.showsWelcomePage = false
        nextState.showsWorkflowGuide = false
        return nextState
    }
}
#endif
