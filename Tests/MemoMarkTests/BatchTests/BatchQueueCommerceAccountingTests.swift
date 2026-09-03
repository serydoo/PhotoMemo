import Foundation
import Testing
@testable import MemoMark

@Suite("Batch queue commerce accounting")
struct BatchQueueCommerceAccountingTests {

    @Test("A newly completed free record advances the durable commerce snapshot once")
    @MainActor
    func completedRecordAdvancesSnapshotOnce() throws {
        let suiteName =
            "MemoMark.BatchQueueCommerceAccountingTests.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let accounting = BatchQueueCommerceAccounting(
            persistence: MemoMarkCommercePersistence(
                defaults: defaults
            )
        )
        let task = completedTask()
        let snapshot = freeSnapshot()

        let firstResult = accounting.recordSuccessfulSave(
            for: task,
            current: snapshot
        )
        let updatedSnapshot = try #require(firstResult.updatedSnapshot)
        #expect(updatedSnapshot.successfulRecordCount == 1)

        let duplicateResult = accounting.recordSuccessfulSave(
            for: task,
            current: updatedSnapshot
        )
        #expect(duplicateResult.updatedSnapshot == nil)
        #expect(!duplicateResult.requiresRecovery)
    }

    @Test("Retry admission reserves incomplete work before offering a free retry")
    func retryAdmissionReservesIncompleteWork() {
        let accounting = BatchQueueCommerceAccounting(
            persistence: MemoMarkCommercePersistence(
                defaults: .standard
            )
        )
        let failedTask = BatchTask(
            sourceURL: URL(fileURLWithPath: "/tmp/retry-source.jpg"),
            phase: .failed,
            failure: BatchTaskFailure(
                phase: .exporting,
                message: "Retry",
                classification: .processingFailure,
                canRetry: true
            )
        )
        let queuedTask = BatchTask(
            sourceURL: URL(fileURLWithPath: "/tmp/queued-source.jpg"),
            phase: .queued
        )
        let job = BatchJob(
            title: "Retry",
            launchSource: .inAppPreview,
            configuration: BatchConfigurationSnapshot(
                template: .classicWhite,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            ),
            tasks: [failedTask]
        )
        let otherJob = BatchJob(
            title: "Queued",
            launchSource: .inAppPreview,
            configuration: job.configuration,
            tasks: [queuedTask]
        )
        let snapshot = MemoMarkCommerceSnapshot(
            environment: .production,
            accessSource: .free,
            successfulRecordCount: 199,
            totalAllowance: 200,
            batchLimit: 20,
            firstRecorderDate: nil,
            updatedAt: Date(timeIntervalSince1970: 1)
        )

        let decision = accounting.retryAdmission(
            for: job,
            among: [job, otherJob],
            current: snapshot
        )

        #expect(decision.retryableTaskCount == 1)
        #expect(decision.maximumAdmissionCount == 0)
    }

    @Test("A single Xcode QA completion keeps the legacy finite free projection")
    @MainActor
    func xcodeCompletionKeepsLegacyFreeProjection() throws {
        let suiteName =
            "MemoMark.BatchQueueCommerceAccountingTests.Xcode.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let accounting = BatchQueueCommerceAccounting(
            persistence: MemoMarkCommercePersistence(
                defaults: defaults
            )
        )
        let snapshot = MemoMarkCommerceSnapshot(
            environment: .xcode,
            accessSource: .free,
            successfulRecordCount: 0,
            totalAllowance: 200,
            batchLimit: 20,
            firstRecorderDate: nil,
            updatedAt: Date(timeIntervalSince1970: 1)
        )

        let result = accounting.recordSuccessfulSave(
            for: completedTask(),
            current: snapshot
        )
        let updatedSnapshot = try #require(result.updatedSnapshot)
        #expect(updatedSnapshot.totalAllowance == 200)
        #expect(updatedSnapshot.batchLimit == 20)
    }

    private func completedTask() -> BatchTask {
        var task = BatchTask(
            sourceURL: URL(fileURLWithPath: "/tmp/completed-source.jpg"),
            phase: .completed
        )
        task.savedAssetIdentifier = "asset-completed"
        return task
    }

    private func freeSnapshot() -> MemoMarkCommerceSnapshot {
        MemoMarkCommerceSnapshot(
            environment: .production,
            accessSource: .free,
            successfulRecordCount: 0,
            totalAllowance: 200,
            batchLimit: 20,
            firstRecorderDate: nil,
            updatedAt: Date(timeIntervalSince1970: 1)
        )
    }
}
