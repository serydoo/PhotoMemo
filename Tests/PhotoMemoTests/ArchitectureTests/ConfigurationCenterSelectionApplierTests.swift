#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@MainActor
@Suite("Configuration center selection applier")
struct ConfigurationCenterSelectionApplierTests {

    @Test("apply updates subject region and panel from a full selection update")
    func applyUpdatesFullSelectionState() throws {
        let session = ConfigurationSession()
        let subject =
            try #require(
                session.state.subjects.last
            )
        var selectedPanel: IOSConfigurationPanel = .output

        let update =
            ConfigurationCenterSelectionCoordinator
                .showSubject(subject)

        ConfigurationCenterSelectionApplier
            .apply(
                update,
                session: session,
                selectedPanel: &selectedPanel
            )

        #expect(
            session.state.selectedSubject?.id
            == subject.id
        )
        #expect(
            session.state.selectedRegion
            == .subject
        )
        #expect(selectedPanel == .subject)
    }

    @Test("applyPreviewFocus keeps preview tap asymmetry by changing only the region")
    func applyPreviewFocusChangesOnlyRegion() {
        let session = ConfigurationSession()
        session.selectRegion(.slotA)

        let update =
            ConfigurationCenterSelectionCoordinator
                .focusPreviewRegion(.badge)

        ConfigurationCenterSelectionApplier
            .applyPreviewFocus(
                update,
                session: session
            )

        #expect(session.state.selectedRegion == .badge)
    }
}
#endif
