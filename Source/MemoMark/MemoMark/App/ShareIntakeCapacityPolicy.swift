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
        min(
            snapshot.batchLimit,
            snapshot.remainingRecords
                ?? snapshot.batchLimit
        )
    }
}
