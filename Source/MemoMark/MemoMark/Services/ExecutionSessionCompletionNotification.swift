import Foundation

/// A read-only delivery projection. Save receipts remain on the durable jobs.
struct ExecutionSessionCompletionNotification: Equatable {
    let identifier: String
    let title: String
    let body: String
    let completedCount: Int
    let jobIDs: [UUID]

    @MainActor static func make(id: UUID, jobs: [BatchJob], language: MemoMarkLanguage,
                               pendingIntakeRequestIDs: Set<UUID>? = [],
                               finishedAt: Date = Date()) -> Self? {
        // An accepted Share may still be waiting for this owner's lease.
        // Defer the final summary until durable admission accounts for it.
        // Unreadable intake metadata cannot establish a quiet queue either.
        guard let pendingIntakeRequestIDs,
              pendingIntakeRequestIDs.isSubset(of: Set(jobs.compactMap(\.intakeRequestID))) else { return nil }
        let members = jobs.filter { ($0.executionSessionID ?? $0.id) == id && $0.historyDeletedAt == nil }
        let tasks = members.flatMap(\.tasks)
        guard !tasks.isEmpty, tasks.allSatisfy({ $0.phase == .completed }),
              members.allSatisfy({ $0.deliverySummary.needsAttentionCount == 0 }),
              members.contains(where: { $0.finalNotificationSentAt == nil }) else { return nil }
        let identifiers = tasks.compactMap { task -> String? in
            guard let value = task.savedAssetIdentifier, !value.isEmpty else { return nil }
            return value
        }
        guard identifiers.count == tasks.count else { return nil }
        let count = Set(identifiers).count
        let albums = Set(tasks.compactMap {
            BatchNotificationMessageFormatter.normalizedAlbumName($0.savedAlbumName ?? "")
        })
        let album = albums.count == 1 ? albums.first : nil
        return Self(identifier: ExecutionSessionStatusNotificationIdentifier.value(for: id),
            title: BatchNotificationMessageFormatter.finishedTitle(completedCount: count,
                failedCount: 0, finishedAt: finishedAt, language: language),
            body: BatchNotificationMessageFormatter.finishedMessage(completedCount: count,
                failedCount: 0, totalCount: count, savedAlbumName: album, language: language),
            completedCount: count, jobIDs: members.map(\.id))
    }
}
