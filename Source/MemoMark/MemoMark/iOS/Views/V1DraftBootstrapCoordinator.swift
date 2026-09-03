#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct ConfigurationDraftBootstrapCoordinator {

    private let loadDrafts:
        () -> MemoMarkResult<
            [CardRegion: MemoryCardPreviewDraft]
        >

    init(
        loadDrafts: @escaping () -> MemoMarkResult<
            [CardRegion: MemoryCardPreviewDraft]
        >
    ) {
        self.loadDrafts = loadDrafts
    }

    init(
        session: ConfigurationSession,
        context: MemoryCardPreviewCompositionContext,
        engine: MemoryCardPreviewCompositionEngine
    ) {
        self.init {
            if let configuration =
                session.selectedMemoryConfiguration {
                return .success(
                    ConfigurationDraftProjection(
                        configuration: configuration
                    )
                    .regionDrafts
                    .mapValues {
                        DraftBridge.previewDraft(
                            from: $0
                        )
                    }
                )
            }

            return BootstrapMemoryCardPreviewDraftsIntent(
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
        makeDefaultDraft: (CardRegion) -> MemoryCardEditorDraft
    ) -> [CardRegion: MemoryCardEditorDraft] {
        switch loadDrafts() {
        case .success(let drafts):
            return Dictionary(
                uniqueKeysWithValues:
                    drafts.map { region, draft in
                        (
                            region,
                            DraftBridge
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
