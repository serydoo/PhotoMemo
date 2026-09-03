#if !MEMOMARK_SHARE_EXTENSION
import Foundation

@MainActor
struct DraftRuntimeCoordinator {

    private let loadViewState:
        () -> DraftOrchestrationCoordinator.ViewState
    private let updateViewState:
        (DraftOrchestrationCoordinator.ViewState) -> Void
    private let makeDefaultDraft:
        (CardRegion) -> MemoryCardEditorDraft
    private let refreshPreviewText:
        (CardRegion, MemoryCardPreviewDraft) -> Void
    private let refreshPreviewTexts:
        ([CardRegion: MemoryCardPreviewDraft]) -> Void

    init(
        loadViewState: @escaping () -> DraftOrchestrationCoordinator.ViewState,
        updateViewState: @escaping (
            DraftOrchestrationCoordinator.ViewState
        ) -> Void,
        makeDefaultDraft: @escaping (
            CardRegion
        ) -> MemoryCardEditorDraft,
        refreshPreviewText: @escaping (
            CardRegion,
            MemoryCardPreviewDraft
        ) -> Void,
        refreshPreviewTexts: @escaping (
            [CardRegion: MemoryCardPreviewDraft]
        ) -> Void
    ) {
        self.loadViewState = loadViewState
        self.updateViewState = updateViewState
        self.makeDefaultDraft = makeDefaultDraft
        self.refreshPreviewText = refreshPreviewText
        self.refreshPreviewTexts = refreshPreviewTexts
    }

    init(
        loadViewState: @escaping () -> DraftOrchestrationCoordinator.ViewState,
        updateViewState: @escaping (
            DraftOrchestrationCoordinator.ViewState
        ) -> Void,
        makeDefaultDraft: @escaping (
            CardRegion
        ) -> MemoryCardEditorDraft,
        previewSyncCoordinator: PreviewSyncCoordinator,
        renderModel: @escaping (
            MemoryCardPreviewDraft
        ) -> MemoryCardPreviewRenderModel
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
    ) -> MemoryCardEditorDraft {
        DraftOrchestrationCoordinator
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
            DraftMutationCoordinator
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
            DraftMutationCoordinator
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
            DraftMutationCoordinator
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
            DraftMutationCoordinator
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
            DraftMutationCoordinator
            .removeItem(
                id: itemID,
                from: region,
                in: mutationState,
                makeDefaultDraft:
                    makeDefaultMutationDraft
            )
        )
    }

    @discardableResult
    func removePreviousComposedItem(
        before textItemID: UUID,
        from region: CardRegion
    ) -> Bool {
        let update =
            DraftMutationCoordinator
            .removePreviousComposedItem(
                before: textItemID,
                from: region,
                in: mutationState,
                makeDefaultDraft:
                    makeDefaultMutationDraft
            )
        guard !update.dirtyRegions.isEmpty else {
            return false
        }

        applyMutationUpdate(update)
        return true
    }

    func insert(
        _ item: MemoryCardContentItem,
        into region: CardRegion
    ) {
        applyMutationUpdate(
            DraftMutationCoordinator
            .insert(
                DraftBridge
                .mutationItem(from: item),
                into: region,
                in: mutationState,
                makeDefaultDraft:
                    makeDefaultMutationDraft
            )
        )
    }

    func replaceDraft(_ draft: MemoryCardEditorDraft, for region: CardRegion) {
        var viewState = loadViewState()
        guard viewState.regionDrafts[region] != draft else { return }
        viewState.regionDrafts[region] = draft
        viewState.activeConfigurationStatus = .dirty
        updateViewState(viewState)
        refreshPreviewText(region, DraftBridge.previewDraft(from: draft))
    }

    func refreshPreview(
        for region: CardRegion
    ) {
        refreshPreviewText(
            region,
            DraftBridge.previewDraft(
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
            DraftOrchestrationCoordinator
                .dynamicPreviewDrafts(
                    for: regions,
                    viewState: loadViewState(),
                    makeDefaultDraft:
                        makeDefaultDraft
                )
        )
    }

    func bootstrapDrafts(
        using bootstrapCoordinator: ConfigurationDraftBootstrapCoordinator
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
        DraftMutationCoordinator.State {
        DraftOrchestrationCoordinator
            .mutationState(
                from: loadViewState()
            )
    }

    private func makeDefaultMutationDraft(
        for region: CardRegion
    ) -> DraftMutationDraft {
        DraftBridge.mutationDraft(
            from: makeDefaultDraft(region)
        )
    }

    private func applyMutationState(
        _ state:
            DraftMutationCoordinator.State
    ) {
        updateViewState(
            DraftOrchestrationCoordinator
                .viewState(from: state)
        )
    }

    private func applyMutationUpdate(
        _ update:
            DraftMutationCoordinator.Update
    ) {
        let application =
            DraftOrchestrationCoordinator
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
