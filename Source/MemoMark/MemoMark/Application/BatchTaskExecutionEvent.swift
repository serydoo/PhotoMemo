#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Finite task-state events emitted by media execution. Queue ownership
/// decides whether and when an event is accepted and durably persisted.
nonisolated enum BatchTaskExecutionEvent:
    Sendable {

    case processingStarted(
        progress: BatchTaskProgress
    )

    case metadataLoaded(
        captureDate: Date?,
        progress: BatchTaskProgress
    )

    case previewBuilt(
        progress: BatchTaskProgress
    )

    case exportStarted(
        progress: BatchTaskProgress
    )

    case photoLibrarySaveStarted(
        renderedFileURL: URL,
        progress: BatchTaskProgress
    )

    case completed(
        albumTitle: String,
        assetIdentifier: String,
        notificationAttachmentURL: URL?,
        progress: BatchTaskProgress
    )

    case photoLibraryReadbackPending

    case failed(BatchTaskFailure)

    case retryDisabled

    var transition:
        BatchTaskExecutionTransition {
        switch self {
        case .processingStarted:
            return .startProcessing
        case .metadataLoaded:
            return .recordMetadata
        case .previewBuilt:
            return .recordPreview
        case .exportStarted:
            return .startExport
        case .photoLibrarySaveStarted:
            return .startPhotoLibrarySave
        case .completed:
            return .complete
        case .photoLibraryReadbackPending:
            return .awaitPhotoLibraryReadback
        case .failed:
            return .fail
        case .retryDisabled:
            return .disableRetry
        }
    }

    func apply(
        to task: inout BatchTask
    ) {
        switch self {
        case .processingStarted(let progress):
            task.phase = .importing
            task.progress = progress
            task.failure = nil

        case .metadataLoaded(
            let captureDate,
            let progress
        ):
            task.captureDate = captureDate
            task.phase = .metadataReady
            task.progress = progress

        case .previewBuilt(let progress):
            task.phase = .previewReady
            task.progress = progress

        case .exportStarted(let progress):
            task.phase = .exporting
            task.progress = progress

        case .photoLibrarySaveStarted(
            let renderedFileURL,
            let progress
        ):
            task.renderedFileURL = renderedFileURL
            task.phase = .savingToPhotoLibrary
            task.progress = progress

        case .completed(
            let albumTitle,
            let assetIdentifier,
            let notificationAttachmentURL,
            let progress
        ):
            task.renderedFileURL = nil
            task.savedAlbumName = albumTitle
            task.savedAssetIdentifier = assetIdentifier
            task.notificationAttachmentURL =
                notificationAttachmentURL
            task.phase = .completed
            task.progress = progress

        case .photoLibraryReadbackPending:
            task.renderedFileURL = nil
            task.notificationAttachmentURL = nil
            task.failure = nil
            task.phase = .savingToPhotoLibrary
            task.progress = BatchTaskProgress(
                currentUnit:
                    max(
                        task.progress.totalUnits - 1,
                        0
                    ),
                totalUnits:
                    max(
                        task.progress.totalUnits,
                        1
                    ),
                stage:
                    .confirmingPhotoLibrarySave
            )

        case .failed(let failure):
            task.renderedFileURL = nil
            task.notificationAttachmentURL = nil
            task.phase = .failed
            task.failure = failure
            task.progress = BatchTaskProgress(
                currentUnit: 0,
                totalUnits: 1,
                stage: .failed
            )

        case .retryDisabled:
            task.failure?.canRetry = false
        }
    }
}
#endif
