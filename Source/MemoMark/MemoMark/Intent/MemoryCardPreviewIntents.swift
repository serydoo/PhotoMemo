#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct UpdateRegionPreviewIntent:
    MemoMarkIntent {

    let region: CardRegion

    let text: String

    let session: ConfigurationSession

    let coordinator:
        PreviewCoordinator

    func execute()
    async -> MemoMarkResult<
        Void
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> MemoMarkResult<
        Void
    > {

        coordinator.updateRegionPreview(
            region: region,
            text: text,
            session: session
        )
    }
}

struct UpdateRegionPreviewsIntent:
    MemoMarkIntent {

    let previews: [CardRegion: String]

    let session: ConfigurationSession

    let coordinator:
        PreviewCoordinator

    func execute()
    async -> MemoMarkResult<
        Void
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> MemoMarkResult<
        Void
    > {

        coordinator.updateRegionPreviews(
            previews,
            session: session
        )
    }
}

struct LoadRegionPreviewTextIntent:
    MemoMarkIntent {

    let region: CardRegion

    let session: ConfigurationSession

    let coordinator:
        PreviewCoordinator

    func execute()
    async -> MemoMarkResult<
        String
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> MemoMarkResult<
        String
    > {

        coordinator.previewText(
            for: region,
            session: session
        )
    }
}

struct BuildMemoryCardPreviewRenderModelIntent:
    MemoMarkIntent {

    let draft: MemoryCardPreviewDraft

    let context: MemoryCardPreviewCompositionContext

    let engine:
        MemoryCardPreviewCompositionEngine

    func execute()
    async -> MemoMarkResult<
        MemoryCardPreviewRenderModel
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> MemoMarkResult<
        MemoryCardPreviewRenderModel
    > {

        .success(
            engine.renderModel(
                for: draft,
                context: context
            )
        )
    }
}

struct BootstrapMemoryCardPreviewDraftsIntent:
    MemoMarkIntent {

    let templateIDsByRegion:
        [CardRegion: String]

    let context: MemoryCardPreviewCompositionContext

    let engine:
        MemoryCardPreviewCompositionEngine

    func execute()
    async -> MemoMarkResult<
        [CardRegion: MemoryCardPreviewDraft]
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> MemoMarkResult<
        [CardRegion: MemoryCardPreviewDraft]
    > {

        .success(
            engine.bootstrapDrafts(
                templateIDsByRegion:
                    templateIDsByRegion,
                context: context
            )
        )
    }
}
#endif
