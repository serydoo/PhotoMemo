#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Photo Library save receipt actor ledger")
struct PhotoLibrarySaveReceiptLedgerTests {

    @Test("ledger reads the existing schema without rewriting its keys")
    func readsExistingSchema() async throws {
        let suiteName = Self.makeSuiteName()
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = PhotoLibrarySaveReceiptStore(defaults: defaults)
        #expect(
            store.record(
                assetIdentifier: "asset-existing",
                for: "task/existing"
            )
        )

        let ledger = PhotoLibrarySaveReceiptLedger(store: store)

        #expect(
            await ledger.assetIdentifier(
                for: "task/existing"
            ) == "asset-existing"
        )
        #expect(
            defaults.dictionaryRepresentation().keys.contains(
                "photomemo.photoLibrarySaveReceipt.v1.task-existing"
            )
        )
    }

    @Test("placeholder capability can only advance an existing intent")
    func placeholderCapabilityAdvancesExistingIntent() async throws {
        let suiteName = Self.makeSuiteName()
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = PhotoLibrarySaveReceiptStore(defaults: defaults)
        let ledger = PhotoLibrarySaveReceiptLedger(store: store)
        let writer = ledger.placeholderIntentWriter

        #expect(
            !writer.record(
                assetIdentifier: "asset-before-intent",
                for: "task-placeholder"
            )
        )
        #expect(
            await ledger.recordIntent(
                for: "task-placeholder"
            )
        )
        #expect(
            writer.record(
                assetIdentifier: "asset-placeholder",
                for: "task-placeholder"
            )
        )
        #expect(
            await ledger.pendingAssetIdentifier(
                for: "task-placeholder"
            ) == "asset-placeholder"
        )
        #expect(
            await ledger.materializePendingIntent(
                for: "task-placeholder"
            )
        )
        #expect(
            await ledger.ensureCommitted(
                for: "task-placeholder"
            )
        )
        #expect(
            await ledger.receipt(
                for: "task-placeholder"
            )?.phase == .commitAcknowledged
        )
    }

    @Test("concurrent receipt commands remain independently durable")
    func serializesConcurrentCommands() async throws {
        let suiteName = Self.makeSuiteName()
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let ledger = PhotoLibrarySaveReceiptLedger(
            store: PhotoLibrarySaveReceiptStore(
                defaults: defaults
            )
        )

        await withTaskGroup(of: Bool.self) { group in
            for index in 0..<20 {
                group.addTask {
                    await ledger.recordIntent(
                        for: "task-\(index)"
                    )
                }
            }
            for await result in group {
                #expect(result)
            }
        }

        for index in 0..<20 {
            #expect(
                await ledger.hasPendingIntent(
                    for: "task-\(index)"
                )
            )
        }
    }

    private static func makeSuiteName() -> String {
        "PhotoLibrarySaveReceiptLedgerTests.\(UUID().uuidString)"
    }
}
#endif
