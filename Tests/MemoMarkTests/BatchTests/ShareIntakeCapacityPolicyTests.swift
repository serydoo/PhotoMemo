import Foundation
import Testing
@testable import MemoMark

@Suite("Share intake capacity policy")
struct ShareIntakeCapacityPolicyTests {

    @Test("Free Share intake is bounded by both the batch and remaining-record limits")
    func freeIntakeUsesTheStricterLimit() {
        let snapshot = MemoMarkCommerceSnapshot(
            environment: .production,
            accessSource: .free,
            successfulRecordCount: 198,
            totalAllowance: 200,
            batchLimit: 20,
            firstRecorderDate: nil,
            updatedAt: .distantPast
        )

        #expect(
            ShareIntakeCapacityPolicy()
                .maximumSupportedPhotoCount(
                    for: snapshot
                ) == 2
        )
    }

    @Test("Unlimited QA capacity still honors its batch limit")
    func unlimitedIntakeUsesBatchLimit() {
        let snapshot = MemoMarkCommerceSnapshot(
            environment: .xcode,
            accessSource: .free,
            successfulRecordCount: 0,
            totalAllowance: nil,
            batchLimit: 40,
            firstRecorderDate: nil,
            updatedAt: .distantPast
        )

        #expect(
            ShareIntakeCapacityPolicy()
                .maximumSupportedPhotoCount(
                    for: snapshot
                ) == 40
        )
    }
}
