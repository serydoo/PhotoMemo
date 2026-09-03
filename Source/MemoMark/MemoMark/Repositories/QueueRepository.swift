#if !MEMOMARK_SHARE_EXTENSION
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
    ) async -> BatchJob? {

        await batchQueueStore.enqueue(
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
        intakeRequestID: UUID? = nil,
        title: String? = nil
    ) async -> BatchJob? {

        await batchQueueStore.enqueue(
            payloads: payloads,
            configuration: configuration,
            launchSource: launchSource,
            intakeSummary:
                intakeSummary,
            intakeRequestID:
                intakeRequestID,
            title: title
        )
    }

    func retryFailedTasks(
        in jobID: UUID
    ) async {

        await batchQueueStore
            .retryFailedTasks(
                in: jobID
            )
    }

    func cancelJob(
        _ jobID: UUID
    ) async {

        await batchQueueStore
            .cancelJob(jobID)
    }

    func clearCompletedHistory(
        preserving jobID: UUID?
    ) async {

        await batchQueueStore
            .clearTerminalExternalJobHistory(
                preserving: jobID
            )
    }
}
#endif
