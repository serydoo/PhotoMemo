import Foundation
import Testing
@testable import PhotoMemo

@Suite("Photo library save receipts")
struct PhotoLibrarySaveReceiptStoreTests {

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
