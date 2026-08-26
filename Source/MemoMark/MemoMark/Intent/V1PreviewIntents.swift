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

struct BuildV1PreviewRenderModelIntent:
    MemoMarkIntent {

    let draft: V1PreviewDraft

    let context: V1PreviewCompositionContext

    let engine:
        V1PreviewCompositionEngine

    func execute()
    async -> MemoMarkResult<
        V1PreviewRenderModel
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> MemoMarkResult<
        V1PreviewRenderModel
    > {

        .success(
            engine.renderModel(
                for: draft,
                context: context
            )
        )
    }
}

struct BootstrapV1PreviewDraftsIntent:
    MemoMarkIntent {

    let templateIDsByRegion:
        [CardRegion: String]

    let context: V1PreviewCompositionContext

    let engine:
        V1PreviewCompositionEngine

    func execute()
    async -> MemoMarkResult<
        [CardRegion: V1PreviewDraft]
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> MemoMarkResult<
        [CardRegion: V1PreviewDraft]
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
