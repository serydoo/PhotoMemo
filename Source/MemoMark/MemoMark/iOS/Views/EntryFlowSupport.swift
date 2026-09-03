#if !MEMOMARK_SHARE_EXTENSION
import Foundation

enum EntryPresentation: Equatable {
    case compact
    case regular
}

enum EntryTab:
    Hashable,
    CaseIterable,
    Identifiable {
    case home
    case editor
    case output
    case tasks
    case settings

    static let primaryNavigationCases: [EntryTab] = [
        .home,
        .editor,
        .tasks
    ]

    static let sidebarNavigationCases: [EntryTab] = [
        .home,
        .editor,
        .tasks,
        .settings
    ]

    var id: Self {
        self
    }
}

struct EntryFlowState {
    var selectedTab: EntryTab = .home
    var showsWelcomePage = false
    var showsWorkflowGuide = false
    var showsProcessingPhotoPicker = false
    var showsSubjectOverview = false
    var subjectConfigurationFlowState:
        SubjectConfigurationFlowState?
    var showsSettingsPage = false
}

struct EntryWelcomeFlowUpdate {
    let hasSeenWelcome: Bool
    let flowState: EntryFlowState
}

enum EntryFlowCoordinator {

    static func showWelcomePage(
        from state: EntryFlowState
    ) -> EntryFlowState {
        var nextState = state
        nextState.showsWelcomePage = true
        nextState.showsWorkflowGuide = false
        return nextState
    }

    static func completeWelcome(
        from state: EntryFlowState,
        hasSeenWelcome: Bool
    ) -> EntryWelcomeFlowUpdate {
        applyWelcomeTransition(
            WelcomeFlowCoordinator
                .startUsingApp(
                    from: WelcomeFlowState(
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
        from state: EntryFlowState,
        hasSeenWelcome: Bool
    ) -> EntryWelcomeFlowUpdate {
        applyWelcomeTransition(
            WelcomeFlowCoordinator
                .showWorkflow(
                    from: WelcomeFlowState(
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
        _ welcomeState: WelcomeFlowState,
        to state: EntryFlowState
    ) -> EntryFlowState {
        var nextState = state
        nextState.showsWelcomePage =
            welcomeState.showsWelcomePage
        nextState.showsWorkflowGuide =
            welcomeState.showsWorkflowGuide
        return nextState
    }

    static func openSubjectOverview(
        from state: EntryFlowState
    ) -> EntryFlowState {
        var nextState = state
        nextState.showsSubjectOverview = true
        return nextState
    }

    static func closeSubjectOverview(
        from state: EntryFlowState
    ) -> EntryFlowState {
        var nextState = state
        nextState.showsSubjectOverview = false
        return nextState
    }

    static func openSubjectConfiguration(
        _ flowState: SubjectConfigurationFlowState?,
        from state: EntryFlowState
    ) -> EntryFlowState {
        var nextState = state
        nextState.showsSubjectOverview = false
        nextState.subjectConfigurationFlowState =
            flowState
        return nextState
    }

    static func closeSubjectConfiguration(
        from state: EntryFlowState
    ) -> EntryFlowState {
        var nextState = state
        nextState.subjectConfigurationFlowState = nil
        return nextState
    }

    static func openProcessingPhotoPicker(
        from state: EntryFlowState
    ) -> EntryFlowState {
        var nextState = state
        nextState.showsProcessingPhotoPicker = true
        return nextState
    }

    static func openEditorTab(
        from state: EntryFlowState
    ) -> EntryFlowState {
        var nextState = state
        nextState.selectedTab = .editor
        return nextState
    }

    static func openTasksTab(
        from state: EntryFlowState
    ) -> EntryFlowState {
        var nextState = state
        nextState.selectedTab = .tasks
        return nextState
    }

    static func openSettingsPage(
        from state: EntryFlowState
    ) -> EntryFlowState {
        var nextState = state
        nextState.showsSettingsPage = true
        return nextState
    }

    static func openSettings(
        presentation: EntryPresentation,
        from state: EntryFlowState
    ) -> EntryFlowState {
        switch presentation {
        case .compact:
            return openSettingsPage(from: state)

        case .regular:
            var nextState = state
            nextState.selectedTab = .settings
            nextState.showsSettingsPage = false
            return nextState
        }
    }

    static func closeSettingsPage(
        from state: EntryFlowState
    ) -> EntryFlowState {
        var nextState = state
        nextState.showsSettingsPage = false
        return nextState
    }

    static func prepareForCompactPresentation(
        from state: EntryFlowState
    ) -> EntryFlowState {
        var nextState = state
        switch state.selectedTab {
        case .settings:
            nextState.selectedTab = .home
            nextState.showsSettingsPage = true
            return nextState
        case .output:
            // Output configuration now lives in Configuration Center. If a
            // wide-layout state survives a rotation or an older deep link,
            // route it to the owning destination before TabView selection is
            // evaluated; otherwise compact navigation has no matching tab.
            nextState.selectedTab = .editor
            return nextState
        case .home, .editor, .tasks:
            return state
        }
    }

    static func applyQuickActionResult(
        _ result:
            PhotoProcessingQuickActionCoordinator
            .Result,
        to state: EntryFlowState
    ) -> EntryFlowState {
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
        _ welcomeState: WelcomeFlowState,
        to state: EntryFlowState
    ) -> EntryWelcomeFlowUpdate {
        EntryWelcomeFlowUpdate(
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
