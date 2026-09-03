#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Batch task execution events")
struct BatchTaskExecutionEventTests {

    @Test("processing events project the existing task lifecycle fields")
    func processingEventsProjectExistingLifecycleFields() {
        let sourceURL = URL(fileURLWithPath: "/tmp/source.jpg")
        let renderedURL = URL(fileURLWithPath: "/tmp/rendered.jpg")
        let captureDate = Date(timeIntervalSince1970: 100)
        var task = BatchTask(
            sourceURL: sourceURL,
            phase: .queued,
            failure: BatchTaskFailure(
                phase: .queued,
                message: "old failure"
            )
        )

        BatchTaskExecutionEvent.processingStarted(
            progress: BatchTaskProgress(
                currentUnit: 1,
                totalUnits: 5,
                stage: .readingOriginal
            )
        )
        .apply(to: &task)
        #expect(task.phase == .importing)
        #expect(task.failure == nil)

        BatchTaskExecutionEvent.metadataLoaded(
            captureDate: captureDate,
            progress: BatchTaskProgress(
                currentUnit: 2,
                totalUnits: 5,
                stage: .metadataReady
            )
        )
        .apply(to: &task)
        #expect(task.phase == .metadataReady)
        #expect(task.captureDate == captureDate)

        BatchTaskExecutionEvent.photoLibrarySaveStarted(
            renderedFileURL: renderedURL,
            progress: BatchTaskProgress(
                currentUnit: 5,
                totalUnits: 5,
                stage: .savingToPhotoLibrary
            )
        )
        .apply(to: &task)
        #expect(task.phase == .savingToPhotoLibrary)
        #expect(task.renderedFileURL == renderedURL)
    }

    @Test("terminal events clear transient output and retain durable result fields")
    func terminalEventsClearTransientOutputAndRetainDurableResultFields() {
        var task = BatchTask(
            sourceURL: URL(fileURLWithPath: "/tmp/source.jpg"),
            phase: .savingToPhotoLibrary,
            renderedFileURL:
                URL(fileURLWithPath: "/tmp/rendered.jpg")
        )
        let attachmentURL =
            URL(fileURLWithPath: "/tmp/attachment.jpg")

        BatchTaskExecutionEvent.completed(
            albumTitle: "Family",
            assetIdentifier: "asset-1",
            notificationAttachmentURL: attachmentURL,
            progress: BatchTaskProgress(
                currentUnit: 5,
                totalUnits: 5,
                stage: .completed
            )
        )
        .apply(to: &task)

        #expect(task.phase == .completed)
        #expect(task.renderedFileURL == nil)
        #expect(task.savedAlbumName == "Family")
        #expect(task.savedAssetIdentifier == "asset-1")
        #expect(task.notificationAttachmentURL == attachmentURL)
    }

    @Test("failure and readback events retain the established recovery semantics")
    func failureAndReadbackEventsRetainRecoverySemantics() {
        var task = BatchTask(
            sourceURL: URL(fileURLWithPath: "/tmp/source.jpg"),
            phase: .savingToPhotoLibrary,
            renderedFileURL:
                URL(fileURLWithPath: "/tmp/rendered.jpg")
        )

        BatchTaskExecutionEvent.photoLibraryReadbackPending
            .apply(to: &task)
        #expect(task.phase == .savingToPhotoLibrary)
        #expect(task.failure == nil)
        #expect(task.progress.stage == .confirmingPhotoLibrarySave)

        let failure = BatchTaskFailure(
            phase: .savingToPhotoLibrary,
            message: "failed",
            canRetry: true
        )
        BatchTaskExecutionEvent.failed(failure)
            .apply(to: &task)
        #expect(task.phase == .failed)
        #expect(task.failure == failure)
        #expect(task.progress.stage == .failed)

        BatchTaskExecutionEvent.retryDisabled
            .apply(to: &task)
        #expect(task.failure?.canRetry == false)
    }

    @Test("queue authority rejects an out-of-order execution event")
    @MainActor
    func queueAuthorityRejectsOutOfOrderEvent() async {
        let suiteName =
            "BatchTaskExecutionEventTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }
        let store = BatchQueueStore(
            defaults: defaults,
            automaticallyStartsProcessing: false
        )
        let job = await store.enqueue(
            urls: [
                URL(fileURLWithPath: "/tmp/source.jpg")
            ]
        )!
        let reference = BatchTaskReference(
            jobID: job.id,
            taskID: job.tasks[0].id
        )

        let accepted = await store.applyExecutionEvent(
            .metadataLoaded(
                captureDate: nil,
                progress: BatchTaskProgress(
                    currentUnit: 2,
                    totalUnits: 5,
                    stage: .metadataReady
                )
            ),
            at: reference
        )

        #expect(!accepted)
        #expect(store.currentTask(at: reference)?.phase == .queued)
    }
}
#endif
