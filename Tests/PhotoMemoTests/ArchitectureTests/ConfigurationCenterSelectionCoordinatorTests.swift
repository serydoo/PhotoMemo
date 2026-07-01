#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Configuration center selection coordinator")
struct ConfigurationCenterSelectionCoordinatorTests {

    @Test("showCard selects both the card panel and the matching region")
    func showCardSelectsCardPanelAndRegion() {
        let update =
            ConfigurationCenterSelectionCoordinator
            .showCard(region: .slotC)

        #expect(
            update.selectedPanel == .card(.slotC)
        )
        #expect(
            update.selectedRegion == .slotC
        )
        #expect(update.selectedSubject == nil)
    }

    @Test("showPanel changes only the detail panel")
    func showPanelChangesOnlyDetailPanel() {
        let update =
            ConfigurationCenterSelectionCoordinator
            .showPanel(.output)

        #expect(update.selectedPanel == .output)
        #expect(update.selectedRegion == nil)
        #expect(update.selectedSubject == nil)
    }

    @Test("focusPreviewRegion preserves preview tap asymmetry by changing only the selected region")
    func focusPreviewRegionChangesOnlySelectedRegion() {
        let update =
            ConfigurationCenterSelectionCoordinator
            .focusPreviewRegion(.badge)

        #expect(update.selectedPanel == nil)
        #expect(update.selectedRegion == .badge)
        #expect(update.selectedSubject == nil)
    }

    @Test("isSelectedSubject requires both the subject panel and the same selected subject ID")
    func isSelectedSubjectRequiresMatchingPanelAndID() {
        let selectedID = UUID()
        let otherID = UUID()

        #expect(
            ConfigurationCenterSelectionCoordinator
            .isSelectedSubject(
                panel: .subject,
                selectedSubjectID: selectedID,
                candidateSubjectID: selectedID
            )
        )
        #expect(
            !ConfigurationCenterSelectionCoordinator
            .isSelectedSubject(
                panel: .output,
                selectedSubjectID: selectedID,
                candidateSubjectID: selectedID
            )
        )
        #expect(
            !ConfigurationCenterSelectionCoordinator
            .isSelectedSubject(
                panel: .subject,
                selectedSubjectID: selectedID,
                candidateSubjectID: otherID
            )
        )
    }

    @Test("shouldDismissKeyboard returns true when the selected panel changes")
    func shouldDismissKeyboardWhenPanelChanges() {
        let update =
            ConfigurationCenterSelectionCoordinator
            .showPanel(.memoryModule)

        #expect(
            ConfigurationCenterSelectionCoordinator
                .shouldDismissKeyboard(
                    for: update,
                    currentPanel: .output,
                    currentRegion: .slotA
                )
        )
    }

    @Test("shouldDismissKeyboard returns true when the selected region changes")
    func shouldDismissKeyboardWhenRegionChanges() {
        let update =
            ConfigurationCenterSelectionCoordinator
            .focusPreviewRegion(.slotD)

        #expect(
            ConfigurationCenterSelectionCoordinator
                .shouldDismissKeyboard(
                    for: update,
                    currentPanel: .card(.slotA),
                    currentRegion: .slotA
                )
        )
    }

    @Test("shouldDismissKeyboard returns false when the update keeps the current panel and region")
    func shouldDismissKeyboardWhenSelectionIsUnchanged() {
        let update =
            ConfigurationCenterSelectionCoordinator
            .showCard(region: .slotB)

        #expect(
            !ConfigurationCenterSelectionCoordinator
                .shouldDismissKeyboard(
                    for: update,
                    currentPanel: .card(.slotB),
                    currentRegion: .slotB
                )
        )
    }
}
#endif
