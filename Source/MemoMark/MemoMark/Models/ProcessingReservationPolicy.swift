import Foundation

/// Reservations follow the same durable intent used by receipts/accounting.
/// Repeated delivery is not a new allowance; legacy tasks keep their UUID identity.
nonisolated enum ProcessingReservationPolicy {
    static func reservedIDs(in jobs: [BatchJob]) -> Set<UUID> {
        Set(jobs.flatMap(\.tasks).filter { !$0.phase.isTerminal }.map(\.successfulSaveAccountingID))
            .subtracting(completedIDs(in: jobs))
    }

    static func newReservationCount(for job: BatchJob, among jobs: [BatchJob]) -> Int {
        let covered = reservedIDs(in: jobs).union(completedIDs(in: jobs))
        return Set(job.tasks.map(\.successfulSaveAccountingID)).subtracting(covered).count
    }

    private static func completedIDs(in jobs: [BatchJob]) -> Set<UUID> {
        Set(jobs.flatMap(\.tasks).filter { $0.phase == .completed && $0.savedAssetIdentifier != nil }
            .map(\.successfulSaveAccountingID))
    }
}
