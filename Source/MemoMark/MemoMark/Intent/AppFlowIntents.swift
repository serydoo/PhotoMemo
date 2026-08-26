#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct QueueBatchJobIntent:
    MemoMarkIntent {

    let urls: [URL]

    let launchSource:
        BatchJobLaunchSource

    let title: String?

    let coordinator:
        QueueCoordinator

    func execute()
    async -> MemoMarkResult<
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
    MemoMarkIntent {

    let urls: [URL]

    let importSummary:
        ExternalPhotoImportSummary?

    let source:
        BatchJobLaunchSource

    let coordinator:
        ShareCoordinator

    func execute()
    async -> MemoMarkResult<
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
