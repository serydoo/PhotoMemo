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
}
#endif
