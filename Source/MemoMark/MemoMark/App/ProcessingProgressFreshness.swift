import Foundation

nonisolated enum ProcessingProgressFreshness {
    /// Freshness follows actual durable progress, not another UI projection.
    static func staleDate(updatedAt: Date, isTerminal: Bool) -> Date? {
        isTerminal ? nil : updatedAt.addingTimeInterval(300)
    }
}
