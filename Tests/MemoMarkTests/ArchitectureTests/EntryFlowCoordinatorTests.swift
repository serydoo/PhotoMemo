#if !MEMOMARK_SHARE_EXTENSION
import Testing
@testable import MemoMark

@MainActor
@Suite("V1 entry flow coordinator")
struct EntryFlowCoordinatorTests {

    @Test("showing workflow from welcome closes welcome first and marks welcome seen")
    func showingWorkflowFromWelcomeClosesWelcomeFirstAndMarksWelcomeSeen() {
        let state =
            EntryFlowState(
                selectedTab: .home,
                showsWelcomePage: true,
                showsWorkflowGuide: false,
                showsProcessingPhotoPicker: false,
                showsSubjectOverview: false,
                subjectConfigurationFlowState: nil,
                showsSettingsPage: false
            )

        let update =
            EntryFlowCoordinator
            .showWorkflowFromWelcome(
                from: state,
                hasSeenWelcome: false
            )

        #expect(update.hasSeenWelcome == true)
        #expect(update.flowState.showsWelcomePage == false)
        #expect(update.flowState.showsWorkflowGuide == true)
    }

    @Test("home quick action opens subject overview without changing tabs")
    func homeQuickActionOpensSubjectOverviewWithoutChangingTabs() {
        let state = EntryFlowState()

        let nextState =
            EntryFlowCoordinator
            .openSubjectOverview(
                from: state
            )

        #expect(nextState.selectedTab == .home)
        #expect(nextState.showsSubjectOverview == true)
    }

    @Test("opening subject configuration closes overview first")
    func openingSubjectConfigurationClosesOverviewFirst() throws {
        let liveSession =
            ConfigurationSession(
                state: ConfigurationCenterState.mock
            )
        let flowState =
            try #require(
                SubjectConfigurationFlowPresenter
                    .makeFlowState(
                        from: liveSession
                    )
            )
        let state =
            EntryFlowState(
                selectedTab: .home,
                showsWelcomePage: false,
                showsWorkflowGuide: false,
                showsProcessingPhotoPicker: false,
                showsSubjectOverview: true,
                subjectConfigurationFlowState: nil,
                showsSettingsPage: false
            )

        let nextState =
            EntryFlowCoordinator
            .openSubjectConfiguration(
                flowState,
                from: state
            )

        #expect(nextState.showsSubjectOverview == false)
        #expect(
            nextState.subjectConfigurationFlowState?
                .sourceSubjectID
            == flowState.sourceSubjectID
        )
    }

    @Test("successful quick action routes to tasks only after submission")
    func successfulQuickActionRoutesToTasksOnlyAfterSubmission() {
        let state = EntryFlowState()
        let result =
            PhotoProcessingQuickActionCoordinator
            .Result(
                status: .submitted,
                submittedURLs: []
            )

        let nextState =
            EntryFlowCoordinator
            .applyQuickActionResult(
                result,
                to: state
            )

        #expect(nextState.selectedTab == .tasks)
    }

    @Test("settings page opens as a separate surface without changing the active tab")
    func settingsPageOpensSeparately() {
        let state = EntryFlowState(selectedTab: .home)

        let nextState =
            EntryFlowCoordinator
            .openSettingsPage(
                from: state
            )

        #expect(nextState.selectedTab == .home)
        #expect(nextState.showsSettingsPage == true)
    }

    @Test("regular settings selects the settings destination")
    func regularSettingsSelectsDestination() {
        let nextState =
            EntryFlowCoordinator
            .openSettings(
                presentation: .regular,
                from: EntryFlowState()
            )

        #expect(nextState.selectedTab == .settings)
        #expect(nextState.showsSettingsPage == false)
    }

    @Test("compact settings opens the settings sheet")
    func compactSettingsOpensSheet() {
        let nextState =
            EntryFlowCoordinator
            .openSettings(
                presentation: .compact,
                from: EntryFlowState()
            )

        #expect(nextState.selectedTab == .home)
        #expect(nextState.showsSettingsPage == true)
    }

    @Test("contracting from regular settings preserves access through the compact sheet")
    func contractingSettingsPreservesAccess() {
        let state =
            EntryFlowState(
                selectedTab: .settings
            )

        let nextState =
            EntryFlowCoordinator
            .prepareForCompactPresentation(
                from: state
            )

        #expect(nextState.selectedTab == .home)
        #expect(nextState.showsSettingsPage == true)
    }

    @Test("compact presentation routes retired output selection to Configuration Center")
    func contractingRetiredOutputSelectionRoutesToConfigurationCenter() {
        let state = EntryFlowState(selectedTab: .output)

        let nextState = EntryFlowCoordinator
            .prepareForCompactPresentation(from: state)

        #expect(nextState.selectedTab == .editor)
        #expect(nextState.showsSettingsPage == false)
    }

    @Test("entry navigation opens compact settings without clearing unrelated sheets")
    func entryNavigationOpensCompactSettingsWithoutClearingUnrelatedSheets() {
        var state =
            EntryNavigationState(
                flowState:
                    EntryFlowState(
                        selectedTab: .output,
                        showsWelcomePage: false,
                        showsWorkflowGuide: true,
                        showsProcessingPhotoPicker: true,
                        showsSubjectOverview: true,
                        subjectConfigurationFlowState: nil,
                        showsSettingsPage: false
                    )
            )

        state.openSettings(presentation: .compact)

        #expect(state.flowState.selectedTab == .output)
        #expect(state.flowState.showsSettingsPage == true)
        #expect(state.flowState.showsWorkflowGuide == true)
        #expect(state.flowState.showsProcessingPhotoPicker == true)
        #expect(state.flowState.showsSubjectOverview == true)
    }

    @Test("entry navigation opens regular settings without clearing unrelated sheets")
    func entryNavigationOpensRegularSettingsWithoutClearingUnrelatedSheets() {
        var state =
            EntryNavigationState(
                flowState:
                    EntryFlowState(
                        selectedTab: .output,
                        showsWelcomePage: true,
                        showsWorkflowGuide: true,
                        showsProcessingPhotoPicker: true,
                        showsSubjectOverview: true,
                        subjectConfigurationFlowState: nil,
                        showsSettingsPage: true
                    )
            )

        state.openSettings(presentation: .regular)

        #expect(state.flowState.selectedTab == .settings)
        #expect(state.flowState.showsSettingsPage == false)
        #expect(state.flowState.showsWelcomePage == true)
        #expect(state.flowState.showsWorkflowGuide == true)
        #expect(state.flowState.showsProcessingPhotoPicker == true)
        #expect(state.flowState.showsSubjectOverview == true)
    }
}
#endif
