#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1ModulePanelCoordinator {

    struct State:
        Equatable {

        var activeRegion: CardRegion?
        var usageStorage: String
    }

    static func focusEditor(
        state: State
    ) -> State {
        var nextState =
            state
        nextState.activeRegion = nil
        return nextState
    }

    static func showModules(
        for region: CardRegion,
        state: State
    ) -> State {
        var nextState =
            state
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

        nextState.activeRegion =
            V1ModuleLibraryPresenter
            .resolvedActiveRegion(
                isPresented: false,
                currentRegion:
                    state.activeRegion
            )

        return nextState
    }
}
#endif
