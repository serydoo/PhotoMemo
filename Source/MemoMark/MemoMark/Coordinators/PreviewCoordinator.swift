#if !MEMOMARK_SHARE_EXTENSION
import Foundation

@MainActor
final class PreviewCoordinator {

    private let buildTransaction:
        BuildRecordCardTransaction

    init(
        buildTransaction:
            BuildRecordCardTransaction
    ) {
        self.buildTransaction =
            buildTransaction
    }

    convenience init(
        buildService:
            RecordCardBuildService
    ) {
        self.init(
            buildTransaction:
                BuildRecordCardTransaction(
                    buildService: buildService
                )
        )
    }

    func buildCard(
        from photo: SelectedPhoto,
        configuration: BatchConfigurationSnapshot
    ) -> MemoMarkResult<RecordCard> {

        buildTransaction.buildCard(
            from: photo,
            configuration: configuration
        )
    }

    func defaultPhotoDescription(
        from photo: SelectedPhoto,
        configuration: BatchConfigurationSnapshot
    ) -> MemoMarkResult<String> {

        buildTransaction.defaultPhotoDescription(
            from: photo,
            configuration: configuration
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
