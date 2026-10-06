import Foundation
import Testing
@testable import MemoMark

@Suite("MemoMark commerce store")
struct MemoMarkCommerceStoreTests {

    @Test("purchase reports an unavailable store after a user-triggered product reload")
    @MainActor
    func missingProductBecomesRetryableFailure() async throws {
        let defaults = try makeDefaults()
        var requestedProductIDs: [[String]] = []
        let store = MemoMarkCommerceStore(
            persistence: MemoMarkCommercePersistence(
                defaults: defaults
            ),
            productLoader: { productIDs in
                requestedProductIDs.append(productIDs)
                return []
            }
        )

        await store.purchasePlus()

        #expect(
            requestedProductIDs
                == [MemoMarkCommerceStore.subscriptionProductIDs + [MemoMarkCommerceStore.legacyLifetimeProductID]]
        )
        #expect(store.product == nil)
        guard case .failed = store.purchaseState else {
            Issue.record(
                "Expected an unavailable-store failure after reloading no product."
            )
            return
        }
    }

    @Test("lifetime purchase reloads its own SKU and fails safely if unavailable")
    @MainActor
    func missingLifetimeIsRetryable() async throws {
        let defaults = try makeDefaults()
        var requestedProductIDs: [[String]] = []
        let store = MemoMarkCommerceStore(
            persistence: MemoMarkCommercePersistence(defaults: defaults),
            productLoader: { ids in
                requestedProductIDs.append(ids)
                return []
            }
        )
        await store.purchaseLifetime()
        #expect(requestedProductIDs == [MemoMarkCommerceStore.subscriptionProductIDs + [MemoMarkCommerceStore.legacyLifetimeProductID]])
        #expect(!store.isPlus)
        guard case .failed = store.purchaseState else {
            Issue.record("Missing lifetime product must not grant access.")
            return
        }
    }

    @Test("subscription and lifetime cannot overlap product reloads")
    @MainActor
    func purchaseActionsAreSerialized() async throws {
        let defaults = try makeDefaults()
        var loads = 0
        var pendingLoad: CheckedContinuation<Void, Never>?
        let store = MemoMarkCommerceStore(
            persistence: MemoMarkCommercePersistence(defaults: defaults),
            productLoader: { _ in
                loads += 1
                await withCheckedContinuation { pendingLoad = $0 }
                return []
            }
        )
        let first = Task { await store.purchaseLifetime() }
        while loads == 0 { await Task.yield() }
        await store.purchasePlus()
        pendingLoad?.resume()
        await first.value
        #expect(loads == 1)
        #expect(!store.isPlus)
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName =
            "MemoMarkCommerceStoreTests.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
