enum BackgroundQueueRunResult: Equatable {
    case completed
    case retryScheduled
    case requiresUserAction

    var systemTaskSucceeded: Bool {
        self == .completed
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
