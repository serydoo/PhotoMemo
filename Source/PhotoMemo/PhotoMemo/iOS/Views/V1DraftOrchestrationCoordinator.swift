#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1DraftOrchestrationCoordinator {

    struct ViewState: Hashable {
        var regionDrafts: [CardRegion: V1EditorDraft]
        var activeTextItemIDs: [CardRegion: UUID]
        var activeConfigurationMessage: String
    }

    struct MutationApplication: Hashable {
        var viewState: ViewState
        var previewDraftsByRegion:
            [CardRegion: V1PreviewDraft]
    }

    static func draft(
        for region: CardRegion,
        viewState: ViewState,
        makeDefaultDraft: (CardRegion) -> V1EditorDraft
    ) -> V1EditorDraft {
        V1DraftBridge.editorDraft(
            from:
                V1DraftMutationCoordinator
                .draft(
                    for: region,
                    state:
                        mutationState(
                            from: viewState
                        ),
                    makeDefaultDraft: {
                        V1DraftBridge
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
        _ update: V1DraftMutationCoordinator.Update
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
        makeDefaultDraft: (CardRegion) -> V1EditorDraft
    ) -> [CardRegion: V1PreviewDraft] {
        Dictionary(
            uniqueKeysWithValues:
                regions.map { region in
                    (
                        region,
                        V1DraftBridge.previewDraft(
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
        from state: V1DraftMutationCoordinator.State
    ) -> ViewState {
        let bridgedState =
            V1DraftBridge.viewState(
                from: state
            )

        return ViewState(
            regionDrafts:
                bridgedState.regionDrafts,
            activeTextItemIDs:
                bridgedState.activeTextItemIDs,
            activeConfigurationMessage:
                bridgedState
                .activeConfigurationMessage
        )
    }

    static func mutationState(
        from viewState: ViewState
    ) -> V1DraftMutationCoordinator.State {
        V1DraftBridge.mutationState(
            regionDrafts:
                viewState.regionDrafts,
            activeTextItemIDs:
                viewState.activeTextItemIDs,
            activeConfigurationMessage:
                viewState
                .activeConfigurationMessage
        )
    }

    private static func previewDrafts(
        for regions: Set<CardRegion>,
        viewState: ViewState
    ) -> [CardRegion: V1PreviewDraft] {
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
                        V1DraftBridge.previewDraft(
                            from: draft
                        )
                    )
                }
        )
    }
}
#endif
