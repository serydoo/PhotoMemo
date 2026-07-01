#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1PreviewSyncCoordinator {

    private let composeText:
        (V1PreviewDraft) -> String

    private let syncRegionPreview:
        (CardRegion, String) -> Void

    private let syncRegionPreviews:
        ([CardRegion: String]) -> Void

    private let loadPreviewText:
        (CardRegion) -> String

    init(
        composeText: @escaping (V1PreviewDraft) -> String,
        syncRegionPreview: @escaping (CardRegion, String) -> Void,
        syncRegionPreviews: @escaping ([CardRegion: String]) -> Void,
        loadPreviewText: @escaping (CardRegion) -> String
    ) {
        self.composeText =
            composeText
        self.syncRegionPreview =
            syncRegionPreview
        self.syncRegionPreviews =
            syncRegionPreviews
        self.loadPreviewText =
            loadPreviewText
    }

    init(
        session: ConfigurationSession,
        coordinator: PreviewCoordinator?,
        context: V1PreviewCompositionContext,
        engine: V1PreviewCompositionEngine
    ) {
        self.init(
            composeText: {
                draft in
                switch ComposeV1PreviewTextIntent(
                    draft: draft,
                    context: context,
                    engine: engine
                )
                .executeSynchronously() {
                case .success(let text):
                    return text
                case .failure:
                    return InlineContentTextComposer.compose(
                        draft.items.map { item in
                            InlineContentTextComposer.Piece(
                                kind:
                                    Self.inlineComposerKind(
                                        for: item.kind
                                    ),
                                value:
                                    item.displayValue
                            )
                        }
                    )
                }
            },
            syncRegionPreview: {
                region, text in
                if let coordinator {
                    _ =
                        UpdateRegionPreviewIntent(
                            region: region,
                            text: text,
                            session: session,
                            coordinator:
                                coordinator
                        )
                        .executeSynchronously()
                    return
                }

                session.updateRegionPreview(
                    region: region,
                    text: text
                )
            },
            syncRegionPreviews: {
                previews in
                if let coordinator {
                    _ =
                        UpdateRegionPreviewsIntent(
                            previews: previews,
                            session: session,
                            coordinator:
                                coordinator
                        )
                        .executeSynchronously()
                    return
                }

                for (region, text) in previews {
                    session.updateRegionPreview(
                        region: region,
                        text: text
                    )
                }
            },
            loadPreviewText: {
                region in
                guard let coordinator else {
                    return session.previewText(
                        for: region
                    )
                }

                switch LoadRegionPreviewTextIntent(
                    region: region,
                    session: session,
                    coordinator:
                        coordinator
                )
                .executeSynchronously() {
                case .success(let text):
                    return text
                case .failure:
                    return session.previewText(
                        for: region
                    )
                }
            }
        )
    }

    func refreshPreview(
        for region: CardRegion,
        draft: V1PreviewDraft
    ) {
        syncRegionPreview(
            region,
            composeText(draft)
        )
    }

    func refreshDynamicPreview(
        draftsByRegion:
            [CardRegion: V1PreviewDraft]
    ) {
        let previews =
            Dictionary(
                uniqueKeysWithValues:
                    draftsByRegion.map {
                        region, draft in
                        (
                            region,
                            composeText(draft)
                        )
                    }
            )

        syncRegionPreviews(
            previews
        )
    }

    func previewText(
        for region: CardRegion
    ) -> String {
        loadPreviewText(region)
    }

    private static func inlineComposerKind(
        for kind: V1PreviewDraftItem.Kind
    ) -> InlineContentTextComposer.PieceKind {
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
