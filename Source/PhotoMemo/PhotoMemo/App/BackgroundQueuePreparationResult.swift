enum BackgroundQueuePreparationResult: Equatable {
    case prepared
    case preparedRequiringRetry
    case nothingToProcess
    case retryableFailure
    case permanentFailure

    var canRunQueue: Bool {
        switch self {
        case .prepared, .preparedRequiringRetry, .nothingToProcess:
            return true
        case .retryableFailure, .permanentFailure:
            return false
        }
    }

    var runResultWithoutProcessing:
        BackgroundQueueRunResult? {
        switch self {
        case .prepared, .preparedRequiringRetry:
            return nil
        case .nothingToProcess:
            return .completed
        case .retryableFailure:
            return .retryScheduled
        case .permanentFailure:
            return .requiresUserAction
        }
    }

    var requiresRetryAfterProcessing: Bool {
        self == .preparedRequiringRetry
    }

    static func resolve(
        enqueuedRequestCount: Int,
        failedRequestCount: Int,
        pendingTaskCount: Int
    ) -> Self {

        if failedRequestCount > 0 {
            return pendingTaskCount > 0
                ? .preparedRequiringRetry
                : .retryableFailure
        }
        if enqueuedRequestCount > 0
            || pendingTaskCount > 0 {
            return .prepared
        }
        return .nothingToProcess
    }
}
