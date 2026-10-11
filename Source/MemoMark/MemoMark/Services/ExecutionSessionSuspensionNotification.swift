import Foundation

nonisolated enum ExecutionSessionStatusNotificationIdentifier {
    static func value(for id: UUID) -> String { "photomemo.session.\(id.uuidString).status" }
}

/// A read-only attention projection. Paused work leaves final markers untouched;
/// terminal failure permits acknowledgement only after result delivery succeeds.
/// Neither outcome changes save receipts.
struct ExecutionSessionSuspensionNotification: Equatable {
    let identifier: String
    let title: String
    let body: String
    let completedCount: Int
    let unfinishedCount: Int
    let jobIDs: [UUID]
    var isFinalResult: Bool = false

    /// Failure can precede durable job admission. Never invent a save receipt.
    @MainActor static func makeFailure(id: UUID, jobs: [BatchJob], pendingItemCount: Int?,
                                       language: MemoMarkLanguage) -> Self? {
        if pendingItemCount == 0,
           let suspended = make(id: id, jobs: jobs, language: language) { return suspended }
        let members = jobs.filter { ($0.executionSessionID ?? $0.id) == id && $0.historyDeletedAt == nil }
        let tasks = members.flatMap(\.tasks)
        let saved = Set(tasks.compactMap { task -> String? in
            guard task.phase == .completed, let asset = task.savedAssetIdentifier, !asset.isEmpty else { return nil }
            return asset
        }).count
        let unfinished = members.reduce(0) { $0 + $1.deliverySummary.needsAttentionCount } + max(0, pendingItemCount ?? 0)
        guard unfinished > 0 || pendingItemCount == nil else { return nil }
        let isFinal = pendingItemCount == 0 && !tasks.isEmpty && tasks.allSatisfy { $0.phase.isTerminal }
        if isFinal {
            guard members.contains(where: { $0.finalNotificationSentAt == nil }) else { return nil }
            return Self(identifier: ExecutionSessionStatusNotificationIdentifier.value(for: id),
                title: BatchNotificationMessageFormatter.finishedTitle(completedCount: saved,
                    needsAttentionCount: unfinished, finishedAt: Date(), language: language),
                body: BatchNotificationMessageFormatter.finishedMessage(completedCount: saved,
                    needsAttentionCount: unfinished, totalCount: saved + unfinished,
                    savedAlbumName: nil, language: language),
                completedCount: saved, unfinishedCount: unfinished, jobIDs: members.map(\.id), isFinalResult: true)
        }
        if pendingItemCount == nil {
            return Self(identifier: ExecutionSessionStatusNotificationIdentifier.value(for: id),
                title: language.localized(key: "notification.continued.suspended.title", fallback: "MemoMark processing is paused"),
                body: language.localized(key: "notification.continued.unconfirmed.body",
                    fallback: "The processing status of this share could not be confirmed. Open MemoMark for details."),
                completedCount: saved, unfinishedCount: unfinished, jobIDs: members.map(\.id))
        }
        return Self(identifier: ExecutionSessionStatusNotificationIdentifier.value(for: id),
            title: language.localized(key: "notification.continued.suspended.title", fallback: "MemoMark processing is paused"),
            body: String(format: language.localized(key: "notification.continued.suspended.body",
                fallback: "Confirmed photo saves: %d. Unfinished items: %d. Open MemoMark to resume or cancel processing."),
                locale: language.locale, saved, unfinished),
            completedCount: saved, unfinishedCount: unfinished, jobIDs: members.map(\.id))
    }

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
