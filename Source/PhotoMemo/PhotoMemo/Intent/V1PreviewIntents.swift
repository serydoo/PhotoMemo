#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct UpdateRegionPreviewIntent:
    PhotoMemoIntent {

    let region: CardRegion

    let text: String

    let session: ConfigurationSession

    let coordinator:
        PreviewCoordinator

    func execute()
    async -> PhotoMemoResult<
        Void
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> PhotoMemoResult<
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
    PhotoMemoIntent {

    let previews: [CardRegion: String]

    let session: ConfigurationSession

    let coordinator:
        PreviewCoordinator

    func execute()
    async -> PhotoMemoResult<
        Void
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> PhotoMemoResult<
        Void
    > {

        coordinator.updateRegionPreviews(
            previews,
            session: session
        )
    }
}

struct LoadRegionPreviewTextIntent:
    PhotoMemoIntent {

    let region: CardRegion

    let session: ConfigurationSession

    let coordinator:
        PreviewCoordinator

    func execute()
    async -> PhotoMemoResult<
        String
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> PhotoMemoResult<
        String
    > {

        coordinator.previewText(
            for: region,
            session: session
        )
    }
}

struct ComposeV1PreviewTextIntent:
    PhotoMemoIntent {

    let draft: V1PreviewDraft

    let context: V1PreviewCompositionContext

    let engine:
        V1PreviewCompositionEngine

    func execute()
    async -> PhotoMemoResult<
        String
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> PhotoMemoResult<
        String
    > {

        .success(
            engine.composeText(
                for: draft,
                context: context
            )
        )
    }
}

struct ResolveV1PreviewDisplayValueIntent:
    PhotoMemoIntent {

    let item: V1PreviewDraftItem

    let context: V1PreviewCompositionContext

    let engine:
        V1PreviewCompositionEngine

    func execute()
    async -> PhotoMemoResult<
        String
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> PhotoMemoResult<
        String
    > {

        .success(
            engine.resolvedDisplayValue(
                for: item,
                context: context
            )
        )
    }
}

struct BootstrapV1PreviewDraftsIntent:
    PhotoMemoIntent {

    let templateIDsByRegion:
        [CardRegion: String]

    let context: V1PreviewCompositionContext

    let engine:
        V1PreviewCompositionEngine

    func execute()
    async -> PhotoMemoResult<
        [CardRegion: V1PreviewDraft]
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> PhotoMemoResult<
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
