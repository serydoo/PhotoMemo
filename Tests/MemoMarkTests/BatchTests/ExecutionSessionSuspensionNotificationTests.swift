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
