#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct V1ModulePanelCoordinator {

    struct State:
        Equatable {

        var focusedRegion: CardRegion?
        var activeRegion: CardRegion?
        var usageStorage: String
    }

    static func focusEditor(
        state: State
    ) -> State {
        var nextState =
            state
        nextState.focusedRegion = nil
        nextState.activeRegion = nil
        return nextState
    }

    static func focusRegion(
        _ region: CardRegion,
        state: State
    ) -> State {
        var nextState = state
        nextState.focusedRegion = region
        // The module surface is manually toggled. When it is already open,
        // focusing another editor retargets the surface instead of closing it.
        nextState.activeRegion = state.activeRegion == nil
            ? nil
            : region
        return nextState
    }

    static func showModules(
        for region: CardRegion,
        state: State
    ) -> State {
        var nextState =
            state
        nextState.focusedRegion = region
        nextState.activeRegion = region
        return nextState
    }

    static func setSheetPresented(
        _ isPresented: Bool,
        state: State
    ) -> State {
        var nextState =
            state
        nextState.activeRegion =
            V1ModuleLibraryPresenter
            .resolvedActiveRegion(
                isPresented: isPresented,
                currentRegion:
                    state.activeRegion
            )
        return nextState
    }

    static func selectModule(
        _ module: IOSInsertableModule,
        state: State
    ) -> State {
        var nextState =
            state

        if let storage =
            V1ModuleLibraryPresenter
            .recordedUsageStorage(
                for: module,
                currentStorage:
                    state.usageStorage
            ) {
            nextState.usageStorage =
                storage
        }

        // Keep the candidate surface open after insertion so users can add
        // multiple modules without reopening it after every selection.
        nextState.activeRegion = state.activeRegion

        return nextState
    }
}
#endif
