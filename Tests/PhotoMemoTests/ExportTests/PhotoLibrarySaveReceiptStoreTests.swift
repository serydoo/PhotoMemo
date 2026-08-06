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
            !livePhotoSource.contains(
                "pendingReceiptGraceInterval"
            )
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
                of: "\n            }\n\n            guard"
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
