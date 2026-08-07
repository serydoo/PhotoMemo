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
                focusedRegion: .slotD,
                activeRegion: .slotD,
                usageStorage: "{}"
            )

        let nextState =
            V1ModulePanelCoordinator
            .focusEditor(
                state: state
            )

        #expect(nextState.activeRegion == nil)
        #expect(nextState.focusedRegion == nil)
        #expect(
            nextState.usageStorage
            == state.usageStorage
        )
    }

    @Test("focusRegion keeps the active insertion region without presenting the panel")
    func focusRegionKeepsTheActiveInsertionRegionWithoutPresentingThePanel() {
        let state =
            V1ModulePanelCoordinator
            .State(
                focusedRegion: nil,
                activeRegion: nil,
                usageStorage: "{}"
            )

        let nextState =
            V1ModulePanelCoordinator
            .focusRegion(
                .slotD,
                state: state
            )

        #expect(nextState.focusedRegion == .slotD)
        #expect(nextState.activeRegion == nil)
        #expect(nextState.usageStorage == state.usageStorage)
    }

    @Test("focusRegion retargets an already open module panel")
    func focusRegionRetargetsAnAlreadyOpenModulePanel() {
        let state = V1ModulePanelCoordinator.State(
            focusedRegion: .slotA,
            activeRegion: .slotA,
            usageStorage: "{}"
        )

        let nextState = V1ModulePanelCoordinator.focusRegion(.slotB, state: state)

        #expect(nextState.focusedRegion == .slotB)
        #expect(nextState.activeRegion == .slotB)
    }

    @Test("setSheetPresented false preserves the existing dismissal rule")
    func setSheetPresentedFalsePreservesTheExistingDismissalRule() {
        let state =
            V1ModulePanelCoordinator
            .State(
                focusedRegion: .slotA,
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
        #expect(nextState.focusedRegion == .slotA)
    }

    @Test("selectModule records usage and dismisses the panel")
    func selectModuleRecordsUsageAndDismissesThePanel() {
        let state =
            V1ModulePanelCoordinator
            .State(
                focusedRegion: .slotC,
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
        #expect(nextState.focusedRegion == .slotC)
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
