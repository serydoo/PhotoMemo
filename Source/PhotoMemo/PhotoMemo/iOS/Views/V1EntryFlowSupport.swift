#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum V1EntryTab: Hashable {
    case home
    case editor
    case output
    case tasks
}

struct V1EntryFlowState {
    var selectedTab: V1EntryTab = .home
    var showsWelcomePage = false
    var showsWorkflowGuide = false
    var showsProcessingPhotoPicker = false
    var showsSubjectOverview = false
    var subjectConfigurationFlowState:
        V1IOSSubjectConfigurationFlowState?
    var showsSettingsPage = false
}

struct V1EntryWelcomeFlowUpdate {
    let hasSeenWelcome: Bool
    let flowState: V1EntryFlowState
}

enum V1EntryFlowCoordinator {

    static func showWelcomePage(
        from state: V1EntryFlowState
    ) -> V1EntryFlowState {
        var nextState = state
        nextState.showsWelcomePage = true
        nextState.showsWorkflowGuide = false
        return nextState
    }

    static func completeWelcome(
        from state: V1EntryFlowState,
        hasSeenWelcome: Bool
    ) -> V1EntryWelcomeFlowUpdate {
        applyWelcomeTransition(
            V1WelcomeFlowCoordinator
                .startUsingApp(
                    from: V1WelcomeFlowState(
                        hasSeenWelcome: hasSeenWelcome,
                        showsWelcomePage:
                            state.showsWelcomePage,
                        showsWorkflowGuide:
                            state.showsWorkflowGuide
                    )
                ),
            to: state
        )
    }

    static func showWorkflowFromWelcome(
        from state: V1EntryFlowState,
        hasSeenWelcome: Bool
    ) -> V1EntryWelcomeFlowUpdate {
        applyWelcomeTransition(
            V1WelcomeFlowCoordinator
                .showWorkflow(
                    from: V1WelcomeFlowState(
                        hasSeenWelcome: hasSeenWelcome,
                        showsWelcomePage:
                            state.showsWelcomePage,
                        showsWorkflowGuide:
                            state.showsWorkflowGuide
                    )
                ),
            to: state
        )
    }

    static func applyWelcomeState(
        _ welcomeState: V1WelcomeFlowState,
        to state: V1EntryFlowState
    ) -> V1EntryFlowState {
        var nextState = state
        nextState.showsWelcomePage =
            welcomeState.showsWelcomePage
        nextState.showsWorkflowGuide =
            welcomeState.showsWorkflowGuide
        return nextState
    }

    static func openSubjectOverview(
        from state: V1EntryFlowState
    ) -> V1EntryFlowState {
        var nextState = state
        nextState.showsSubjectOverview = true
        return nextState
    }

    static func closeSubjectOverview(
        from state: V1EntryFlowState
    ) -> V1EntryFlowState {
        var nextState = state
        nextState.showsSubjectOverview = false
        return nextState
    }

    static func openSubjectConfiguration(
        _ flowState: V1IOSSubjectConfigurationFlowState?,
        from state: V1EntryFlowState
    ) -> V1EntryFlowState {
        var nextState = state
        nextState.showsSubjectOverview = false
        nextState.subjectConfigurationFlowState =
            flowState
        return nextState
    }

    static func closeSubjectConfiguration(
        from state: V1EntryFlowState
    ) -> V1EntryFlowState {
        var nextState = state
        nextState.subjectConfigurationFlowState = nil
        return nextState
    }

    static func openProcessingPhotoPicker(
        from state: V1EntryFlowState
    ) -> V1EntryFlowState {
        var nextState = state
        nextState.showsProcessingPhotoPicker = true
        return nextState
    }

    static func openEditorTab(
        from state: V1EntryFlowState
    ) -> V1EntryFlowState {
        var nextState = state
        nextState.selectedTab = .editor
        return nextState
    }

    static func openTasksTab(
        from state: V1EntryFlowState
    ) -> V1EntryFlowState {
        var nextState = state
        nextState.selectedTab = .tasks
        return nextState
    }

    static func openSettingsPage(
        from state: V1EntryFlowState
    ) -> V1EntryFlowState {
        var nextState = state
        nextState.showsSettingsPage = true
        return nextState
    }

    static func closeSettingsPage(
        from state: V1EntryFlowState
    ) -> V1EntryFlowState {
        var nextState = state
        nextState.showsSettingsPage = false
        return nextState
    }

    static func applyQuickActionResult(
        _ result:
            V1PhotoProcessingQuickActionCoordinator
            .Result,
        to state: V1EntryFlowState
    ) -> V1EntryFlowState {
        var nextState = state

        switch result.status {
        case .configurationSaveFailed,
                .noSupportedPhotos:
            break
        case .submitted:
            nextState.selectedTab = .tasks
        }

        return nextState
    }

    private static func applyWelcomeTransition(
        _ welcomeState: V1WelcomeFlowState,
        to state: V1EntryFlowState
    ) -> V1EntryWelcomeFlowUpdate {
        V1EntryWelcomeFlowUpdate(
            hasSeenWelcome:
                welcomeState.hasSeenWelcome,
            flowState:
                applyWelcomeState(
                    welcomeState,
                    to: state
                )
        )
    }
}
#endif
