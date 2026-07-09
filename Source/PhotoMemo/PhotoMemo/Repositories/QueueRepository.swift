#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

@MainActor
final class QueueRepository {

    private let batchQueueStore:
        BatchQueueStore

    init(
        batchQueueStore:
            BatchQueueStore
    ) {
        self.batchQueueStore =
            batchQueueStore
    }

    var jobs: [BatchJob] {
        batchQueueStore.jobs
    }

    var defaultConfigurationSnapshot:
        BatchConfigurationSnapshot {
        batchQueueStore
            .defaultConfigurationSnapshot
    }

    func updateDefaultConfiguration(
        _ snapshot: BatchConfigurationSnapshot
    ) {

        batchQueueStore
            .updateDefaultConfiguration(
                snapshot
            )
    }

    func enqueue(
        urls: [URL],
        launchSource: BatchJobLaunchSource,
        title: String?
    ) -> BatchJob? {

        batchQueueStore.enqueue(
            urls: urls,
            launchSource: launchSource,
            title: title
        )
    }

    func enqueue(
        payloads: [BatchTaskIntakePayload],
        configuration: BatchConfigurationSnapshot,
        launchSource: BatchJobLaunchSource,
        intakeSummary:
            ExternalPhotoImportSummary? = nil,
        title: String? = nil
    ) -> BatchJob? {

        batchQueueStore.enqueue(
            payloads: payloads,
            configuration: configuration,
            launchSource: launchSource,
            intakeSummary:
                intakeSummary,
            title: title
        )
    }

    func retryFailedTasks(
        in jobID: UUID
    ) {

        batchQueueStore
            .retryFailedTasks(
                in: jobID
            )
    }

    func cancelJob(
        _ jobID: UUID
    ) {

        batchQueueStore
            .cancelJob(jobID)
    }

    func clearCompletedHistory(
        preserving jobID: UUID?
    ) {

        batchQueueStore
            .clearTerminalExternalJobHistory(
                preserving: jobID
            )
    }
}
#endif
