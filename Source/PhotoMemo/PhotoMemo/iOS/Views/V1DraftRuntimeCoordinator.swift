#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

@MainActor
struct V1DraftRuntimeCoordinator {

    private let loadViewState:
        () -> V1DraftOrchestrationCoordinator.ViewState
    private let updateViewState:
        (V1DraftOrchestrationCoordinator.ViewState) -> Void
    private let makeDefaultDraft:
        (CardRegion) -> V1EditorDraft
    private let refreshPreviewText:
        (CardRegion, V1PreviewDraft) -> Void
    private let refreshPreviewTexts:
        ([CardRegion: V1PreviewDraft]) -> Void

    init(
        loadViewState: @escaping () -> V1DraftOrchestrationCoordinator.ViewState,
        updateViewState: @escaping (
            V1DraftOrchestrationCoordinator.ViewState
        ) -> Void,
        makeDefaultDraft: @escaping (
            CardRegion
        ) -> V1EditorDraft,
        refreshPreviewText: @escaping (
            CardRegion,
            V1PreviewDraft
        ) -> Void,
        refreshPreviewTexts: @escaping (
            [CardRegion: V1PreviewDraft]
        ) -> Void
    ) {
        self.loadViewState = loadViewState
        self.updateViewState = updateViewState
        self.makeDefaultDraft = makeDefaultDraft
        self.refreshPreviewText = refreshPreviewText
        self.refreshPreviewTexts = refreshPreviewTexts
    }

    init(
        loadViewState: @escaping () -> V1DraftOrchestrationCoordinator.ViewState,
        updateViewState: @escaping (
            V1DraftOrchestrationCoordinator.ViewState
        ) -> Void,
        makeDefaultDraft: @escaping (
            CardRegion
        ) -> V1EditorDraft,
        previewSyncCoordinator: V1PreviewSyncCoordinator,
        renderModel: @escaping (
            V1PreviewDraft
        ) -> V1PreviewRenderModel
    ) {
        self.init(
            loadViewState: loadViewState,
            updateViewState: updateViewState,
            makeDefaultDraft: makeDefaultDraft,
            refreshPreviewText: { region, draft in
                previewSyncCoordinator.refreshPreview(
                    for: region,
                    model:
                        renderModel(draft)
                )
            },
            refreshPreviewTexts: { draftsByRegion in
                previewSyncCoordinator
                    .refreshDynamicPreview(
                        modelsByRegion:
                            draftsByRegion
                            .mapValues(renderModel)
                    )
            }
        )
    }

    func draft(
        for region: CardRegion
    ) -> V1EditorDraft {
        V1DraftOrchestrationCoordinator
            .draft(
                for: region,
                viewState: loadViewState(),
                makeDefaultDraft: makeDefaultDraft
            )
    }

    func setActiveTextItem(
        _ itemID: UUID?,
        for region: CardRegion
    ) {
        applyMutationState(
            V1DraftMutationCoordinator
            .setActiveTextItem(
                itemID,
                for: region,
                in: mutationState
            )
        )
    }

    func updateTextItem(
        _ itemID: UUID,
        text: String,
        for region: CardRegion
    ) {
        applyMutationUpdate(
            V1DraftMutationCoordinator
            .updateTextItem(
                id: itemID,
                text: text,
                for: region,
                in: mutationState,
                makeDefaultDraft:
                    makeDefaultMutationDraft
            )
        )
    }

    func prependText(
        _ text: String,
        to region: CardRegion
    ) {
        applyMutationUpdate(
            V1DraftMutationCoordinator
            .prependText(
                text,
                for: region,
                in: mutationState,
                makeDefaultDraft:
                    makeDefaultMutationDraft
            )
        )
    }

    func appendText(
        _ text: String,
        to region: CardRegion
    ) {
        applyMutationUpdate(
            V1DraftMutationCoordinator
            .appendText(
                text,
                for: region,
                in: mutationState,
                makeDefaultDraft:
                    makeDefaultMutationDraft
            )
        )
    }

    func removeItem(
        _ itemID: UUID,
        from region: CardRegion
    ) {
        applyMutationUpdate(
            V1DraftMutationCoordinator
            .removeItem(
                id: itemID,
                from: region,
                in: mutationState,
                makeDefaultDraft:
                    makeDefaultMutationDraft
            )
        )
    }

    func insert(
        _ item: V1ContentItem,
        into region: CardRegion
    ) {
        applyMutationUpdate(
            V1DraftMutationCoordinator
            .insert(
                V1DraftBridge
                .mutationItem(from: item),
                into: region,
                in: mutationState,
                makeDefaultDraft:
                    makeDefaultMutationDraft
            )
        )
    }

    func refreshPreview(
        for region: CardRegion
    ) {
        refreshPreviewText(
            region,
            V1DraftBridge.previewDraft(
                from: draft(for: region)
            )
        )
    }

    func refreshDynamicPreview() {
        refreshDynamicPreview(
            for: CardRegion.memoryCardRegions
        )
    }

    func refreshDynamicPreview(
        for regions: [CardRegion]
    ) {
        refreshPreviewTexts(
            V1DraftOrchestrationCoordinator
                .dynamicPreviewDrafts(
                    for: regions,
                    viewState: loadViewState(),
                    makeDefaultDraft:
                        makeDefaultDraft
                )
        )
    }

    func bootstrapDrafts(
        using bootstrapCoordinator: V1DraftBootstrapCoordinator
    ) {
        var viewState = loadViewState()
        viewState.regionDrafts =
            bootstrapCoordinator
            .bootstrapDrafts(
                makeDefaultDraft:
                    makeDefaultDraft
            )
        updateViewState(viewState)
        refreshDynamicPreview()
    }

    private var mutationState:
        V1DraftMutationCoordinator.State {
        V1DraftOrchestrationCoordinator
            .mutationState(
                from: loadViewState()
            )
    }

    private func makeDefaultMutationDraft(
        for region: CardRegion
    ) -> V1DraftMutationDraft {
        V1DraftBridge.mutationDraft(
            from: makeDefaultDraft(region)
        )
    }

    private func applyMutationState(
        _ state:
            V1DraftMutationCoordinator.State
    ) {
        updateViewState(
            V1DraftOrchestrationCoordinator
                .viewState(from: state)
        )
    }

    private func applyMutationUpdate(
        _ update:
            V1DraftMutationCoordinator.Update
    ) {
        let application =
            V1DraftOrchestrationCoordinator
            .applyMutationUpdate(update)
        updateViewState(
            application.viewState
        )

        guard !application
            .previewDraftsByRegion
            .isEmpty else {
            return
        }

        refreshPreviewTexts(
            application
            .previewDraftsByRegion
        )
    }
}
#endif
