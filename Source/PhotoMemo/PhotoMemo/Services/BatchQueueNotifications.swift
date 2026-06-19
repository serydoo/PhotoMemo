#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

@MainActor
final class BatchQueueNotifications {

    private let notificationService:
        BatchNotificationService

    init(
        notificationService:
            BatchNotificationService? = nil
    ) {
        self.notificationService =
            notificationService
            ?? BatchNotificationService()
    }

    func scheduleStartNotificationIfNeeded(
        for jobID: UUID,
        in store: BatchQueueStore
    ) {

        Task { @MainActor [weak store] in
            guard let store else {
                return
            }

            await deliverStartNotificationIfNeeded(
                for: jobID,
                in: store
            )
        }
    }

    func deliverStartNotificationIfNeeded(
        for jobID: UUID,
        in store: BatchQueueStore
    ) async {

        guard let jobIndex =
            store.jobIndex(
                for: jobID
            ),
            let job =
                store.job(at: jobIndex)
        else {
            return
        }

        guard job.startNotificationSentAt == nil
        else {
            return
        }

        let didSend =
            await notificationService
            .notifyJobQueued(job)

        guard didSend else {
            return
        }

        store.markStartNotificationSent(
            at: jobIndex
        )
    }

    func deliverProgressNotificationIfNeeded(
        for jobID: UUID,
        stage: String,
        in store: BatchQueueStore
    ) async {

        guard let jobIndex =
            store.jobIndex(
                for: jobID
            ),
            let job =
                store.job(at: jobIndex)
        else {
            return
        }

        guard job.lastProgressNotificationStage
            != stage else {
            return
        }

        let didSend =
            await notificationService
            .notifyJobProgress(
                job,
                stage: stage
            )

        guard didSend else {
            return
        }

        store.markProgressNotificationSent(
            at: jobIndex,
            stage: stage
        )
    }

    func deliverFinalNotificationIfNeeded(
        for jobID: UUID,
        in store: BatchQueueStore
    ) async {

        guard let jobIndex =
            store.jobIndex(
                for: jobID
            ),
            let job =
                store.job(at: jobIndex)
        else {
            return
        }

        guard job.finalNotificationSentAt == nil
        else {
            return
        }

        guard shouldSendFinalNotification(
            for: job
        ) else {
            return
        }

        let didSend =
            await notificationService
            .notifyJobFinished(job)

        guard didSend else {
            return
        }

        store.markFinalNotificationSent(
            at: jobIndex
        )
    }
}

private extension BatchQueueNotifications {

    func shouldSendFinalNotification(
        for job: BatchJob
    ) -> Bool {

        guard job.tasks.allSatisfy({
            $0.phase.isTerminal
        }) else {
            return false
        }

        guard job.state != .cancelled else {
            return false
        }

        return job.completedTaskCount > 0
            || job.failedTaskCount > 0
    }
}
#endif
