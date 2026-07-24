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
