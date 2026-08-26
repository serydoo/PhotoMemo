#if !MEMOMARK_SHARE_EXTENSION
import Foundation

@MainActor
final class QueueCoordinator {

    private let queueRepository:
        QueueRepository

    init(
        queueRepository:
            QueueRepository
    ) {
        self.queueRepository =
            queueRepository
    }

    func enqueue(
        urls: [URL],
        launchSource: BatchJobLaunchSource,
        title: String? = nil
    ) -> MemoMarkResult<BatchJob> {

        guard let job =
            queueRepository.enqueue(
                urls: urls,
                launchSource: launchSource,
                title: title
            ) else {
            return .failure(
                MemoMarkError(
                    code: .queueOperationFailed,
                    message:
                        "Unable to enqueue the requested photo batch."
                )
            )
        }

        return .success(job)
    }

    func enqueue(
        payloads: [BatchTaskIntakePayload],
        configuration: BatchConfigurationSnapshot,
        launchSource: BatchJobLaunchSource,
        intakeSummary:
            ExternalPhotoImportSummary? = nil,
        intakeRequestID: UUID? = nil,
        title: String? = nil
    ) -> MemoMarkResult<BatchJob> {

        guard let job =
            queueRepository.enqueue(
                payloads: payloads,
                configuration: configuration,
                launchSource: launchSource,
                intakeSummary:
                    intakeSummary,
                intakeRequestID:
                    intakeRequestID,
                title: title
            ) else {
            return .failure(
                MemoMarkError(
                    code: .queueOperationFailed,
                    message:
                        "Unable to enqueue the requested batch payloads."
                )
            )
        }

        return .success(job)
    }

    func retryFailedTasks(
        in jobID: UUID
    ) -> MemoMarkResult<Void> {

        queueRepository
            .retryFailedTasks(
                in: jobID
            )
        return .success(())
    }

    func cancelJob(
        _ jobID: UUID
    ) -> MemoMarkResult<Void> {

        queueRepository
            .cancelJob(jobID)
        return .success(())
    }

    func clearCompletedHistory(
        preserving jobID: UUID?
    ) -> MemoMarkResult<Void> {

        queueRepository
            .clearCompletedHistory(
                preserving: jobID
            )
        return .success(())
    }

    func updateDefaultConfiguration(
        _ snapshot: BatchConfigurationSnapshot
    ) -> MemoMarkResult<Void> {

        queueRepository
            .updateDefaultConfiguration(
                snapshot
            )
        return .success(())
    }
}
#endif
