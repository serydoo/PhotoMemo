#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Application boundary for producing the immutable card consumed by the
/// production export pipeline. Preview presentation may use this transaction,
/// but production work must not depend on the preview coordinator itself.
struct BuildRecordCardTransaction {

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

    /// Runs deterministic card compilation away from the UI actor. The
    /// synchronous method remains available to preview and compatibility
    /// callers; production queue execution uses this boundary so memory
    /// resolution cannot block Configuration Center rendering.
    func buildCardOffMainThread(
        from photo: SelectedPhoto,
        configuration: BatchConfigurationSnapshot
    ) async -> MemoMarkResult<RecordCard> {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(
                    returning: self.buildCard(
                        from: photo,
                        configuration: configuration
                    )
                )
            }
        }
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
}
#endif
