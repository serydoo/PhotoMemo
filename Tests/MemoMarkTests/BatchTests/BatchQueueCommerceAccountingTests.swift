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

    @Test("repeated shares of one intent consume one free record")
    @MainActor func repeatedIntentCountsOnce() throws {
        let suite = "IntentAccounting-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let accounting = BatchQueueCommerceAccounting(persistence: MemoMarkCommercePersistence(defaults: defaults))
        var first = completedTask()
        var second = completedTask()
        first.processingIdentity = ProcessingIdentity(sourceDigest: "same", semanticsDigest: "same")
        second.processingIdentity = first.processingIdentity
        let result = accounting.recordSuccessfulSave(for: first, current: freeSnapshot())
        let updated = try #require(result.updatedSnapshot)
        #expect(updated.successfulRecordCount == 1)
        #expect(accounting.recordSuccessfulSave(for: second, current: updated).updatedSnapshot == nil)
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

    @Test("Expired subscription admission uses free policy instead of stale Plus fields")
    func expiredSubscriptionUsesFreeAdmission() {
        let suiteName =
            "MemoMark.BatchQueueCommerceAccountingTests.Expired.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let accounting = BatchQueueCommerceAccounting(
            persistence: MemoMarkCommercePersistence(defaults: defaults)
        )
        let snapshot = MemoMarkCommerceSnapshot(
            environment: .production,
            accessSource: .plusSubscription,
            successfulRecordCount: 199,
            totalAllowance: nil,
            batchLimit: 40,
            firstRecorderDate: nil,
            validThrough: Date(timeIntervalSince1970: 1),
            updatedAt: .distantPast
        )

        #expect(
            accounting.admissionCapacity(
                among: [],
                current: snapshot
            ) == 1
        )
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

extension BatchQueueCommerceAccountingTests {
    @Test("startup reconciliation must preserve identity accounting count")
    @MainActor func identityReconciliationCountsOnce() throws {
        let suite = "MemoMark.AuditAccounting." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let accounting = BatchQueueCommerceAccounting(persistence: MemoMarkCommercePersistence(defaults: defaults))
        var task = completedTask()
        task.processingIdentity = ProcessingIdentity(sourceDigest: "audit-source", semanticsDigest: "audit-output")
        let first = try #require(accounting.recordSuccessfulSave(for: task, current: freeSnapshot()).updatedSnapshot)
        #expect(first.successfulRecordCount == 1)
        let job = BatchJob(title: "Audit", launchSource: .shareExtension,
            configuration: BatchConfigurationSnapshot(template: .classicWhite, badge: nil, anchor: nil,
                shouldWritePhotoDescription: false, photoDescriptionOverride: "", selectedAlbumIdentifier: ""),
            tasks: [task])
        let reconciled = accounting.reconcile(completedJobs: [job], current: first)
        #expect(!reconciled.requiresRecovery)
        let count = reconciled.updatedSnapshot?.successfulRecordCount ?? first.successfulRecordCount
        #expect(count == 1)
    }
}

extension BatchQueueCommerceAccountingTests {
    @Test("Recovery removes only proven legacy aliases without changing unrelated usage")
    @MainActor func recoveryCanonicalizesKnownLegacyAccountingAliases() throws {
        let suite = "AccountingAliasRecovery." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let persistence = MemoMarkCommercePersistence(defaults: defaults)
        let accounting = BatchQueueCommerceAccounting(persistence: persistence)
        var task = completedTask()
        task.processingIdentity = ProcessingIdentity(sourceDigest: "alias-source", semanticsDigest: "alias-output")
        let unrelated = UUID()
        for id in [task.id, task.successfulSaveAccountingID, unrelated] {
            #expect(persistence.recordSuccessfulSave(taskID: id, environment: .production))
        }
        let job = BatchJob(title: "Recovery", launchSource: .shareExtension,
            configuration: BatchConfigurationSnapshot(template: .classicWhite, badge: nil, anchor: nil,
                shouldWritePhotoDescription: false, photoDescriptionOverride: "", selectedAlbumIdentifier: ""), tasks: [task])
        let first = accounting.reconcile(completedJobs: [job], current: freeSnapshot())
        #expect(!first.requiresRecovery)
        #expect(persistence.successfulRecordCount(environment: .production) == 2)
        #expect(persistence.hasRecordedSuccessfulSave(taskID: unrelated, environment: .production))
        _ = accounting.reconcile(completedJobs: [job], current: freeSnapshot())
        #expect(persistence.successfulRecordCount(environment: .production) == 2)
    }
}
