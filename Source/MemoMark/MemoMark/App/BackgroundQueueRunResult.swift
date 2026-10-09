enum BackgroundQueueRunResult: Equatable {
    case completed
    case retryScheduled
    case requiresUserAction
    case paused

    var systemTaskSucceeded: Bool {
        self == .completed || self == .paused
    }

    /// A native progress card represents output completion, rather than the
    /// scheduler merely finishing a run with held or terminal failed work.
    func continuedTaskSucceeded(session: ExecutionSession?) -> Bool {
        guard self == .completed, let session, session.totalCount > 0 else { return false }
        return session.completedCount == session.totalCount && session.pendingCount == 0 && session.failedCount == 0
    }

    static func resolve(
        cancellationRequested: Bool,
        retryRequested: Bool,
        pendingTaskCount: Int
    ) -> Self {

        if retryRequested {
            return .retryScheduled
        }
        // A system cancellation only warrants another background owner while
        // durable pending work remains. If the expiration handler has already
        // converted the active task into a terminal retryable failure, there
        // is no queue work for the scheduler to repeat; the user can invoke
        // the explicit retry action instead.
        if cancellationRequested {
            return pendingTaskCount > 0
                ? .retryScheduled
                : .completed
        }
        return pendingTaskCount == 0
            ? .completed
            : .retryScheduled
    }
}
