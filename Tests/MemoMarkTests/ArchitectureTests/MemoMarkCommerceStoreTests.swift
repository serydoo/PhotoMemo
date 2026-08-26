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
                == [[MemoMarkCommerceStore.plusProductID]]
        )
        #expect(store.product == nil)
        guard case .failed = store.purchaseState else {
            Issue.record(
                "Expected an unavailable-store failure after reloading no product."
            )
            return
        }
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
