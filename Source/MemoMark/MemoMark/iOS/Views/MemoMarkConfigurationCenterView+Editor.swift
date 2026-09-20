#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import PhotosUI
import UIKit

extension MemoMarkConfigurationCenterView {
    @ViewBuilder
    var presentedEditorCluster: some View {
        if rootPresentationState.isEditingFilmMarkContent {
            filmMarkEditorCluster
        } else {
            editorCluster
        }
    }

    var previewSection: some View {
        MemoryCardPreviewSection(
            presentationStyle: presentationStyle,
            logoMode: logoMode,
            customLogoImagePath:
                customLogoBadge?.imagePath,
            subjectAvatarLogoImagePath:
                resolvedSubjectAvatarLogoImagePath,
            regionText:
                previewText(
                    for: CardRegion.region(for: .leftPrimary)
                ),
            timeText:
                previewText(
                    for: CardRegion.region(for: .leftSecondary)
                ),
            contextText:
                previewText(
                    for: CardRegion.region(for: .rightPrimary)
                ),
            memoryText:
                previewText(
                    for: CardRegion.region(for: .rightSecondary)
                ),
            filmMarkOutputText:
                filmMarkPreviewText,
            filmMarkConfiguration:
                rootConfigurationProjectionState.filmMarkConfiguration,
            isFilmMarkGeometryExpanded:
                rootPresentationState.isFilmMarkGeometryExpanded,
            onTap: dismissKeyboard
        )
    }

    var editorCluster: some View {
        MemoryCardRegionEditorCluster(
            presentationStyle: presentationStyle,
            visibleRegions:
                CardRegion.editableRegions(
                    for: presentationStyle
                ),
            photoDescriptionRegions:
                presentationStyle.contentContract
                .photoDescriptionTextAreas
                .compactMap(CardRegion.region(for:)),
            slotATextKitCommandBus:
                editorInteractionState.slotATextKitCommandBus,
            slotBTextKitCommandBus:
                editorInteractionState.slotBTextKitCommandBus,
            slotCTextKitCommandBus:
                editorInteractionState.slotCTextKitCommandBus,
            slotDTextKitCommandBus:
                editorInteractionState.slotDTextKitCommandBus,
            draft: { region in
                draft(for: region)
            },
            onFocus: { region in
                focusRegionEditor(for: region)
            },
            onFocusTextItem: { region, item in
                setActiveTextItem(item.id, for: region)
                focusRegionEditor(for: region)
            },
            onFocusTrailingText: { region in
                // A default module-only region uses a transient trailing
                // text field. Clearing a stale text anchor ensures insertion
                // appends after the visible module instead of jumping left.
                setActiveTextItem(nil, for: region)
                focusRegionEditor(for: region)
            },
            onUpdateTextItem: { region, item, text in
                updateTextItem(item.id, text: text, for: region)
            },
            onReplaceDraft: { region, draft in
                draftRuntimeCoordinator.replaceDraft(draft, for: region)
            },
            onPrependText: { region, text in
                prependText(text, to: region)
            },
            onAppendText: { region, text in
                appendText(text, to: region)
            },
            onRemoveItem: { region, item in
                removeItem(item.id, from: region)
                refreshPreview(for: region)
            },
            onRemovePreviousComposedItem: { region, itemID in
                let removed = draftRuntimeCoordinator.removePreviousComposedItem(before: itemID, from: region)
                if removed {
                    refreshPreview(for: region)
                }
                return removed
            },
            focusedRegion:
                editorInteractionState.focusedEditorRegion,
            activeModuleRegion:
                editorInteractionState.activeModuleRegion,
            modules: modules(for:),
            categoryTitle: moduleCategoryTitle,
            valueText: moduleDisplayText,
            insertionMarkerID: { region in
                if editorInteractionState.recentInsertionRegion == region {
                    return editorInteractionState.recentInsertionItemID
                }

                // While the candidate surface is open, keep one quiet marker
                // beside the active text node so the saved insertion context
                // remains visible after the keyboard has been dismissed.
                guard editorInteractionState.activeModuleRegion == region else {
                    return nil
                }
                return editorInteractionState.activeTextItemIDs[region]
            },
            showsInsertionMarkerAtEnd: { region in
                editorInteractionState.activeModuleRegion == region
                    && editorInteractionState.activeTextItemIDs[region] == nil
            },
            onSelectModule: { module, region in
                if region == .slotA {
                    editorInteractionState.slotATextKitCommandBus
                        .insert(moduleItem(module))
                    editorInteractionState.clearInsertionContext()
                } else if region == .slotB {
                    editorInteractionState.slotBTextKitCommandBus
                        .insert(moduleItem(module))
                    editorInteractionState.clearInsertionContext()
                } else if region == .slotC {
                    editorInteractionState.slotCTextKitCommandBus
                        .insert(moduleItem(module))
                    editorInteractionState.clearInsertionContext()
                } else if region == .slotD {
                    editorInteractionState.slotDTextKitCommandBus
                        .insert(moduleItem(module))
                    editorInteractionState.clearInsertionContext()
                } else {
                    editorInteractionState.recentInsertionRegion = region
                    editorInteractionState.recentInsertionItemID =
                        insert(module, into: region)
                }
                applyModulePanelState(
                    ModulePanelCoordinator.selectModule(
                        module,
                        state: modulePanelState
                    )
                )
            },
            onCloseModuleLibrary: {
                applyModulePanelState(
                    ModulePanelCoordinator.setSheetPresented(
                        false,
                        state: modulePanelState
                    )
                )
            }
        )
    }

    /// FilmMark uses the same native TextKit editor surface as a single card
    /// region, but its binding is deliberately its own content carrier. The
    /// `.slotA` value below is only a visual editor identity required by the
    /// reusable control; it never reads or writes the classic slot-A draft.
    var filmMarkEditorCluster: some View {
        MemoryCardRegionEditorCluster(
            presentationStyle: .filmMark,
            visibleRegions: [.slotA],
            photoDescriptionRegions: [],
            slotATextKitCommandBus: editorInteractionState.slotATextKitCommandBus,
            slotBTextKitCommandBus: editorInteractionState.slotBTextKitCommandBus,
            slotCTextKitCommandBus: editorInteractionState.slotCTextKitCommandBus,
            slotDTextKitCommandBus: editorInteractionState.slotDTextKitCommandBus,
            draft: { _ in filmMarkContentDraft },
            onFocus: { region in
                focusRegionEditor(for: region)
            },
            onFocusTextItem: { _, _ in },
            onFocusTrailingText: { _ in },
            onUpdateTextItem: { _, item, text in
                var draft = filmMarkContentDraft
                draft.updateTextItem(item, text: text)
                updateFilmMarkContentDraft(draft)
            },
            onReplaceDraft: { _, draft in
                updateFilmMarkContentDraft(draft)
            },
            onPrependText: { _, text in
                var draft = filmMarkContentDraft
                _ = draft.prependText(text)
                updateFilmMarkContentDraft(draft)
            },
            onAppendText: { _, text in
                var draft = filmMarkContentDraft
                _ = draft.appendText(text)
                updateFilmMarkContentDraft(draft)
            },
            onRemoveItem: { _, item in
                var draft = filmMarkContentDraft
                draft.items.removeAll { $0.id == item.id }
                draft.normalizeTrailingTextInput()
                updateFilmMarkContentDraft(draft)
            },
            onRemovePreviousComposedItem: { _, _ in false },
            focusedRegion: editorInteractionState.focusedEditorRegion,
            activeModuleRegion: editorInteractionState.activeModuleRegion,
            modules: modules(for:),
            categoryTitle: moduleCategoryTitle,
            valueText: moduleDisplayText,
            insertionMarkerID: { _ in nil },
            showsInsertionMarkerAtEnd: { _ in false },
            onSelectModule: { module, _ in
                editorInteractionState.slotATextKitCommandBus
                    .insert(moduleItem(module))
                editorInteractionState.clearInsertionContext()
                applyModulePanelState(
                    ModulePanelCoordinator.selectModule(
                        module,
                        state: modulePanelState
                    )
                )
            },
            onCloseModuleLibrary: {
                applyModulePanelState(
                    ModulePanelCoordinator.setSheetPresented(
                        false,
                        state: modulePanelState
                    )
                )
            }
        )
    }

    private func focusRegionEditor(
        for region: CardRegion
    ) {
        editorInteractionState.clearInsertionContext()
        applyModulePanelState(
            ModulePanelCoordinator.focusRegion(
                region,
                state: modulePanelState
            )
        )
    }

    private func showModuleLibrary(
        for region: CardRegion
    ) {
        applyModulePanelState(
            ModulePanelCoordinator.showModules(
                for: region,
                state: modulePanelState
            )
        )
    }

    func toggleModuleLibraryFromToolbar() {
        if editorInteractionState.activeModuleRegion != nil {
            applyModulePanelState(ModulePanelCoordinator.setSheetPresented(false, state: modulePanelState))
            return
        }
        guard let focusedEditorRegion =
            editorInteractionState.focusedEditorRegion
        else { return }
        dismissKeyboard()
        showModuleLibrary(for: focusedEditorRegion)
    }

    func resetCardEditorState() {
        editorInteractionState.clearInsertionContext()
        dismissKeyboard()
        applyModulePanelState(ModulePanelCoordinator.focusEditor(state: modulePanelState))
    }

    var resolvedSubjectAvatarLogoImagePath: String? {
        session.state.selectedSubject?
            .identity.avatarBadgeImagePath
        ?? session.state.selectedSubject?
            .identity.avatarImagePath
    }

    var subjectAvatarBadge: Badge {
        Badge(
            name: OptimizedSubjectAvatarAsset.subjectAvatarBadgeName,
            type: .customUpload,
            imagePath: resolvedSubjectAvatarLogoImagePath,
            isSystemDefault: false
        )
    }

    var resolvedMemoryWriteText: String {
        MemoryWriteTextPresenter
            .resolvedText(
                subject:
                    alignedSelectedSubject()
                    ?? session.state.selectedSubject,
                usesCustomText:
                    session.usesCustomMemoryWriteText,
                customText:
                    session.customMemoryWriteText,
                smartModuleCarrierRegion:
                    session.smartModuleCarrierRegion
            )
    }

    func draft(for region: CardRegion) -> MemoryCardEditorDraft {
        draftRuntimeCoordinator
            .draft(for: region)
    }

    private func setActiveTextItem(
        _ itemID: UUID?,
        for region: CardRegion
    ) {
        draftRuntimeCoordinator
            .setActiveTextItem(
                itemID,
                for: region
            )
    }

    private func updateTextItem(
        _ itemID: UUID,
        text: String,
        for region: CardRegion
    ) {
        draftRuntimeCoordinator
            .updateTextItem(
                itemID,
                text: text,
                for: region
            )
    }

    private func prependText(
        _ text: String,
        to region: CardRegion
    ) {
        draftRuntimeCoordinator
            .prependText(
                text,
                to: region
            )
    }

    private func appendText(
        _ text: String,
        to region: CardRegion
    ) {
        draftRuntimeCoordinator
            .appendText(
                text,
                to: region
            )
    }

    private func removeItem(
        _ itemID: UUID,
        from region: CardRegion
    ) {
        draftRuntimeCoordinator
            .removeItem(
                itemID,
                from: region
            )
    }

    var draftOrchestrationState:
        DraftOrchestrationCoordinator.ViewState {
            DraftOrchestrationCoordinator
            .ViewState(
                regionDrafts: regionDrafts,
                activeTextItemIDs:
                    editorInteractionState.activeTextItemIDs,
                activeConfigurationStatus:
                    activeConfigurationStatus
            )
    }

    func applyDraftOrchestrationState(
        _ state:
            DraftOrchestrationCoordinator.ViewState
    ) {
        editorDraftState.replaceActive(
            state.regionDrafts
        )
        editorInteractionState.activeTextItemIDs =
            state.activeTextItemIDs
        activeConfigurationStatus =
            state.activeConfigurationStatus
    }

    private func refreshPreview(for region: CardRegion) {
        draftRuntimeCoordinator
            .refreshPreview(
                for: region
            )
    }

    func refreshDynamicPreview() {
        draftRuntimeCoordinator
            .refreshDynamicPreview()
    }

    func previewText(
        for region: CardRegion
    ) -> String {
        previewSyncCoordinator
            .previewText(
                for: region
            )
    }

    var filmMarkPreviewText: String {
        guard presentationStyle == .filmMark else {
            return previewText(
                for: CardRegion.region(for: .leftPrimary)
            )
        }

        return composedText(for: filmMarkContentDraft)
    }

    private func templateText(for draft: MemoryCardEditorDraft) -> String {
        draft.singleLineTemplateText
    }

    private func composedText(
        for draft: MemoryCardEditorDraft
    ) -> String {
        PreviewDraftAdapter.composedText(
            for: draft,
            context: previewCompositionContext,
            engine: previewCompositionEngine
        )
    }

    func previewRenderModel(
        for draft: MemoryCardPreviewDraft
    ) -> MemoryCardPreviewRenderModel {
        PreviewDraftAdapter.renderModel(
            for: draft,
            context: previewCompositionContext,
            engine: previewCompositionEngine
        )
    }

    func makeDefaultDraft(
        for region: CardRegion
    ) -> MemoryCardEditorDraft {
        PreviewDraftAdapter.defaultDraft(
            for: region,
            templateID: session.activeTemplateID(for: region),
            context: previewCompositionContext,
            engine: previewCompositionEngine
        )
    }

    private func moduleItem(
        _ module: IOSInsertableModule
    ) -> MemoryCardContentItem {
        PreviewDraftAdapter.moduleItem(
            module,
            context: previewCompositionContext,
            engine: previewCompositionEngine
        )
    }

    func defaultFilmMarkPrimaryOutputDraft() -> MemoryCardEditorDraft {
        var draft = MemoryCardEditorDraft(
            items: FilmMarkContentSchemaV2.defaultPrimaryOutputModules.map(
                moduleItem
            )
        )
        draft.normalizeTrailingTextInput()
        return draft
    }

    private func updateFilmMarkContentDraft(
        _ draft: MemoryCardEditorDraft
    ) {
        var normalized = draft
        normalized.normalizeTrailingTextInput()
        filmMarkContentDraft = normalized
        activeConfigurationStatus = .dirty
        refreshDynamicPreview()
    }

    private func insert(
        _ module: IOSInsertableModule,
        into region: CardRegion
    ) -> UUID {
        let item = moduleItem(module)
        draftRuntimeCoordinator.insert(item, into: region)
        return item.id
    }

}
#endif
