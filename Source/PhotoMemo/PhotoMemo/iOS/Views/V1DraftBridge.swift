#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1DraftBridge {

    struct ViewState: Hashable {
        var regionDrafts: [CardRegion: V1EditorDraft]
        var activeTextItemIDs: [CardRegion: UUID]
        var activeConfigurationMessage: String
    }

    nonisolated static func mutationState(
        regionDrafts: [CardRegion: V1EditorDraft],
        activeTextItemIDs: [CardRegion: UUID],
        activeConfigurationMessage: String
    ) -> V1DraftMutationCoordinator.State {
        V1DraftMutationCoordinator.State(
            regionDrafts: regionDrafts.mapValues(mutationDraft(from:)),
            activeTextItemIDs: activeTextItemIDs,
            activeConfigurationMessage: activeConfigurationMessage
        )
    }

    nonisolated static func viewState(
        from state: V1DraftMutationCoordinator.State
    ) -> ViewState {
        ViewState(
            regionDrafts: state.regionDrafts.mapValues(editorDraft(from:)),
            activeTextItemIDs: state.activeTextItemIDs,
            activeConfigurationMessage: state.activeConfigurationMessage
        )
    }

    nonisolated static func previewDraft(
        from draft: V1EditorDraft
    ) -> V1PreviewDraft {
        V1PreviewDraft(
            items:
                draft.items.map(
                    previewItem(from:)
                )
        )
    }

    nonisolated static func mutationDraft(
        from draft: V1EditorDraft
    ) -> V1DraftMutationDraft {
        V1DraftMutationDraft(
            items:
                draft.items.map(
                    mutationItem(from:)
                )
        )
    }

    nonisolated static func editorDraft(
        from draft: V1PreviewDraft
    ) -> V1EditorDraft {
        V1EditorDraft(
            items:
                draft.items.map(
                    editorItem(from:)
                )
        )
    }

    nonisolated static func editorDraft(
        from draft: V1DraftMutationDraft
    ) -> V1EditorDraft {
        V1EditorDraft(
            items:
                draft.items.map(
                    editorItem(from:)
                )
        )
    }

    nonisolated static func editorItem(
        from item: V1PreviewDraftItem
    ) -> V1ContentItem {
        V1ContentItem(
            id: item.id,
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
        from item: V1ContentItem
    ) -> V1PreviewDraftItem {
        V1PreviewDraftItem(
            id: item.id,
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
        from item: V1ContentItem
    ) -> V1DraftMutationItem {
        V1DraftMutationItem(
            id: item.id,
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
        from item: V1DraftMutationItem
    ) -> V1ContentItem {
        V1ContentItem(
            id: item.id,
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
        from kind: V1ContentItem.Kind
    ) -> V1DraftMutationItem.Kind {
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
        from kind: V1ContentItem.Kind
    ) -> V1PreviewDraftItem.Kind {
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
        from kind: V1PreviewDraftItem.Kind
    ) -> V1ContentItem.Kind {
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
        from kind: V1DraftMutationItem.Kind
    ) -> V1ContentItem.Kind {
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
