#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1DraftBootstrapCoordinator {

    private let loadDrafts:
        () -> PhotoMemoResult<
            [CardRegion: V1PreviewDraft]
        >

    init(
        loadDrafts: @escaping () -> PhotoMemoResult<
            [CardRegion: V1PreviewDraft]
        >
    ) {
        self.loadDrafts = loadDrafts
    }

    init(
        session: ConfigurationSession,
        context: V1PreviewCompositionContext,
        engine: V1PreviewCompositionEngine
    ) {
        self.init {
            BootstrapV1PreviewDraftsIntent(
                templateIDsByRegion:
                    Dictionary(
                        uniqueKeysWithValues:
                            CardRegion
                            .memoryCardRegions
                            .map { region in
                                (
                                    region,
                                    session
                                    .activeTemplateID(
                                        for: region
                                    ) ?? ""
                                )
                            }
                    ),
                context: context,
                engine: engine
            )
            .executeSynchronously()
        }
    }

    func bootstrapDrafts(
        makeDefaultDraft: (CardRegion) -> V1EditorDraft
    ) -> [CardRegion: V1EditorDraft] {
        switch loadDrafts() {
        case .success(let drafts):
            return Dictionary(
                uniqueKeysWithValues:
                    drafts.map { region, draft in
                        (
                            region,
                            V1DraftBridge
                            .editorDraft(
                                from: draft
                            )
                        )
                    }
            )
        case .failure:
            return Dictionary(
                uniqueKeysWithValues:
                    CardRegion
                    .memoryCardRegions
                    .map { region in
                        (
                            region,
                            makeDefaultDraft(region)
                        )
                    }
            )
        }
    }
}
#endif
