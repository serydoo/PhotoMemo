#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("module panel coordinator")
struct ModulePanelCoordinatorTests {

    @Test("focusEditor dismisses the active module panel")
    func focusEditorDismissesTheActiveModulePanel() {
        let state =
            ModulePanelCoordinator
            .State(
                focusedRegion: .slotD,
                activeRegion: .slotD,
                usageStorage: "{}"
            )

        let nextState =
            ModulePanelCoordinator
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
            ModulePanelCoordinator
            .State(
                focusedRegion: nil,
                activeRegion: nil,
                usageStorage: "{}"
            )

        let nextState =
            ModulePanelCoordinator
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
        let state = ModulePanelCoordinator.State(
            focusedRegion: .slotA,
            activeRegion: .slotA,
            usageStorage: "{}"
        )

        let nextState = ModulePanelCoordinator.focusRegion(.slotB, state: state)

        #expect(nextState.focusedRegion == .slotB)
        #expect(nextState.activeRegion == .slotB)
    }

    @Test("setSheetPresented false preserves the existing dismissal rule")
    func setSheetPresentedFalsePreservesTheExistingDismissalRule() {
        let state =
            ModulePanelCoordinator
            .State(
                focusedRegion: .slotA,
                activeRegion: .slotA,
                usageStorage: "{}"
            )

        let nextState =
            ModulePanelCoordinator
            .setSheetPresented(
                false,
                state: state
            )

        #expect(nextState.activeRegion == nil)
        #expect(nextState.focusedRegion == .slotA)
    }

    @Test("selectModule records usage and keeps the panel open")
    func selectModuleRecordsUsageAndKeepsThePanelOpen() {
        let state =
            ModulePanelCoordinator
            .State(
                focusedRegion: .slotC,
                activeRegion: .slotC,
                usageStorage: "{}"
            )

        let nextState =
            ModulePanelCoordinator
            .selectModule(
                .cameraModel,
                state: state
            )
        let counts =
            ModuleUsageTracker
            .counts(
                from:
                    nextState.usageStorage
            )

        #expect(nextState.activeRegion == .slotC)
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
