import Foundation
import Testing
@testable import MemoMark

@Suite("ContinuedProcessingMessageFormatter")
struct ContinuedProcessingMessageFormatterTests {
    @Test("Accepted intake awaiting admission prevents premature system completion")
    @MainActor func acceptedIntakePreventsCompletion() {
        let job = makeJob(phase: .completed)
        let session = ExecutionSession(id: job.id, jobs: [job], pendingIntakeTaskCount: 3)
        #expect(session.totalCount == 4)
        #expect(session.pendingCount == 3)
        #expect(session.completedProgressUnits == 100)
        #expect(session.totalProgressUnits == 400)
        let message = ContinuedProcessingMessageFormatter.message(for: session, language: .english)
        #expect(message.title == "MemoMark is processing photos")
        #expect(message.subtitle.contains("1/4"))
        #expect(!message.subtitle.contains("processing is complete"))
    }

    @Test("Live Photo work keeps its actual phase visible in every supported language", arguments: MemoMarkLanguage.allCases)
    @MainActor func livePhotoPhase(language: MemoMarkLanguage) {
        let job = makeJob(phase: .exporting)
        let session = ExecutionSession(id: job.id, jobs: [job])
        let message = ContinuedProcessingMessageFormatter.message(for: session, language: language)
        #expect(message.subtitle.contains("66%"))
        #expect(message.subtitle.contains("0/1"))
        #expect(message.subtitle.contains(BatchTaskProgressStage.renderingLivePhoto.localizedStatusMessage(for: language)))
        #expect(!message.title.contains("notification.continued"))
    }

    @Test("Terminal completion replaces the processing phase, while an empty session stays preparing")
    @MainActor func completionAndEmpty() {
        let job = makeJob(phase: .completed)
        let completed = ContinuedProcessingMessageFormatter.message(
            for: ExecutionSession(id: job.id, jobs: [job]), language: .english)
        let empty = ContinuedProcessingMessageFormatter.message(
            for: ExecutionSession(id: UUID(), jobs: []), language: .english)
        #expect(completed.title == "MemoMark photos are ready")
        #expect(completed.subtitle == "Photo processing is complete.")
        #expect(empty.title != completed.title)
        #expect(empty.subtitle.contains("0%"))
        #expect(empty.subtitle.contains("Preparing photos"))
    }

    @MainActor private func makeJob(phase: BatchTaskPhase) -> BatchJob {
        BatchJob(title: "QA", configuration: SettingsService().buildBatchConfigurationSnapshot(),
            tasks: [BatchTask(sourceURL: URL(fileURLWithPath: "/tmp/live.jpg"), phase: phase,
                progress: BatchTaskProgress(currentUnit: 4, totalUnits: 6, stage: .renderingLivePhoto))])
    }
}
