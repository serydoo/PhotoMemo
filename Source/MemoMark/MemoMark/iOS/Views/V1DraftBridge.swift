#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct DraftBridge {

    struct ViewState: Hashable {
        var regionDrafts: [CardRegion: MemoryCardEditorDraft]
        var activeTextItemIDs: [CardRegion: UUID]
        var activeConfigurationStatus:
            ConfigurationPersistenceStatus
    }

    nonisolated static func mutationState(
        regionDrafts: [CardRegion: MemoryCardEditorDraft],
        activeTextItemIDs: [CardRegion: UUID],
        activeConfigurationStatus:
            ConfigurationPersistenceStatus
    ) -> DraftMutationCoordinator.State {
        DraftMutationCoordinator.State(
            regionDrafts: regionDrafts.mapValues(mutationDraft(from:)),
            activeTextItemIDs: activeTextItemIDs,
            activeConfigurationStatus:
                activeConfigurationStatus
        )
    }

    nonisolated static func viewState(
        from state: DraftMutationCoordinator.State
    ) -> ViewState {
        ViewState(
            regionDrafts: state.regionDrafts.mapValues(editorDraft(from:)),
            activeTextItemIDs: state.activeTextItemIDs,
            activeConfigurationStatus:
                state.activeConfigurationStatus
        )
    }

    nonisolated static func previewDraft(
        from draft: MemoryCardEditorDraft
    ) -> MemoryCardPreviewDraft {
        MemoryCardPreviewDraft(
            items:
                draft.items.map(
                    previewItem(from:)
                )
        )
    }

    nonisolated static func mutationDraft(
        from draft: MemoryCardEditorDraft
    ) -> DraftMutationDraft {
        DraftMutationDraft(
            items:
                draft.items.map(
                    mutationItem(from:)
                )
        )
    }

    nonisolated static func editorDraft(
        from draft: MemoryCardPreviewDraft
    ) -> MemoryCardEditorDraft {
        MemoryCardEditorDraft(
            items:
                draft.items.map(
                    editorItem(from:)
                )
        )
    }

    nonisolated static func editorDraft(
        from draft: DraftMutationDraft
    ) -> MemoryCardEditorDraft {
        MemoryCardEditorDraft(
            items:
                draft.items.map(
                    editorItem(from:)
                )
        )
    }

    nonisolated static func editorItem(
        from item: MemoryCardPreviewDraftItem
    ) -> MemoryCardContentItem {
        MemoryCardContentItem(
            id: item.id,
            sourceItemID: item.sourceItemID,
            kind:
                editorKind(
                    from: item.kind
                ),
            title: item.title,
            value: item.value,
            savedValue: item.savedValue,
            systemImage: item.systemImage
        )
    }

    nonisolated static func previewItem(
        from item: MemoryCardContentItem
    ) -> MemoryCardPreviewDraftItem {
        MemoryCardPreviewDraftItem(
            id: item.id,
            sourceItemID: item.sourceItemID,
            kind:
                previewKind(
                    from: item.kind
                ),
            title: item.title,
            value: item.value,
            savedValue: item.savedValue,
            systemImage: item.systemImage
        )
    }

    nonisolated static func mutationItem(
        from item: MemoryCardContentItem
    ) -> DraftMutationItem {
        DraftMutationItem(
            id: item.id,
            sourceItemID: item.sourceItemID,
            kind:
                mutationKind(
                    from: item.kind
                ),
            title: item.title,
            value: item.value,
            savedValue: item.savedValue,
            systemImage: item.systemImage
        )
    }

    nonisolated private static func editorItem(
        from item: DraftMutationItem
    ) -> MemoryCardContentItem {
        MemoryCardContentItem(
            id: item.id,
            sourceItemID: item.sourceItemID,
            kind:
                editorKind(
                    from: item.kind
                ),
            title: item.title,
            value: item.value,
            savedValue: item.savedValue,
            systemImage: item.systemImage
        )
    }

    nonisolated private static func mutationKind(
        from kind: MemoryCardContentItem.Kind
    ) -> DraftMutationItem.Kind {
        switch kind {
        case .text:
            return .text
        case .token:
            return .token
        case .separator:
            return .separator
        case .lineBreak:
            return .lineBreak
        }
    }

    nonisolated private static func previewKind(
        from kind: MemoryCardContentItem.Kind
    ) -> MemoryCardPreviewDraftItem.Kind {
        switch kind {
        case .text:
            return .text
        case .token:
            return .token
        case .separator:
            return .separator
        case .lineBreak:
            return .lineBreak
        }
    }

    nonisolated private static func editorKind(
        from kind: MemoryCardPreviewDraftItem.Kind
    ) -> MemoryCardContentItem.Kind {
        switch kind {
        case .text:
            return .text
        case .token:
            return .token
        case .separator:
            return .separator
        case .lineBreak:
            return .lineBreak
        }
    }

    nonisolated private static func editorKind(
        from kind: DraftMutationItem.Kind
    ) -> MemoryCardContentItem.Kind {
        switch kind {
        case .text:
            return .text
        case .token:
            return .token
        case .separator:
            return .separator
        case .lineBreak:
            return .lineBreak
        }
    }
}
#endif
