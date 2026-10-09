import Foundation
import Testing
@testable import MemoMark

@Suite("ExecutionSessionCompletionNotification")
struct ExecutionSessionCompletionNotificationTests {
    @Test("Repeated inputs report distinct saved assets and reuse one session notification")
    @MainActor func distinctOutputReceiptCount() throws {
        let sessionID = UUID()
        var first = job(phase: .completed, asset: "A")
        first.executionSessionID = sessionID
        var second = job(phase: .completed, asset: "A")
        second.executionSessionID = sessionID
        second.tasks.append(BatchTask(sourceURL: URL(fileURLWithPath: "/tmp/b.jpg"),
            phase: .completed, savedAlbumName: "QA", savedAssetIdentifier: "B"))
        let initial = try #require(ExecutionSessionCompletionNotification.make(id: sessionID, jobs: [first], language: .english))
        let combined = try #require(ExecutionSessionCompletionNotification.make(id: sessionID, jobs: [first, second], language: .english))
        #expect(initial.identifier == combined.identifier)
        #expect(combined.completedCount == 2)
        #expect(combined.jobIDs.count == 2)
        #expect(combined.body.contains("QA"))
    }

    @Test("Pending, cancelled, missing receipts and already acknowledged sessions never claim successful output")
    @MainActor func noPrematureCompletion() {
        let id = UUID()
        for phase in [BatchTaskPhase.queued, .savingToPhotoLibrary, .cancelled, .failed] {
            var member = job(phase: phase, asset: "A")
            member.executionSessionID = id
            #expect(ExecutionSessionCompletionNotification.make(id: id, jobs: [member], language: .english) == nil)
        }
        var missing = job(phase: .completed, asset: nil)
        missing.executionSessionID = id
        #expect(ExecutionSessionCompletionNotification.make(id: id, jobs: [missing], language: .english) == nil)
        missing.tasks[0].savedAssetIdentifier = "A"
        missing.finalNotificationSentAt = Date()
        #expect(ExecutionSessionCompletionNotification.make(id: id, jobs: [missing], language: .english) == nil)
    }

    @Test("An intake failure cannot be reported as complete success")
    @MainActor func intakeFailurePreventsSuccess() {
        var member = job(phase: .completed, asset: "A")
        member.intakeSummary = ExternalPhotoImportSummary(importedCount: 1, skippedCount: 0, failedCount: 1)
        #expect(ExecutionSessionCompletionNotification.make(id: member.id, jobs: [member], language: .english) == nil)
    }

    @Test("An accepted Share awaiting admission defers the final session notification")
    @MainActor func pendingIntakeDefersFinalSummary() throws {
        let session = UUID()
        let nextRequest = UUID()
        var first = job(phase: .completed, asset: "A")
        first.executionSessionID = session
        first.intakeRequestID = UUID()
        #expect(ExecutionSessionCompletionNotification.make(id: session, jobs: [first], language: .english,
            pendingIntakeRequestIDs: [nextRequest]) == nil)
        #expect(ExecutionSessionCompletionNotification.make(id: session, jobs: [first], language: .english,
            pendingIntakeRequestIDs: nil) == nil)
        #expect(ExecutionSessionCompletionNotification.make(id: session, jobs: [first], language: .english,
            pendingIntakeRequestIDs: [try #require(first.intakeRequestID)]) != nil)
        var next = job(phase: .completed, asset: "B")
        next.executionSessionID = session
        next.intakeRequestID = nextRequest
        let message = try #require(ExecutionSessionCompletionNotification.make(id: session,
            jobs: [first, next], language: .english, pendingIntakeRequestIDs: [nextRequest]))
        #expect(message.completedCount == 2)
        #expect(first.finalNotificationSentAt == nil)
    }

    @Test("Completion uses the requested interface language", arguments: MemoMarkLanguage.allCases)
    @MainActor func localizedCompletion(language: MemoMarkLanguage) throws {
        let member = job(phase: .completed, asset: "A")
        let message = try #require(ExecutionSessionCompletionNotification.make(id: member.id, jobs: [member], language: language))
        #expect(message.body == BatchNotificationMessageFormatter.finishedMessage(
            completedCount: 1, failedCount: 0, totalCount: 1, savedAlbumName: "QA", language: language))
        #expect(!message.title.contains("notification.batch"))
    }

    @MainActor private func job(phase: BatchTaskPhase, asset: String?) -> BatchJob {
        BatchJob(title: "QA", launchSource: .shareExtension,
            configuration: SettingsService().buildBatchConfigurationSnapshot(),
            tasks: [BatchTask(sourceURL: URL(fileURLWithPath: "/tmp/a.jpg"), phase: phase,
                savedAlbumName: "QA", savedAssetIdentifier: asset)])
    }
}
