#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct QueueBatchJobIntent:
    PhotoMemoIntent {

    let urls: [URL]

    let launchSource:
        BatchJobLaunchSource

    let title: String?

    let coordinator:
        QueueCoordinator

    func execute()
    async -> PhotoMemoResult<
        BatchJob
    > {

        coordinator.enqueue(
            urls: urls,
            launchSource: launchSource,
            title: title
        )
    }
}

struct SubmitExternalURLsIntent:
    PhotoMemoIntent {

    let urls: [URL]

    let importSummary:
        ExternalPhotoImportSummary?

    let source:
        BatchJobLaunchSource

    let coordinator:
        ShareCoordinator

    func execute()
    async -> PhotoMemoResult<
        ShareSubmissionReceipt
    > {

        coordinator.submit(
            urls: urls,
            importSummary:
                importSummary,
            source: source
        )
    }
}
#endif
