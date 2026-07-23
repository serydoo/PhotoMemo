import Foundation
import Testing
@testable import PhotoMemo

@Suite("MemoMark commerce persistence")
struct MemoMarkCommercePersistenceTests {

    @Test("successful saves count once per environment and task")
    func successfulSavesAreIdempotentAndNamespaced() throws {
        let defaults = try makeDefaults()
        let persistence =
            MemoMarkCommercePersistence(
                defaults: defaults
            )
        let taskID = UUID()

        #expect(
            persistence.recordSuccessfulSave(
                taskID: taskID,
                environment: .sandbox
            )
        )
        #expect(
            !persistence.recordSuccessfulSave(
                taskID: taskID,
                environment: .sandbox
            )
        )
        #expect(
            persistence.successfulRecordCount(
                environment: .sandbox
            ) == 1
        )
        #expect(
            persistence.successfulRecordCount(
                environment: .production
            ) == 0
        )
    }

    @Test("major-version gift applies once without resetting records")
    func majorVersionGiftAppliesOnce() throws {
        let defaults = try makeDefaults()
        let persistence =
            MemoMarkCommercePersistence(
                defaults: defaults
            )

        #expect(
            persistence.applyAllowanceGift(
                id: "major-2",
                amount: 50,
                environment: .production
            )
        )
        #expect(
            !persistence.applyAllowanceGift(
                id: "major-2",
                amount: 50,
                environment: .production
            )
        )
        #expect(
            persistence.bonusAllowance(
                environment: .production
            ) == 50
        )
    }

    @Test("shared snapshot round trips for the Share Extension")
    func sharedSnapshotRoundTrips() throws {
        let defaults = try makeDefaults()
        let persistence =
            MemoMarkCommercePersistence(
                defaults: defaults
            )
        let snapshot =
            MemoMarkCommerceSnapshot(
                environment: .sandbox,
                isPlus: true,
                successfulRecordCount: 200,
                totalAllowance: nil,
                batchLimit: 40,
                firstRecorderDate: Date(
                    timeIntervalSince1970: 1_721_692_800
                ),
                updatedAt: Date(
                    timeIntervalSince1970: 1_721_692_900
                )
            )

        persistence.saveSharedSnapshot(snapshot)

        #expect(persistence.loadSharedSnapshot() == snapshot)
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName =
            "MemoMarkCommercePersistenceTests.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(
            forName: suiteName
        )
        return defaults
    }
}
