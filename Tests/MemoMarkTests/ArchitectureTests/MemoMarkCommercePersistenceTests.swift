import Foundation
import Testing
@testable import MemoMark

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

    @Test("durable completed task IDs repair a missed usage count")
    func durableCompletedTaskIDsRepairMissedUsageCount() throws {
        let defaults = try makeDefaults()
        let persistence = MemoMarkCommercePersistence(defaults: defaults)
        let firstTask = UUID()
        let secondTask = UUID()

        #expect(
            persistence.reconcileSuccessfulSaves(
                taskIDs: [firstTask, secondTask],
                environment: .production
            )
        )
        #expect(
            persistence.successfulRecordCount(
                environment: .production
            ) == 2
        )
        #expect(
            persistence.hasRecordedSuccessfulSave(
                taskID: firstTask,
                environment: .production
            )
        )
    }

    @Test("commerce persistence trusts verified read-back when synchronize reports false")
    func commercePersistenceUsesReadBackAsCommitEvidence() throws {
        let defaults = try makeDefaults()
        let persistence = MemoMarkCommercePersistence(
            defaults: defaults,
            synchronize: { false }
        )
        let taskID = UUID()

        #expect(
            persistence.reconcileSuccessfulSaves(
                taskIDs: [taskID],
                environment: .production
            )
        )
        #expect(
            persistence.successfulRecordCount(
                environment: .production
            ) == 1
        )
        #expect(
            persistence.hasRecordedSuccessfulSave(
                taskID: taskID,
                environment: .production
            )
        )

        let snapshot = MemoMarkCommerceSnapshot(
            environment: .production,
            accessSource: .free,
            successfulRecordCount: 1,
            totalAllowance: 200,
            batchLimit: 20,
            firstRecorderDate: nil,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        #expect(persistence.saveSharedSnapshot(snapshot))
        #expect(persistence.loadSharedSnapshot() == snapshot)
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
                amount: 100,
                environment: .production
            )
        )
        #expect(
            !persistence.applyAllowanceGift(
                id: "major-2",
                amount: 100,
                environment: .production
            )
        )
        #expect(
            persistence.bonusAllowance(
                environment: .production
            ) == 100
        )
    }

    @Test("fresh 2.0 installation records the launch without receiving an upgrade gift")
    func freshVersionTwoInstallDoesNotReceiveGift() throws {
        let defaults = try makeDefaults()
        let persistence = MemoMarkCommercePersistence(defaults: defaults)

        #expect(
            !persistence.applyMajorVersionGiftIfEligible(
                marketingVersion: "2.0",
                amount: 100,
                environment: .production
            )
        )
        #expect(
            persistence.bonusAllowance(
                environment: .production
            ) == 0
        )
    }

    @Test("pre-2.0 usage receives the version two gift once")
    func legacyInstallationReceivesVersionTwoGiftOnce() throws {
        let defaults = try makeDefaults()
        defaults.set(true, forKey: "photomemo.v1.welcomeSeen")
        let persistence = MemoMarkCommercePersistence(defaults: defaults)

        #expect(
            persistence.applyMajorVersionGiftIfEligible(
                marketingVersion: "2.0",
                amount: 100,
                environment: .production
            )
        )
        #expect(
            !persistence.applyMajorVersionGiftIfEligible(
                marketingVersion: "2.0.1",
                amount: 100,
                environment: .production
            )
        )
        #expect(
            persistence.bonusAllowance(
                environment: .production
            ) == 100
        )
    }

    @Test("existing installation receives each later major-version gift once")
    func laterMajorVersionGiftRequiresUpgrade() throws {
        let defaults = try makeDefaults()
        let persistence = MemoMarkCommercePersistence(defaults: defaults)

        #expect(
            !persistence.applyMajorVersionGiftIfEligible(
                marketingVersion: "2.0",
                amount: 100,
                environment: .production
            )
        )
        #expect(
            persistence.applyMajorVersionGiftIfEligible(
                marketingVersion: "3.0",
                amount: 100,
                environment: .production
            )
        )
        #expect(
            !persistence.applyMajorVersionGiftIfEligible(
                marketingVersion: "3.1",
                amount: 100,
                environment: .production
            )
        )
    }

    @Test("major-version gifts remain isolated by StoreKit environment")
    func majorVersionGiftRegistrationIsEnvironmentScoped() throws {
        let defaults = try makeDefaults()
        defaults.set(true, forKey: "photomemo.v1.welcomeSeen")
        let persistence = MemoMarkCommercePersistence(defaults: defaults)

        #expect(
            persistence.applyMajorVersionGiftIfEligible(
                marketingVersion: "2.0",
                amount: 100,
                environment: .sandbox
            )
        )
        #expect(
            persistence.applyMajorVersionGiftIfEligible(
                marketingVersion: "2.0",
                amount: 100,
                environment: .production
            )
        )
        #expect(
            !persistence.applyMajorVersionGiftIfEligible(
                marketingVersion: "2.0.1",
                amount: 100,
                environment: .sandbox
            )
        )
    }

    @Test("a durable gift ledger completes an interrupted major-version registration")
    func majorVersionGiftRegistrationRecoversWithoutDoubleGranting() throws {
        let defaults = try makeDefaults()
        defaults.set(true, forKey: "photomemo.v1.welcomeSeen")
        let persistence = MemoMarkCommercePersistence(defaults: defaults)

        #expect(
            persistence.applyAllowanceGift(
                id: "major-2",
                amount: 100,
                environment: .production
            )
        )
        #expect(
            !persistence.applyMajorVersionGiftIfEligible(
                marketingVersion: "2.0",
                amount: 100,
                environment: .production
            )
        )
        #expect(
            persistence.bonusAllowance(
                environment: .production
            ) == 100
        )
        #expect(
            persistence.applyMajorVersionGiftIfEligible(
                marketingVersion: "3.0",
                amount: 100,
                environment: .production
            )
        )
        #expect(
            persistence.bonusAllowance(
                environment: .production
            ) == 200
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
                accessSource: .verifiedPlus,
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

    @Test("Production ignores a persisted TestFlight temporary snapshot")
    func productionRejectsTestFlightTemporarySnapshot() throws {
        let defaults = try makeDefaults()
        let persistence =
            MemoMarkCommercePersistence(
                defaults: defaults
            )
        persistence.saveSharedSnapshot(
            MemoMarkCommerceSnapshot(
                environment: .sandbox,
                accessSource: .testFlightTemporary,
                successfulRecordCount: 18,
                totalAllowance: nil,
                batchLimit: 40,
                firstRecorderDate: nil,
                updatedAt: Date()
            )
        )

        let snapshot = persistence.loadSharedSnapshot(
            compatibleWith: .production
        )

        #expect(snapshot.environment == .production)
        #expect(snapshot.accessSource == .free)
        #expect(snapshot.batchLimit == 20)
        #expect(snapshot.totalAllowance == 200)
    }

    @Test("Xcode QA snapshot stays isolated when its ledger exceeds free allowance")
    func xcodeQASnapshotDoesNotUseProductionAllowance() throws {
        let defaults = try makeDefaults()
        let persistence = MemoMarkCommercePersistence(defaults: defaults)
        let completedTaskIDs = Set(
            (0..<201).map { _ in UUID() }
        )

        #expect(
            persistence.reconcileSuccessfulSaves(
                taskIDs: completedTaskIDs,
                environment: .xcode
            )
        )
        #expect(
            persistence.saveSharedSnapshot(
                MemoMarkCommerceSnapshot(
                    environment: .sandbox,
                    accessSource: .testFlightTemporary,
                    successfulRecordCount: 44,
                    totalAllowance: nil,
                    batchLimit: 40,
                    firstRecorderDate: nil,
                    updatedAt: Date()
                )
            )
        )

        let snapshot = persistence.loadSharedSnapshot(
            compatibleWith: .xcode
        )

        #expect(snapshot.environment == .xcode)
        #expect(snapshot.successfulRecordCount == 201)
        #expect(snapshot.totalAllowance == nil)
        #expect(snapshot.batchLimit == 40)
        #expect(snapshot.remainingRecords == nil)
    }

    @Test("receipt identity resolves the current distribution environment")
    func receiptIdentityResolvesEnvironment() {
        #expect(
            MemoMarkCommerceEnvironment.runtime(
                receiptURL: URL(fileURLWithPath: "/StoreKit/sandboxReceipt"),
                isDebugBuild: false
            ) == .sandbox
        )
        #expect(
            MemoMarkCommerceEnvironment.runtime(
                receiptURL: URL(fileURLWithPath: "/StoreKit/receipt"),
                isDebugBuild: false
            ) == .production
        )
        #expect(
            MemoMarkCommerceEnvironment.runtime(
                receiptURL: nil,
                isDebugBuild: false
            ) == .production
        )
        #expect(
            MemoMarkCommerceEnvironment.runtime(
                receiptURL: nil,
                isDebugBuild: true
            ) == .xcode
        )
    }

    @Test("legacy Plus snapshot migrates to an explicit access source")
    func legacySnapshotMigratesAccessSource() throws {
        let legacy = LegacySnapshot(
            environment: .sandbox,
            isPlus: true,
            successfulRecordCount: 12,
            totalAllowance: nil,
            batchLimit: 40,
            firstRecorderDate: nil,
            updatedAt: Date(timeIntervalSince1970: 100)
        )

        let decoded = try JSONDecoder().decode(
            MemoMarkCommerceSnapshot.self,
            from: JSONEncoder().encode(legacy)
        )

        #expect(decoded.accessSource == .testFlightTemporary)
        #expect(decoded.isPlus)
        #expect(decoded.successfulRecordCount == 12)
    }

    @Test("TestFlight experience is durable and Sandbox-only")
    func testFlightExperienceIsSandboxOnly() throws {
        let defaults = try makeDefaults()
        let persistence =
            MemoMarkCommercePersistence(
                defaults: defaults
            )

        #expect(
            persistence.activateTestFlightExperience(
                environment: .sandbox
            )
        )
        #expect(
            persistence.isTestFlightExperienceActive(
                environment: .sandbox
            )
        )
        #expect(
            !persistence.isTestFlightExperienceActive(
                environment: .production
            )
        )
        #expect(
            !persistence.activateTestFlightExperience(
                environment: .production
            )
        )

        let reloaded =
            MemoMarkCommercePersistence(
                defaults: defaults
            )
        #expect(
            reloaded.isTestFlightExperienceActive(
                environment: .sandbox
            )
        )

        #expect(
            reloaded.deactivateTestFlightExperience(
                environment: .sandbox
            )
        )
        #expect(
            !reloaded.isTestFlightExperienceActive(
                environment: .sandbox
            )
        )
        #expect(
            !reloaded.deactivateTestFlightExperience(
                environment: .production
            )
        )
    }

    @Test("First Recorder identity is granted once and remains independent from Plus")
    func firstRecorderIdentityIsDurable() throws {
        let defaults = try makeDefaults()
        let persistence =
            MemoMarkCommercePersistence(
                defaults: defaults
            )
        let firstDate = Date(timeIntervalSince1970: 100)
        let laterDate = Date(timeIntervalSince1970: 200)

        #expect(
            persistence.grantFirstRecorderIdentityIfNeeded(
                date: firstDate,
                environment: .production
            )
        )
        #expect(
            !persistence.grantFirstRecorderIdentityIfNeeded(
                date: laterDate,
                environment: .production
            )
        )
        #expect(
            persistence.firstRecorderDate(
                environment: .production
            ) == firstDate
        )
        #expect(
            persistence.firstRecorderDate(
                environment: .sandbox
            ) == nil
        )
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

    private struct LegacySnapshot: Codable {
        let environment: MemoMarkCommerceEnvironment
        let isPlus: Bool
        let successfulRecordCount: Int
        let totalAllowance: Int?
        let batchLimit: Int
        let firstRecorderDate: Date?
        let updatedAt: Date
    }
}
