#if !MEMOMARK_SHARE_EXTENSION
import Foundation

@MainActor
final class PreviewCoordinator {

    private let buildService:
        RecordCardBuildService

    init(
        buildService:
            RecordCardBuildService
    ) {
        self.buildService =
            buildService
    }

    func buildCard(
        from photo: SelectedPhoto,
        configuration: BatchConfigurationSnapshot
    ) -> MemoMarkResult<RecordCard> {

        .success(
            buildService.buildCard(
                from: photo,
                configuration: configuration
            )
        )
    }

    func defaultPhotoDescription(
        from photo: SelectedPhoto,
        configuration: BatchConfigurationSnapshot
    ) -> MemoMarkResult<String> {

        .success(
            buildService.defaultPhotoDescription(
                from: photo,
                configuration: configuration
            )
        )
    }

    func updateRegionPreview(
        region: CardRegion,
        text: String,
        session: ConfigurationSession
    ) -> MemoMarkResult<Void> {

        session.updateRegionPreview(
            region: region,
            text: text
        )
        return .success(())
    }

    func updateRegionPreviews(
        _ previews: [CardRegion: String],
        session: ConfigurationSession
    ) -> MemoMarkResult<Void> {

        for (region, text) in previews {
            session.updateRegionPreview(
                region: region,
                text: text
            )
        }

        return .success(())
    }

    func previewText(
        for region: CardRegion,
        session: ConfigurationSession
    ) -> MemoMarkResult<String> {

        .success(
            session.previewText(
                for: region
            )
        )
    }
}
#endif
