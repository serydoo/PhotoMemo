#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct DraftOrchestrationCoordinator {

    struct ViewState: Hashable {
        var regionDrafts: [CardRegion: MemoryCardEditorDraft]
        var activeTextItemIDs: [CardRegion: UUID]
        var activeConfigurationStatus:
            ConfigurationPersistenceStatus
    }

    struct MutationApplication: Hashable {
        var viewState: ViewState
        var previewDraftsByRegion:
            [CardRegion: MemoryCardPreviewDraft]
    }

    static func draft(
        for region: CardRegion,
        viewState: ViewState,
        makeDefaultDraft: (CardRegion) -> MemoryCardEditorDraft
    ) -> MemoryCardEditorDraft {
        DraftBridge.editorDraft(
            from:
                DraftMutationCoordinator
                .draft(
                    for: region,
                    state:
                        mutationState(
                            from: viewState
                        ),
                    makeDefaultDraft: {
                        DraftBridge
                            .mutationDraft(
                                from:
                                    makeDefaultDraft(
                                        $0
                                    )
                            )
                    }
                )
        )
    }

    static func applyMutationUpdate(
        _ update: DraftMutationCoordinator.Update
    ) -> MutationApplication {
        let viewState =
            viewState(
                from: update.state
            )

        return MutationApplication(
            viewState: viewState,
            previewDraftsByRegion:
                previewDrafts(
                    for: update.dirtyRegions,
                    viewState: viewState
                )
        )
    }

    static func dynamicPreviewDrafts(
        for regions: [CardRegion],
        viewState: ViewState,
        makeDefaultDraft: (CardRegion) -> MemoryCardEditorDraft
    ) -> [CardRegion: MemoryCardPreviewDraft] {
        Dictionary(
            uniqueKeysWithValues:
                regions.map { region in
                    (
                        region,
                        DraftBridge.previewDraft(
                            from:
                                viewState.regionDrafts[
                                    region
                                ]
                                ?? makeDefaultDraft(
                                    region
                                )
                        )
                    )
                }
        )
    }

    static func viewState(
        from state: DraftMutationCoordinator.State
    ) -> ViewState {
        let bridgedState =
            DraftBridge.viewState(
                from: state
            )

        return ViewState(
            regionDrafts:
                bridgedState.regionDrafts,
            activeTextItemIDs:
                bridgedState.activeTextItemIDs,
            activeConfigurationStatus:
                bridgedState
                .activeConfigurationStatus
        )
    }

    static func mutationState(
        from viewState: ViewState
    ) -> DraftMutationCoordinator.State {
        DraftBridge.mutationState(
            regionDrafts:
                viewState.regionDrafts,
            activeTextItemIDs:
                viewState.activeTextItemIDs,
            activeConfigurationStatus:
                viewState
                .activeConfigurationStatus
        )
    }

    private static func previewDrafts(
        for regions: Set<CardRegion>,
        viewState: ViewState
    ) -> [CardRegion: MemoryCardPreviewDraft] {
        Dictionary(
            uniqueKeysWithValues:
                regions.compactMap { region in
                    guard let draft =
                        viewState.regionDrafts[
                            region
                        ]
                    else {
                        return nil
                    }

                    return (
                        region,
                        DraftBridge.previewDraft(
                            from: draft
                        )
                    )
                }
        )
    }
}
#endif
