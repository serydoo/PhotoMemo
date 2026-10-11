import Foundation
import Testing
@testable import MemoMark

@Suite("Suspended session native notification")
@MainActor struct ExecutionSessionSuspensionNotificationTests {
    @Test("A hold reports confirmed distinct saves and unfinished items in each interface language", arguments: MemoMarkLanguage.allCases)
    func confirmedResults(language: MemoMarkLanguage) throws {
        var job = member()
        job.executionSuspendedAt = Date()
        let message = try #require(ExecutionSessionSuspensionNotification.make(id: job.id, jobs: [job], language: language))
        #expect(message.completedCount == 1)
        #expect(message.unfinishedCount == 1)
        #expect(message.identifier == "photomemo.session.\(job.id.uuidString).status")
        #expect(!message.title.contains("notification."))
        #expect(!message.body.contains("notification."))
    }

    @Test("Running, completed and deleted sessions never emit a suspension notice")
    func noStaleNotice() {
        var job = member()
        #expect(ExecutionSessionSuspensionNotification.make(id: job.id, jobs: [job], language: .english) == nil)
        job.executionSuspendedAt = Date()
        job.historyDeletedAt = Date()
        #expect(ExecutionSessionSuspensionNotification.make(id: job.id, jobs: [job], language: .english) == nil)
        job.historyDeletedAt = nil
        job.tasks[2].phase = .completed
        job.tasks[2].savedAssetIdentifier = "B"
        #expect(ExecutionSessionSuspensionNotification.make(id: job.id, jobs: [job], language: .english) == nil)
    }

    private func member() -> BatchJob {
        BatchJob(title: "QA", launchSource: .shareExtension, configuration: SettingsService().buildBatchConfigurationSnapshot(),
            tasks: [.init(sourceURL: URL(fileURLWithPath: "/tmp/a.jpg"), phase: .completed, savedAssetIdentifier: "A"),
                    .init(sourceURL: URL(fileURLWithPath: "/tmp/a-copy.jpg"), phase: .completed, savedAssetIdentifier: "A"),
                    .init(sourceURL: URL(fileURLWithPath: "/tmp/b.jpg"), phase: .queued)])
    }
}

@MainActor extension ExecutionSessionSuspensionNotificationTests {
    @Test("Failure before admission and terminal failures both have an actionable result", arguments: MemoMarkLanguage.allCases)
    func failureFallback(language: MemoMarkLanguage) throws {
        let id = UUID()
        let unknown = try #require(ExecutionSessionSuspensionNotification.makeFailure(
            id: id, jobs: [], pendingItemCount: nil, language: language))
        #expect(unknown.completedCount == 0)
        #expect(unknown.unfinishedCount == 0)
        #expect(!unknown.isFinalResult)
        #expect(!unknown.body.contains("notification."))
        let admission = try #require(ExecutionSessionSuspensionNotification.makeFailure(
            id: id, jobs: [], pendingItemCount: 2, language: language))
        #expect(admission.completedCount == 0)
        #expect(admission.unfinishedCount == 2)
        #expect(admission.jobIDs.isEmpty)
        #expect(!admission.isFinalResult)
        var job = member()
        job.executionSuspendedAt = Date()
        let joined = try #require(ExecutionSessionSuspensionNotification.makeFailure(
            id: job.id, jobs: [job], pendingItemCount: 2, language: language))
        #expect(joined.unfinishedCount == 3)
        #expect(!joined.isFinalResult)
        job.tasks[2].phase = .failed
        let failed = try #require(ExecutionSessionSuspensionNotification.makeFailure(
            id: job.id, jobs: [job], pendingItemCount: 0, language: language))
        #expect(failed.completedCount == 1)
        #expect(failed.unfinishedCount == 1)
        #expect(failed.isFinalResult)
        #expect(!failed.body.contains("notification."))
        let unreadablePending = try #require(ExecutionSessionSuspensionNotification.makeFailure(
            id: job.id, jobs: [job], pendingItemCount: nil, language: language))
        #expect(unreadablePending.completedCount == 1)
        #expect(unreadablePending.unfinishedCount == 1)
        #expect(!unreadablePending.isFinalResult)
        #expect(unreadablePending.body == unknown.body)
    }
}
