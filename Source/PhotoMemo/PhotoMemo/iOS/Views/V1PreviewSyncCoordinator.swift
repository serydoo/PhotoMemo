#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1PreviewSyncCoordinator {

    private let syncRegionPreview:
        (CardRegion, String) -> Void

    private let syncRegionPreviews:
        ([CardRegion: String]) -> Void

    private let loadPreviewText:
        (CardRegion) -> String

    init(
        syncRegionPreview: @escaping (CardRegion, String) -> Void,
        syncRegionPreviews: @escaping ([CardRegion: String]) -> Void,
        loadPreviewText: @escaping (CardRegion) -> String
    ) {
        self.syncRegionPreview =
            syncRegionPreview
        self.syncRegionPreviews =
            syncRegionPreviews
        self.loadPreviewText =
            loadPreviewText
    }

    init(
        session: ConfigurationSession,
        coordinator: PreviewCoordinator?
    ) {
        self.init(
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
        model: V1PreviewRenderModel
    ) {
        syncRegionPreview(
            region,
            model.displayText
        )
    }

    func refreshDynamicPreview(
        modelsByRegion:
            [CardRegion: V1PreviewRenderModel]
    ) {
        let previews =
            Dictionary(
                uniqueKeysWithValues:
                    modelsByRegion.map {
                        region, model in
                        (
                            region,
                            model.displayText
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
}
#endif
