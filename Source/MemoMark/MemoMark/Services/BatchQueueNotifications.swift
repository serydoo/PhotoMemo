#if !MEMOMARK_SHARE_EXTENSION
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
        in runtime: any BatchQueueNotificationRuntime
    ) {

        Task { @MainActor [weak runtime] in
            guard let runtime else {
                return
            }

            await deliverStartNotificationIfNeeded(
                for: jobID,
                in: runtime
            )
        }
    }

    func deliverStartNotificationIfNeeded(
        for jobID: UUID,
        in runtime: any BatchQueueNotificationRuntime
    ) async {

        guard let job = runtime.notificationJob(
            for: jobID
        )
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

        await runtime.markStartNotificationSent(
            for: job.id
        )
    }

    func deliverProgressNotificationIfNeeded(
        for jobID: UUID,
        stage: String
    ) async {
        // Stage-by-stage progress belongs to Live Activity. Reposting local
        // notifications for each phase creates stacked cards in Notification
        // Center and is not reliable as a real-time progress surface.
        _ = jobID
        _ = stage
    }

    func deliverFinalNotificationIfNeeded(
        for jobID: UUID,
        in runtime: any BatchQueueNotificationRuntime
    ) async {

        guard let job = runtime.notificationJob(
            for: jobID
        )
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
            await runtime.releaseNotificationAttachmentsIfCovered(
                for: jobID
            )
            return
        }

        await runtime.markFinalNotificationSent(
            for: job.id
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
