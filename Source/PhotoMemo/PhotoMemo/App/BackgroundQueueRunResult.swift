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

        if cancellationRequested || retryRequested {
            return .retryScheduled
        }
        return pendingTaskCount == 0
            ? .completed
            : .retryScheduled
    }
}
