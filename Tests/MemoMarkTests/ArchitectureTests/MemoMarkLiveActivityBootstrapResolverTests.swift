#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Live Activity bootstrap resolver")
struct MemoMarkLiveActivityBootstrapResolverTests {

    @Test("Duplicate job activities retain one activity and return the remainder for cleanup")
    func duplicateJobActivitiesRetainOneActivityAndReturnTheRemainderForCleanup() {
        let firstJobID = UUID()
        let secondJobID = UUID()

        let result =
            MemoMarkLiveActivityBootstrapResolver.resolve(
                candidates: [
                    (jobID: firstJobID, activity: "first"),
                    (jobID: firstJobID, activity: "duplicate"),
                    (jobID: secondJobID, activity: "second")
                ]
            )

        #expect(result.trackedActivities.count == 2)
        #expect(result.trackedActivities[firstJobID] == "first")
        #expect(result.trackedActivities[secondJobID] == "second")
        #expect(result.duplicateActivities.count == 1)
        #expect(result.duplicateActivities.first?.jobID == firstJobID)
        #expect(result.duplicateActivities.first?.activity == "duplicate")
    }

    @Test("Bootstrap retains only the current job and ends stale invalid and duplicate activities")
    func bootstrapRetainsOnlyTheCurrentJobAndEndsAllOtherActivities() {
        let currentJobID = UUID()
        let staleJobID = UUID()

        let result =
            MemoMarkLiveActivityBootstrapResolver.resolve(
                candidates: [
                    (jobIDString: currentJobID.uuidString, activity: "current"),
                    (jobIDString: currentJobID.uuidString, activity: "duplicate"),
                    (jobIDString: staleJobID.uuidString, activity: "stale"),
                    (jobIDString: "not-a-uuid", activity: "invalid")
                ],
                currentJobID: currentJobID
            )

        #expect(result.trackedActivities == [currentJobID: "current"])
        #expect(
            Set(
                result.activitiesToEnd.map {
                    $0.activity
                }
            ) == ["duplicate", "stale", "invalid"]
        )
    }

    @Test("Bootstrap ends every retained system activity when the durable queue is empty")
    func bootstrapEndsEveryActivityWhenQueueIsEmpty() {
        let result =
            MemoMarkLiveActivityBootstrapResolver.resolve(
                candidates: [
                    (jobIDString: UUID().uuidString, activity: "valid"),
                    (jobIDString: "not-a-uuid", activity: "invalid")
                ],
                currentJobID: nil
            )

        #expect(result.trackedActivities.isEmpty)
        #expect(
            Set(
                result.activitiesToEnd.map {
                    $0.activity
                }
            ) == ["valid", "invalid"]
        )
    }

    @Test("Queue reconciliation ends every tracked job except the current durable job")
    func queueReconciliationEndsTrackedJobsThatAreNoLongerCurrent() {
        let currentJobID = UUID()
        let staleJobID = UUID()

        #expect(
            MemoMarkLiveActivityQueueReconciliationResolver.jobIDsToEnd(
                trackedJobIDs: [currentJobID, staleJobID],
                currentJobID: currentJobID
            ) == [staleJobID]
        )
        #expect(
            Set(
                MemoMarkLiveActivityQueueReconciliationResolver.jobIDsToEnd(
                    trackedJobIDs: [currentJobID, staleJobID],
                    currentJobID: nil
                )
            ) == [currentJobID, staleJobID]
        )
    }

    @Test("Request failures retry transient errors and suppress only the invalid scope")
    func requestFailurePolicyScopesSuppression() {
        #expect(
            MemoMarkLiveActivityRequestFailurePolicy.disposition(
                for: .temporarilyUnavailable
            ) == .retryAfter(15)
        )
        #expect(
            MemoMarkLiveActivityRequestFailurePolicy.disposition(
                for: .invalidRequest
            ) == .suppressJob
        )
        #expect(
            MemoMarkLiveActivityRequestFailurePolicy.disposition(
                for: .serviceUnavailable
            ) == .disableRequestsForRun
        )
    }

    @Test("Transient terminal request failure remains scheduled until its delayed retry is consumed")
    func transientTerminalFailureRemainsScheduledUntilRetry() {
        let jobID = UUID()
        var registry =
            MemoMarkLiveActivityRequestRetryRegistry<String>()

        let token = registry.schedule(
            payload: "terminal",
            for: jobID
        )

        #expect(registry.hasScheduledRetry(for: jobID))
        #expect(
            registry.consumeRetry(
                for: jobID,
                token: token,
                currentPayload: "terminal"
            ) == "terminal"
        )
        #expect(!registry.hasScheduledRetry(for: jobID))
    }

    @Test("Retry is discarded when its payload is no longer current")
    func retryRequiresCurrentPayload() {
        let jobID = UUID()
        var registry =
            MemoMarkLiveActivityRequestRetryRegistry<String>()
        let token = registry.schedule(
            payload: "old",
            for: jobID
        )

        #expect(
            registry.consumeRetry(
                for: jobID,
                token: token,
                currentPayload: "new"
            ) == nil
        )
        #expect(!registry.hasScheduledRetry(for: jobID))
    }

    @Test("Pending retry adopts the latest payload for the same current job")
    func pendingRetryAdoptsLatestCurrentPayload() {
        let jobID = UUID()
        var registry =
            MemoMarkLiveActivityRequestRetryRegistry<String>()
        let token = registry.schedule(
            payload: "old",
            for: jobID
        )

        registry.updateScheduledPayload(
            "latest",
            for: jobID
        )

        #expect(
            registry.consumeRetry(
                for: jobID,
                token: token,
                currentPayload: "latest"
            ) == "latest"
        )
    }

    @Test("Job switching cancels stale retries and retains only the current job")
    func jobSwitchCancelsStaleRetries() {
        let previousJobID = UUID()
        let currentJobID = UUID()
        var registry =
            MemoMarkLiveActivityRequestRetryRegistry<String>()
        _ = registry.schedule(
            payload: "previous",
            for: previousJobID
        )
        _ = registry.schedule(
            payload: "current",
            for: currentJobID
        )

        #expect(
            registry.cancelAll(except: currentJobID)
                == Set([previousJobID])
        )
        #expect(!registry.hasScheduledRetry(for: previousJobID))
        #expect(registry.hasScheduledRetry(for: currentJobID))
    }

    @Test("Successful request or activity end removes its pending retry")
    func successOrEndRemovesPendingRetry() {
        let successfulJobID = UUID()
        let endedJobID = UUID()
        var registry =
            MemoMarkLiveActivityRequestRetryRegistry<String>()
        _ = registry.schedule(
            payload: "success",
            for: successfulJobID
        )
        _ = registry.schedule(
            payload: "ended",
            for: endedJobID
        )

        let didCancelSuccessfulJob = registry.cancel(
            for: successfulJobID
        )
        let didCancelEndedJob = registry.cancel(
            for: endedJobID
        )

        #expect(didCancelSuccessfulJob)
        #expect(didCancelEndedJob)
        #expect(!registry.hasScheduledRetry(for: successfulJobID))
        #expect(!registry.hasScheduledRetry(for: endedJobID))
    }
}
#endif
