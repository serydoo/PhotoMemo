#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 module panel coordinator")
struct V1ModulePanelCoordinatorTests {

    @Test("focusEditor dismisses the active module panel")
    func focusEditorDismissesTheActiveModulePanel() {
        let state =
            V1ModulePanelCoordinator
            .State(
                activeRegion: .slotD,
                usageStorage: "{}"
            )

        let nextState =
            V1ModulePanelCoordinator
            .focusEditor(
                state: state
            )

        #expect(nextState.activeRegion == nil)
        #expect(
            nextState.usageStorage
            == state.usageStorage
        )
    }

    @Test("setSheetPresented false preserves the existing dismissal rule")
    func setSheetPresentedFalsePreservesTheExistingDismissalRule() {
        let state =
            V1ModulePanelCoordinator
            .State(
                activeRegion: .slotA,
                usageStorage: "{}"
            )

        let nextState =
            V1ModulePanelCoordinator
            .setSheetPresented(
                false,
                state: state
            )

        #expect(nextState.activeRegion == nil)
    }

    @Test("selectModule records usage and dismisses the panel")
    func selectModuleRecordsUsageAndDismissesThePanel() {
        let state =
            V1ModulePanelCoordinator
            .State(
                activeRegion: .slotC,
                usageStorage: "{}"
            )

        let nextState =
            V1ModulePanelCoordinator
            .selectModule(
                .cameraModel,
                state: state
            )
        let counts =
            V1ModuleUsageTracker
            .counts(
                from:
                    nextState.usageStorage
            )

        #expect(nextState.activeRegion == nil)
        #expect(
            counts[
                IOSInsertableModule
                    .cameraModel
                    .rawValue
            ] == 1
        )
    }
}
#endif
