import Foundation

/// Freezes the Share request's admission capacity from one durable commerce
/// snapshot. The Share Extension and its preview may read current state at
/// different times, but a submission must make one decision before it begins
/// copying provider files into the shared container.
nonisolated struct ShareIntakeCapacityPolicy:
    Sendable {

    func maximumSupportedPhotoCount(
        for snapshot: MemoMarkCommerceSnapshot
    ) -> Int {
        guard !snapshot.isPlus else {
            return min(
                snapshot.batchLimit,
                snapshot.remainingRecords ?? snapshot.batchLimit
            )
        }

        // Defensive boundary for a stale shared snapshot. Production and
        // sandbox free users must never inherit the Plus batch limit; Xcode
        // QA remains intentionally unlimited within its own environment.
        let batchLimit = snapshot.environment == .xcode
            ? snapshot.batchLimit
            : MemoMarkCommercePolicy.freeBatchLimit
        let totalAllowance = snapshot.totalAllowance
            ?? MemoMarkCommercePolicy.baseFreeAllowance
        return min(
            batchLimit,
            max(
                totalAllowance - max(snapshot.successfulRecordCount, 0),
                0
            )
        )
    }
}
