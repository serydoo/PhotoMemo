#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Application boundary for notification delivery after a durable queue
/// transition. The notification adapter may read the current immutable job
/// projection and acknowledge only its own durable delivery markers; it does
/// not depend on the UI-facing queue facade.
@MainActor
protocol BatchQueueNotificationRuntime: AnyObject {

    func notificationJob(
        for jobID: UUID
    ) -> BatchJob?

    func markStartNotificationSent(
        for jobID: UUID
    ) async

    func markFinalNotificationSent(
        for jobID: UUID
    ) async

    func releaseNotificationAttachmentsIfCovered(
        for jobID: UUID
    ) async
}

extension BatchQueueStore: BatchQueueNotificationRuntime {

    func notificationJob(
        for jobID: UUID
    ) -> BatchJob? {

        jobs.first {
            $0.id == jobID
        }
    }
}
#endif
