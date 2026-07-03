#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1WelcomeFlowState: Equatable {
    var hasSeenWelcome: Bool
    var showsWelcomePage: Bool
    var showsWorkflowGuide: Bool
}

enum V1WelcomeFlowCoordinator {

    static func presentWelcome(
        hasSeenWelcome: Bool
    ) -> V1WelcomeFlowState {
        V1WelcomeFlowState(
            hasSeenWelcome: hasSeenWelcome,
            showsWelcomePage: !hasSeenWelcome,
            showsWorkflowGuide: false
        )
    }

    static func showWorkflow(
        from state: V1WelcomeFlowState
    ) -> V1WelcomeFlowState {
        var nextState = state
        nextState.hasSeenWelcome = true
        nextState.showsWelcomePage = false
        nextState.showsWorkflowGuide = true
        return nextState
    }

    static func startUsingApp(
        from state: V1WelcomeFlowState
    ) -> V1WelcomeFlowState {
        var nextState = state
        nextState.hasSeenWelcome = true
        nextState.showsWelcomePage = false
        nextState.showsWorkflowGuide = false
        return nextState
    }
}
#endif
