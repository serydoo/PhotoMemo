import Foundation

nonisolated enum ExecutionSessionStatusNotificationIdentifier {
    static func value(for id: UUID) -> String { "photomemo.session.\(id.uuidString).status" }
}

/// A stopped owner is not a completed delivery. This projection never
/// acknowledges final notification markers or changes save receipts.
struct ExecutionSessionSuspensionNotification: Equatable {
    let identifier: String
    let title: String
    let body: String
    let completedCount: Int
    let unfinishedCount: Int
    let jobIDs: [UUID]

    @MainActor static func make(id: UUID, jobs: [BatchJob], language: MemoMarkLanguage) -> Self? {
        let members = jobs.filter { ($0.executionSessionID ?? $0.id) == id && $0.historyDeletedAt == nil }
        let tasks = members.flatMap(\.tasks)
        guard members.contains(where: { $0.executionSuspendedAt != nil }),
              tasks.contains(where: { !$0.phase.isTerminal }) else { return nil }
        let saved = Set(tasks.compactMap { task -> String? in
            guard task.phase == .completed, let id = task.savedAssetIdentifier, !id.isEmpty else { return nil }
            return id
        }).count
        let unfinished = members.reduce(0) { $0 + $1.deliverySummary.needsAttentionCount }
        guard unfinished > 0 else { return nil }
        let title = language.localized(key: "notification.continued.suspended.title", fallback: "MemoMark processing is paused")
        let body = String(format: language.localized(key: "notification.continued.suspended.body",
            fallback: "Confirmed photo saves: %d. Unfinished items: %d. Open MemoMark to resume or cancel processing."),
            locale: language.locale, saved, unfinished)
        return Self(identifier: ExecutionSessionStatusNotificationIdentifier.value(for: id), title: title,
            body: body, completedCount: saved, unfinishedCount: unfinished, jobIDs: members.map(\.id))
    }
}
