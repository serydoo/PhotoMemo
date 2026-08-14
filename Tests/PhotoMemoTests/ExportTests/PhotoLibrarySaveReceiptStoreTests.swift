import Foundation
import Testing
@testable import PhotoMemo

@Suite("Photo library save receipts")
struct PhotoLibrarySaveReceiptStoreTests {

    @Test("visible recorded asset is reused")
    func visibleRecordedAssetIsReused() {
        let policy =
            PhotoLibrarySaveReceiptReconciliationPolicy()

        #expect(
            policy.decision(
                assetExists: true,
                recordedAt: nil
            ) == .reuseAsset
        )
    }

    @Test("recent receipt with missing asset awaits PhotoKit visibility")
    func recentMissingAssetAwaitsVisibility() {
        let policy =
            PhotoLibrarySaveReceiptReconciliationPolicy()

        #expect(
            policy.decision(
                assetExists: false,
                recordedAt:
                    Date(timeIntervalSince1970: 80)
            ) == .awaitVisibility
        )
    }

    @Test("stale missing receipt remains ambiguous without proof of non-commit")
    func staleMissingAssetAwaitsRecovery() {
        let policy =
            PhotoLibrarySaveReceiptReconciliationPolicy()

        #expect(
            policy.decision(
                assetExists: false,
                recordedAt:
                    Date(timeIntervalSince1970: 70)
            ) == .awaitVisibility
        )
    }

    @Test("missing receipt timestamp preserves an ambiguous external outcome")
    func missingReceiptTimestampAwaitsVisibility() {
        let policy =
            PhotoLibrarySaveReceiptReconciliationPolicy()

        #expect(
            policy.decision(
                assetExists: false,
                recordedAt: nil
            ) == .awaitVisibility
        )
    }

    @Test("save gate serializes suspending PhotoKit operations")
    func saveGateSerializesSuspendingOperations() async {
        let gate = PhotoLibrarySaveGate()
        let probe = PhotoLibrarySaveGateProbe()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 2 {
                group.addTask {
                    try? await gate.run {
                        await probe.enter()
                        try? await Task.sleep(
                            nanoseconds: 50_000_000
                        )
                        await probe.leave()
                    }
                }
            }
        }

        #expect(await probe.maximumConcurrentOperations == 1)
    }

    @Test("cancelled save-gate waiter never starts its PhotoKit operation")
    func cancelledSaveGateWaiterDoesNotRun() async {
        let gate = PhotoLibrarySaveGate()
        let blocker = PhotoLibrarySaveGateBlocker()

        let firstTask = Task<Void, Error> {
            try await gate.run {
                await blocker.holdFirstOperation()
            }
        }
        await blocker.waitUntilFirstOperationStarts()

        let cancelledTask = Task<Void, Error> {
            try await gate.run {
                await blocker.recordSecondOperation()
            }
        }
        await Task.yield()
        cancelledTask.cancel()
        await blocker.releaseFirstOperation()

        do {
            try await firstTask.value
        } catch {
            Issue.record(
                "The active save operation should complete: \(error)"
            )
        }

        do {
            try await cancelledTask.value
            Issue.record(
                "A cancelled save-gate waiter should throw CancellationError."
            )
        } catch is CancellationError {
            // Expected.
        } catch {
            Issue.record(
                "Expected CancellationError, received \(error)."
            )
        }

        #expect(await blocker.secondOperationCount == 0)
    }

    @Test("save receipts persist by normalized task identity")
    func receiptsRoundTripAcrossStoreInstances() throws {
        let suiteName =
            "PhotoLibrarySaveReceiptStoreTests.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store =
            PhotoLibrarySaveReceiptStore(
                defaults: defaults
            )
        store.record(
            assetIdentifier: "asset-123",
            for: " task/123 "
        )

        let receiptKeys = defaults
            .dictionaryRepresentation()
            .keys
            .filter {
                $0.hasPrefix(
                    "photomemo.photoLibrarySaveReceipt.v1.task-123"
                )
            }
        #expect(receiptKeys.count == 1)
        #expect(
            defaults.data(
                forKey:
                    "photomemo.photoLibrarySaveReceipt.v1.task-123"
            ) != nil
        )

        let reloaded =
            PhotoLibrarySaveReceiptStore(
                defaults: defaults
            )
        #expect(
            reloaded.assetIdentifier(
                for: "task/123"
            ) == "asset-123"
        )

        reloaded.removeReceipt(for: "task/123")
        #expect(
            store.assetIdentifier(
                for: "task/123"
            ) == nil
        )
    }

    @Test("receipt lifecycle distinguishes submission from commit acknowledgement")
    func receiptLifecycleDistinguishesSubmissionFromCommitAcknowledgement() throws {
        let suiteName =
            "PhotoLibrarySaveReceiptStoreTests.Lifecycle.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = PhotoLibrarySaveReceiptStore(defaults: defaults)
        store.record(
            assetIdentifier: "asset-lifecycle",
            for: "task/lifecycle"
        )

        let submitted = try #require(
            store.receipt(for: "task/lifecycle")
        )
        #expect(
            submitted.phase == .transactionSubmitted
        )
        #expect(
            store.markCommitted(for: "task/lifecycle")
        )

        let committed = try #require(
            store.receipt(for: "task/lifecycle")
        )
        #expect(
            committed.assetIdentifier == "asset-lifecycle"
        )
        #expect(
            committed.phase == .commitAcknowledged
        )
    }

    @Test("already acknowledged receipts remain reusable when acknowledgement storage is unavailable")
    func alreadyAcknowledgedReceiptDoesNotRequireAnotherWrite() throws {
        let suiteName =
            "PhotoLibrarySaveReceiptStoreTests.EnsureCommitted.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = PhotoLibrarySaveReceiptStore(
            defaults: defaults
        )
        #expect(
            store.record(
                assetIdentifier: "asset-committed",
                for: "task/committed"
            )
        )
        #expect(
            store.markCommitted(
                for: "task/committed"
            )
        )

        let failingStore = PhotoLibrarySaveReceiptStore(
            defaults: defaults,
            receiptDataWriter: { _, _, _ in }
        )

        #expect(
            failingStore.ensureCommitted(
                for: "task/committed"
            )
        )
        #expect(
            failingStore.receipt(
                for: "task/committed"
            )?.phase == .commitAcknowledged
        )
    }

    @Test("pre-commit save intent survives restart until an asset receipt replaces it")
    func preCommitSaveIntentSurvivesRestartUntilReceiptReplacesIt() throws {
        let suiteName =
            "PhotoLibrarySaveReceiptStoreTests.Intent.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = PhotoLibrarySaveReceiptStore(defaults: defaults)
        #expect(
            store.recordIntent(for: "task/intent")
        )
        #expect(
            store.hasPendingIntent(for: "task/intent")
        )

        let reloaded = PhotoLibrarySaveReceiptStore(defaults: defaults)
        #expect(
            reloaded.hasPendingIntent(for: "task/intent")
        )
        let intent = try #require(
            reloaded.intent(for: "task/intent")
        )
        #expect(intent.startedAt.timeIntervalSince1970 > 0)
        #expect(
            reloaded.recordIntentAssetIdentifier(
                "asset-after-placeholder",
                for: "task/intent"
            )
        )
        #expect(
            reloaded.pendingAssetIdentifier(
                for: "task/intent"
            ) == "asset-after-placeholder"
        )
        #expect(
            reloaded.record(
                assetIdentifier: "asset-after-intent",
                for: "task/intent"
            )
        )
        #expect(
            !reloaded.hasPendingIntent(for: "task/intent")
        )
        #expect(
            reloaded.assetIdentifier(for: "task/intent")
            == "asset-after-intent"
        )
    }

    @Test("legacy pre-commit intents remain readable without a placeholder")
    func legacyPreCommitIntentRemainsReadable() throws {
        let suiteName =
            "PhotoLibrarySaveReceiptStoreTests.LegacyIntent.(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let legacyData = try JSONEncoder().encode(
            [
                "startedAt": Date(
                    timeIntervalSince1970: 123
                )
            ]
        )
        defaults.set(
            legacyData,
            forKey:
                "photomemo.photoLibrarySaveIntent.v1.task-legacy"
        )

        let store = PhotoLibrarySaveReceiptStore(
            defaults: defaults
        )
        let intent = try #require(
            store.intent(for: "task/legacy")
        )
        #expect(
            intent.startedAt
            == Date(timeIntervalSince1970: 123)
        )
        #expect(intent.assetIdentifier == nil)
        #expect(
            store.hasPendingIntent(for: "task/legacy")
        )
    }

    @Test("pre-commit intent write failure is reported and does not create a false intent")
    func preCommitIntentWriteFailureIsReported() throws {
        let suiteName =
            "PhotoLibrarySaveReceiptStoreTests.IntentFailure.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = PhotoLibrarySaveReceiptStore(
            defaults: defaults,
            receiptDataWriter: { _, _, _ in }
        )

        #expect(
            !store.recordIntent(for: "task/intent-write-failure")
        )
        #expect(
            !store.hasPendingIntent(
                for: "task/intent-write-failure"
            )
        )
    }

    @Test("placeholder identifier can be durably attached to a pending intent")
    func pendingIntentCanRetainPlaceholderIdentifierWhenReceiptWriteFails() throws {
        let suiteName =
            "PhotoLibrarySaveReceiptStoreTests.IntentPlaceholder.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = PhotoLibrarySaveReceiptStore(
            defaults: defaults,
            receiptDataWriter: { data, key, defaults in
                if key.hasPrefix(
                    "photomemo.photoLibrarySaveReceipt.v1"
                ) {
                    return
                }
                defaults.set(data, forKey: key)
            }
        )
        #expect(
            store.recordIntent(
                for: "task/placeholder"
            )
        )
        #expect(
            store.recordIntentAssetIdentifier(
                "asset-placeholder",
                for: "task/placeholder"
            )
        )
        #expect(
            store.pendingAssetIdentifier(
                for: "task/placeholder"
            ) == "asset-placeholder"
        )
        #expect(
            !store.materializePendingIntent(
                for: "task/placeholder"
            )
        )
        #expect(
            store.pendingAssetIdentifier(
                for: "task/placeholder"
            ) == "asset-placeholder"
        )
        #expect(
            store.assetIdentifier(
                for: "task/placeholder"
            ) == nil
        )
    }

    @Test("receipt write failure is reported without losing the submitted receipt")
    func receiptWriteFailurePreservesSubmittedReceipt() throws {
        let suiteName =
            "PhotoLibrarySaveReceiptStoreTests.WriteFailure.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = PhotoLibrarySaveReceiptStore(
            defaults: defaults
        )
        #expect(
            store.record(
                assetIdentifier: "asset-write-failure",
                for: "task/write-failure"
            )
        )
        let submittedData = defaults.data(
            forKey:
                "photomemo.photoLibrarySaveReceipt.v1.task-write-failure"
        )

        let failingStore = PhotoLibrarySaveReceiptStore(
            defaults: defaults,
            receiptDataWriter: { _, _, _ in }
        )

        #expect(
            !failingStore.markCommitted(
                for: "task/write-failure"
            )
        )
        #expect(
            defaults.data(
                forKey:
                    "photomemo.photoLibrarySaveReceipt.v1.task-write-failure"
            ) == submittedData
        )
        #expect(
            failingStore.receipt(
                for: "task/write-failure"
            )?.phase == .transactionSubmitted
        )
    }

    @Test("record reports a write failure instead of silently succeeding")
    func recordReportsWriteFailure() throws {
        let suiteName =
            "PhotoLibrarySaveReceiptStoreTests.RecordFailure.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = PhotoLibrarySaveReceiptStore(
            defaults: defaults,
            receiptDataWriter: { _, _, _ in }
        )

        #expect(
            !store.record(
                assetIdentifier: "asset-record-failure",
                for: "task/record-failure"
            )
        )
        #expect(
            store.receipt(
                for: "task/record-failure"
            ) == nil
        )
    }

    @Test("legacy split receipt remains readable during atomic-value migration")
    func legacySplitReceiptRemainsReadable() throws {
        let suiteName =
            "PhotoLibrarySaveReceiptStoreTests.Legacy.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let storageKey =
            "photomemo.photoLibrarySaveReceipt.v1.legacy-task"
        let recordedAt = Date(timeIntervalSince1970: 100)
        defaults.set("legacy-asset", forKey: storageKey)
        defaults.set(
            recordedAt,
            forKey: storageKey + ".recordedAt"
        )

        let store = PhotoLibrarySaveReceiptStore(
            defaults: defaults
        )

        #expect(
            store.assetIdentifier(for: "legacy-task")
            == "legacy-asset"
        )
        #expect(
            store.recordedAt(for: "legacy-task")
            == recordedAt
        )
        #expect(
            store.receipt(for: "legacy-task")?.phase
            == .transactionSubmitted
        )
    }

    @Test("legacy atomic receipt without phase remains readable")
    func legacyAtomicReceiptWithoutPhaseRemainsReadable() throws {
        let suiteName =
            "PhotoLibrarySaveReceiptStoreTests.LegacyAtomic.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let storageKey =
            "photomemo.photoLibrarySaveReceipt.v1.legacy-atomic"
        struct LegacyAtomicReceipt: Codable {
            let assetIdentifier: String
            let recordedAt: Date
        }
        let legacyData = try JSONEncoder().encode(
            LegacyAtomicReceipt(
                assetIdentifier: "legacy-atomic-asset",
                recordedAt: Date(timeIntervalSince1970: 200)
            )
        )
        defaults.set(legacyData, forKey: storageKey)

        let store = PhotoLibrarySaveReceiptStore(
            defaults: defaults
        )

        #expect(
            store.assetIdentifier(for: "legacy-atomic")
            == "legacy-atomic-asset"
        )
        #expect(
            store.receipt(for: "legacy-atomic")?.phase
            == .transactionSubmitted
        )
    }

    @Test("receipt pruning preserves queued task receipts and removes only orphaned receipts")
    func pruningReceiptsUsesPersistedTaskIdentity() throws {
        let suiteName =
            "PhotoLibrarySaveReceiptStoreTests.Pruning.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let retainedTaskID = UUID().uuidString
        let orphanedTaskID = UUID().uuidString
        let store = PhotoLibrarySaveReceiptStore(
            defaults: defaults
        )
        store.record(
            assetIdentifier: "asset-retained",
            for: retainedTaskID
        )
        store.record(
            assetIdentifier: "asset-orphaned",
            for: orphanedTaskID
        )

        store.pruneReceipts(
            retaining: [retainedTaskID]
        )

        #expect(
            store.assetIdentifier(for: retainedTaskID)
            == "asset-retained"
        )
        #expect(
            store.assetIdentifier(for: orphanedTaskID)
            == nil
        )
    }

    @Test("photo save idempotency never scans the complete library")
    func idempotencyUsesDirectAssetLookup() throws {
        let exportSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift"
        )
        let livePhotoSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/PhotoKitLivePhotoAssetWriter.swift"
        )

        #expect(
            !exportSource.contains(
                "PHAsset.fetchAssets(\n            with: options"
            )
        )
        #expect(
            !livePhotoSource.contains(
                "PHAsset.fetchAssets(with: options)"
            )
        )
        #expect(
            exportSource.contains(
                "fetchAssets(\n            withLocalIdentifiers:"
            )
        )
        #expect(
            livePhotoSource.contains(
                "fetchAssets(\n                withLocalIdentifiers:"
            )
        )
    }

    @Test("PhotoKit saves persist idempotency receipts before committing asset changes")
    func receiptsAreRecordedInsideBothPhotoKitChangeTransactions() throws {
        let exportSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift"
        )
        let livePhotoSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/PhotoKitLivePhotoAssetWriter.swift"
        )

        try assertReceiptIsRecordedBeforeChangeCommit(
            in: exportSource
        )
        try assertReceiptIsRecordedBeforeChangeCommit(
            in: livePhotoSource
        )
    }

    @Test("static and Live Photo lookup share the receipt reconciliation policy")
    func photoKitWritersShareReceiptReconciliationPolicy() throws {
        let exportSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift"
        )
        let livePhotoSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/PhotoKitLivePhotoAssetWriter.swift"
        )

        #expect(
            exportSource.contains(
                "receiptReconciliationPolicy\n            .decision("
            )
        )
        #expect(
            livePhotoSource.contains(
                "receiptReconciliationPolicy\n            .decision("
            )
        )
        #expect(
            exportSource.contains(
                "receiptStore.markCommitted("
            )
        )
        #expect(
            livePhotoSource.contains(
                "receiptStore.markCommitted("
            )
        )
        #expect(
            !livePhotoSource.contains(
                "pendingReceiptGraceInterval"
            )
        )
    }

    @Test("receipt acknowledgement failure stays on readback pending for both writers")
    func receiptAcknowledgementFailureStaysRecoverable() throws {
        let exportSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift"
        )
        let livePhotoSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/PhotoKitLivePhotoAssetWriter.swift"
        )

        #expect(
            exportSource.contains(
                "guard receiptStore.markCommitted(for: idempotencyKey) else"
            )
        )
        #expect(
            exportSource.contains(
                "throw PhotoLibraryExportError.savedAssetReadbackPending"
            )
        )
        #expect(
            livePhotoSource.contains(
                "guard receiptStore.markCommitted(for: idempotencyKey) else"
            )
        )
        #expect(
            livePhotoSource.contains(
                "throw LivePhotoAssetWritingError.savedAssetReadbackPending"
            )
        )
    }

    @Test("reused assets require durable acknowledgement for both writers")
    func reusedAssetsRequireDurableAcknowledgement() throws {
        let exportSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift"
        )
        let livePhotoSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/PhotoKitLivePhotoAssetWriter.swift"
        )

        #expect(
            exportSource.contains(
                "guard receiptStore.materializePendingIntent("
            )
        )
        #expect(
            exportSource.contains(
                "receiptStore.ensureCommitted("
            )
        )
        #expect(
            exportSource.contains(
                "throw PhotoLibraryExportError\n                    .savedAssetReadbackPending"
            )
        )
        #expect(
            livePhotoSource.contains(
                "guard receiptStore.materializePendingIntent("
            )
        )
        #expect(
            livePhotoSource.contains(
                "receiptStore.ensureCommitted("
            )
        )
        #expect(
            livePhotoSource.contains(
                "throw LivePhotoAssetWritingError\n                    .savedAssetReadbackPending"
            )
        )
        #expect(
            exportSource.contains(
                "recordIntentAssetIdentifier"
            )
        )
        #expect(
            livePhotoSource.contains(
                "recordIntentAssetIdentifier"
            )
        )
    }

    @Test("PhotoKit save rechecks cancellation after the external transaction")
    func photoKitSaveRechecksCancellationAfterExternalTransaction() throws {
        let exportSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift"
        )
        let livePhotoSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/PhotoKitLivePhotoAssetWriter.swift"
        )

        try assertCancellationRecheckAfterTransaction(
            in: exportSource,
            placeholderGuard: "guard placeholderIdentifier != nil else"
        )
        try assertCancellationRecheckAfterTransaction(
            in: livePhotoSource,
            placeholderGuard: "guard let placeholderIdentifier else"
        )
    }

    @Test("PhotoKit writers persist a pre-commit intent before their external transaction")
    func photoKitWritersPersistPreCommitIntentBeforeExternalTransaction() throws {
        let exportSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift"
        )
        let livePhotoSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/PhotoKitLivePhotoAssetWriter.swift"
        )

        try assertPreCommitIntentBeforeTransaction(
            in: exportSource
        )
        try assertPreCommitIntentBeforeTransaction(
            in: livePhotoSource
        )
    }

    private func assertPreCommitIntentBeforeTransaction(
        in source: String
    ) throws {
        let intentStart = try #require(
            source.range(of: "receiptStore.recordIntent(")
        )
        let transactionStart = try #require(
            source.range(
                of: "try await performChanges {",
                range: intentStart.upperBound..<source.endIndex
            )
        )
        #expect(
            intentStart.lowerBound < transactionStart.lowerBound
        )
    }

    private func assertCancellationRecheckAfterTransaction(
        in source: String,
        placeholderGuard: String
    ) throws {
        let saveStart = try #require(
            source.range(of: "var placeholderIdentifier: String?")
        )
        let saveSource = source[saveStart.lowerBound...]
        let transactionStart = try #require(
            saveSource.range(of: "try await performChanges {")
        )
        let transactionSource = saveSource[transactionStart.lowerBound...]
        let transactionEnd = try #require(
            transactionSource.range(
                of: "\n            }\n\n            try Task.checkCancellation()\n\n            \(placeholderGuard)"
            )
        )

        #expect(
            transactionSource[..<transactionEnd.lowerBound]
                .contains("receiptStore.record(")
        )
    }

    private func assertReceiptIsRecordedBeforeChangeCommit(
        in source: String
    ) throws {
        let transactionStart = try #require(
            source.range(
                of: "try await performChanges {"
            )
        )
        let transaction = source[transactionStart.lowerBound...]
        let commitBoundary = try #require(
            transaction.range(
                of: "\n            }\n\n"
            )
        )

        #expect(
            transaction[..<commitBoundary.lowerBound]
                .contains("receiptStore.record(")
        )
    }

    private func sourceText(
        _ relativePath: String
    ) throws -> String {
        try String(
            contentsOf:
                repositoryRoot
                .appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}

private actor PhotoLibrarySaveGateProbe {

    private var activeOperations = 0
    private(set) var maximumConcurrentOperations = 0

    func enter() {
        activeOperations += 1
        maximumConcurrentOperations = max(
            maximumConcurrentOperations,
            activeOperations
        )
    }

    func leave() {
        activeOperations -= 1
    }
}

private actor PhotoLibrarySaveGateBlocker {

    private var firstOperationStarted = false
    private var firstOperationStartWaiters:
        [CheckedContinuation<Void, Never>] = []
    private var firstOperationReleaseContinuation:
        CheckedContinuation<Void, Never>?
    private(set) var secondOperationCount = 0

    func holdFirstOperation() async {
        firstOperationStarted = true
        let waiters = firstOperationStartWaiters
        firstOperationStartWaiters.removeAll()
        for waiter in waiters {
            waiter.resume()
        }

        await withCheckedContinuation { continuation in
            firstOperationReleaseContinuation = continuation
        }
    }

    func waitUntilFirstOperationStarts() async {
        guard !firstOperationStarted else {
            return
        }

        await withCheckedContinuation { continuation in
            firstOperationStartWaiters.append(continuation)
        }
    }

    func releaseFirstOperation() {
        firstOperationReleaseContinuation?.resume()
        firstOperationReleaseContinuation = nil
    }

    func recordSecondOperation() {
        secondOperationCount += 1
    }
}
