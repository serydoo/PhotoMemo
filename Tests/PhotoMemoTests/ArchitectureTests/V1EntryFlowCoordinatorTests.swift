#if !PHOTOMEMO_SHARE_EXTENSION
import Testing
@testable import PhotoMemo

@MainActor
@Suite("V1 entry flow coordinator")
struct V1EntryFlowCoordinatorTests {

    @Test("showing workflow from welcome closes welcome first and marks welcome seen")
    func showingWorkflowFromWelcomeClosesWelcomeFirstAndMarksWelcomeSeen() {
        let state =
            V1EntryFlowState(
                selectedTab: .home,
                showsWelcomePage: true,
                showsWorkflowGuide: false,
                showsProcessingPhotoPicker: false,
                showsSubjectOverview: false,
                subjectConfigurationFlowState: nil,
                showsSettingsPage: false
            )

        let update =
            V1EntryFlowCoordinator
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
        let state = V1EntryFlowState()

        let nextState =
            V1EntryFlowCoordinator
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
                V1IOSSubjectConfigurationFlowPresenter
                    .makeFlowState(
                        from: liveSession
                    )
            )
        let state =
            V1EntryFlowState(
                selectedTab: .home,
                showsWelcomePage: false,
                showsWorkflowGuide: false,
                showsProcessingPhotoPicker: false,
                showsSubjectOverview: true,
                subjectConfigurationFlowState: nil,
                showsSettingsPage: false
            )

        let nextState =
            V1EntryFlowCoordinator
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
        let state = V1EntryFlowState()
        let result =
            V1PhotoProcessingQuickActionCoordinator
            .Result(
                status: .submitted,
                submittedURLs: []
            )

        let nextState =
            V1EntryFlowCoordinator
            .applyQuickActionResult(
                result,
                to: state
            )

        #expect(nextState.selectedTab == .tasks)
    }

    @Test("settings page opens as a separate surface without changing the active tab")
    func settingsPageOpensSeparately() {
        let state = V1EntryFlowState(selectedTab: .home)

        let nextState =
            V1EntryFlowCoordinator
            .openSettingsPage(
                from: state
            )

        #expect(nextState.selectedTab == .home)
        #expect(nextState.showsSettingsPage == true)
    }

    @Test("regular settings selects the settings destination")
    func regularSettingsSelectsDestination() {
        let nextState =
            V1EntryFlowCoordinator
            .openSettings(
                presentation: .regular,
                from: V1EntryFlowState()
            )

        #expect(nextState.selectedTab == .settings)
        #expect(nextState.showsSettingsPage == false)
    }

    @Test("compact settings opens the settings sheet")
    func compactSettingsOpensSheet() {
        let nextState =
            V1EntryFlowCoordinator
            .openSettings(
                presentation: .compact,
                from: V1EntryFlowState()
            )

        #expect(nextState.selectedTab == .home)
        #expect(nextState.showsSettingsPage == true)
    }

    @Test("contracting from regular settings preserves access through the compact sheet")
    func contractingSettingsPreservesAccess() {
        let state =
            V1EntryFlowState(
                selectedTab: .settings
            )

        let nextState =
            V1EntryFlowCoordinator
            .prepareForCompactPresentation(
                from: state
            )

        #expect(nextState.selectedTab == .home)
        #expect(nextState.showsSettingsPage == true)
    }

    @Test("entry navigation opens compact settings without clearing unrelated sheets")
    func entryNavigationOpensCompactSettingsWithoutClearingUnrelatedSheets() {
        var state =
            EntryNavigationState(
                flowState:
                    V1EntryFlowState(
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
                    V1EntryFlowState(
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
