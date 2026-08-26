import Foundation

nonisolated final class MemoMarkCommercePersistence:
    @unchecked Sendable {

    private enum Key {
        static let prefix =
            "memomark.commerce.v1"
        static let sharedSnapshot =
            "memomark.commerce.v1.sharedSnapshot"
        static let preVersionTwoUsageEvidence = [
            "photomemo.personalProfile.firstRunCompleted",
            "photomemo.v1.welcomeSeen",
            "photomemo.selectedTemplate",
            "photomemo.v1.subjectLibrary"
        ]

        static func lastLaunchedMajorVersion(
            _ environment: MemoMarkCommerceEnvironment
        ) -> String {
            "\(prefix).\(environment.rawValue).lastLaunchedMajorVersion"
        }

        static func allowanceLedger(
            _ environment: MemoMarkCommerceEnvironment
        ) -> String {
            "\(prefix).\(environment.rawValue).allowanceLedger"
        }
    }

    private struct AllowanceLedger: Codable {
        var appliedGiftIDs: [String]
        var bonusAllowance: Int
    }

    private let defaults: UserDefaults
    private let synchronizeDefaults: () -> Bool
    private let lock = NSLock()

    init(
        defaults: UserDefaults =
            MemoMarkSharedContainer
            .sharedUserDefaults,
        synchronize: (() -> Bool)? = nil
    ) {
        self.defaults = defaults
        self.synchronizeDefaults =
            synchronize
            ?? { defaults.synchronize() }
    }

    func successfulRecordCount(
        environment:
            MemoMarkCommerceEnvironment
    ) -> Int {
        lock.withLock {
            defaults.integer(
                forKey:
                    countKey(environment)
            )
        }
    }

    func hasRecordedSuccessfulSave(
        taskID: UUID,
        environment:
            MemoMarkCommerceEnvironment
    ) -> Bool {
        lock.withLock {
            Set(
                defaults.stringArray(
                    forKey:
                        completedTaskIDsKey(environment)
                ) ?? []
            ).contains(taskID.uuidString)
        }
    }

    @discardableResult
    func recordSuccessfulSave(
        taskID: UUID,
        environment:
            MemoMarkCommerceEnvironment
    ) -> Bool {
        lock.withLock {
            let completedKey =
                completedTaskIDsKey(
                    environment
                )
            var completedTaskIDs =
                Set(
                    defaults.stringArray(
                        forKey: completedKey
                    ) ?? []
                )
            let taskKey = taskID.uuidString

            guard completedTaskIDs.insert(
                taskKey
            ).inserted else {
                return false
            }

            let countStorageKey = countKey(environment)
            let previousIDs = defaults.object(forKey: completedKey)
            let previousCount = defaults.object(forKey: countStorageKey)
            let expectedIDs = completedTaskIDs.sorted()
            let expectedCount =
                defaults.integer(forKey: countStorageKey) + 1

            defaults.set(expectedIDs, forKey: completedKey)
            defaults.set(expectedCount, forKey: countStorageKey)
            _ = synchronizeDefaults()

            guard defaults.stringArray(forKey: completedKey)
                    == expectedIDs,
                  defaults.integer(forKey: countStorageKey)
                    == expectedCount else {
                restore(
                    previousIDs,
                    forKey: completedKey
                )
                restore(
                    previousCount,
                    forKey: countStorageKey
                )
                _ = synchronizeDefaults()
                return false
            }

            return true
        }
    }

    @discardableResult
    func reconcileSuccessfulSaves(
        taskIDs: Set<UUID>,
        environment:
            MemoMarkCommerceEnvironment
    ) -> Bool {
        guard !taskIDs.isEmpty else {
            return true
        }

        return lock.withLock {
            let completedKey = completedTaskIDsKey(environment)
            let countStorageKey = countKey(environment)
            var completedTaskIDs = Set(
                defaults.stringArray(forKey: completedKey) ?? []
            )
            let previousIDs = defaults.object(forKey: completedKey)
            let previousCount = defaults.object(forKey: countStorageKey)
            completedTaskIDs.formUnion(
                taskIDs.map(\.uuidString)
            )
            let expectedIDs = completedTaskIDs.sorted()
            let expectedCount = max(
                defaults.integer(forKey: countStorageKey),
                expectedIDs.count
            )

            defaults.set(expectedIDs, forKey: completedKey)
            defaults.set(expectedCount, forKey: countStorageKey)
            _ = synchronizeDefaults()

            guard defaults.stringArray(forKey: completedKey)
                    == expectedIDs,
                  defaults.integer(forKey: countStorageKey)
                    == expectedCount else {
                restore(previousIDs, forKey: completedKey)
                restore(previousCount, forKey: countStorageKey)
                _ = synchronizeDefaults()
                return false
            }
            return true
        }
    }

    func bonusAllowance(
        environment:
            MemoMarkCommerceEnvironment
    ) -> Int {
        lock.withLock {
            allowanceLedger(
                for: environment
            ).bonusAllowance
        }
    }

    @discardableResult
    func applyMajorVersionGiftIfEligible(
        marketingVersion: String,
        amount: Int,
        environment: MemoMarkCommerceEnvironment
    ) -> Bool {
        guard let majorVersion = Int(
            marketingVersion
                .split(separator: ".")
                .first ?? ""
        ), majorVersion >= 2,
          amount > 0 else {
            return false
        }

        return lock.withLock {
            let previousMajorVersion =
                defaults.object(
                    forKey:
                        Key.lastLaunchedMajorVersion(
                            environment
                        )
                ) as? Int
            let isExistingInstallation: Bool

            if let previousMajorVersion {
                isExistingInstallation =
                    majorVersion > previousMajorVersion
            } else {
                isExistingInstallation =
                    Key.preVersionTwoUsageEvidence
                    .contains {
                        defaults.object(forKey: $0) != nil
                    }
            }

            guard isExistingInstallation else {
                recordMajorVersion(
                    majorVersion,
                    after: previousMajorVersion,
                    environment: environment
                )
                return false
            }

            let giftID = "major-\(majorVersion)"
            var ledger = allowanceLedger(
                for: environment
            )
            let wasAlreadyGranted = ledger.appliedGiftIDs.contains(
                giftID
            )

            if !wasAlreadyGranted {
                ledger.appliedGiftIDs.append(giftID)
                ledger.appliedGiftIDs.sort()
                ledger.bonusAllowance += amount
                guard saveAllowanceLedger(
                    ledger,
                    environment: environment
                ) else {
                    return false
                }
            }

            recordMajorVersion(
                majorVersion,
                after: previousMajorVersion,
                environment: environment
            )

            return !wasAlreadyGranted
        }
    }

    func firstRecorderDate(
        environment:
            MemoMarkCommerceEnvironment
    ) -> Date? {
        lock.withLock {
            defaults.object(
                forKey:
                    firstRecorderDateKey(
                        environment
                    )
            ) as? Date
        }
    }

    @discardableResult
    func grantFirstRecorderIdentityIfNeeded(
        date: Date,
        environment:
            MemoMarkCommerceEnvironment
    ) -> Bool {
        lock.withLock {
            let key =
                firstRecorderDateKey(
                    environment
                )
            let previousValue = defaults.object(forKey: key)
            guard defaults.object(
                forKey: key
            ) == nil else {
                return false
            }

            defaults.set(date, forKey: key)
            _ = synchronizeDefaults()
            guard defaults.object(forKey: key) as? Date == date else {
                restore(previousValue, forKey: key)
                _ = synchronizeDefaults()
                return false
            }
            return true
        }
    }

    func isTestFlightExperienceActive(
        environment:
            MemoMarkCommerceEnvironment
    ) -> Bool {
        guard environment == .sandbox else {
            return false
        }

        return lock.withLock {
            defaults.bool(
                forKey:
                    testFlightExperienceKey(
                        environment
                    )
            )
        }
    }

    @discardableResult
    func activateTestFlightExperience(
        environment:
            MemoMarkCommerceEnvironment
    ) -> Bool {
        guard environment == .sandbox else {
            return false
        }

        return lock.withLock {
            let key = testFlightExperienceKey(environment)
            let previousValue = defaults.object(forKey: key)
            defaults.set(
                true,
                forKey: key
            )
            _ = synchronizeDefaults()
            guard defaults.bool(forKey: key) else {
                restore(previousValue, forKey: key)
                _ = synchronizeDefaults()
                return false
            }
            return true
        }
    }

    @discardableResult
    func deactivateTestFlightExperience(
        environment:
            MemoMarkCommerceEnvironment
    ) -> Bool {
        guard environment == .sandbox else {
            return false
        }

        return lock.withLock {
            let key = testFlightExperienceKey(environment)
            let previousValue = defaults.object(forKey: key)
            defaults.removeObject(
                forKey: key
            )
            _ = synchronizeDefaults()
            guard defaults.object(forKey: key) == nil else {
                restore(previousValue, forKey: key)
                _ = synchronizeDefaults()
                return false
            }
            return true
        }
    }

    @discardableResult
    func applyAllowanceGift(
        id: String,
        amount: Int,
        environment:
            MemoMarkCommerceEnvironment
    ) -> Bool {
        let normalizedID =
            id.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !normalizedID.isEmpty,
              amount > 0 else {
            return false
        }

        return lock.withLock {
            var ledger = allowanceLedger(
                for: environment
            )

            guard !ledger.appliedGiftIDs.contains(
                normalizedID
            ) else {
                return false
            }

            ledger.appliedGiftIDs.append(normalizedID)
            ledger.appliedGiftIDs.sort()
            ledger.bonusAllowance += amount
            return saveAllowanceLedger(
                ledger,
                environment: environment
            )
        }
    }

    @discardableResult
    func saveSharedSnapshot(
        _ snapshot: MemoMarkCommerceSnapshot
    ) -> Bool {
        lock.withLock {
            guard let data = try? JSONEncoder()
                .encode(snapshot) else {
                return false
            }

            let previousValue = defaults.object(
                forKey: Key.sharedSnapshot
            )
            defaults.set(
                data,
                forKey: Key.sharedSnapshot
            )
            _ = synchronizeDefaults()
            guard defaults.data(forKey: Key.sharedSnapshot) == data else {
                restore(previousValue, forKey: Key.sharedSnapshot)
                _ = synchronizeDefaults()
                return false
            }
            return true
        }
    }

    func loadSharedSnapshot()
    -> MemoMarkCommerceSnapshot {
        lock.withLock {
            guard let data = defaults.data(
                forKey: Key.sharedSnapshot
            ),
            let snapshot = try? JSONDecoder()
                .decode(
                    MemoMarkCommerceSnapshot.self,
                    from: data
                ) else {
                return .initial
            }

            return snapshot
        }
    }

    func loadSharedSnapshot(
        compatibleWith environment:
            MemoMarkCommerceEnvironment
    ) -> MemoMarkCommerceSnapshot {
        let snapshot = loadSharedSnapshot()

        if environment == .xcode,
           snapshot.environment == .xcode,
           !snapshot.isPlus {
            let policy = MemoMarkCommercePolicy.resolved(
                for: environment,
                bonusAllowance:
                    bonusAllowance(
                        environment: environment
                    )
            )
            return MemoMarkCommerceSnapshot(
                environment: environment,
                accessSource: .free,
                successfulRecordCount:
                    successfulRecordCount(
                        environment: environment
                    ),
                totalAllowance: policy.totalAllowance,
                batchLimit: policy.batchLimit,
                firstRecorderDate: nil,
                updatedAt: snapshot.updatedAt
            )
        }

        guard snapshot.environment
                == environment else {
            let policy =
                MemoMarkCommercePolicy.resolved(
                    for: environment,
                    bonusAllowance:
                        bonusAllowance(
                            environment: environment
                        )
                )
            return MemoMarkCommerceSnapshot(
                environment: environment,
                accessSource: .free,
                successfulRecordCount:
                    successfulRecordCount(
                        environment: environment
                    ),
                totalAllowance:
                    policy.totalAllowance,
                batchLimit: policy.batchLimit,
                firstRecorderDate: nil,
                updatedAt: .distantPast
            )
        }

        return snapshot
    }

    private func recordMajorVersion(
        _ majorVersion: Int,
        after previousMajorVersion: Int?,
        environment: MemoMarkCommerceEnvironment
    ) {
        if previousMajorVersion.map({
            majorVersion > $0
        }) ?? true {
            defaults.set(
                majorVersion,
                forKey:
                    Key.lastLaunchedMajorVersion(
                        environment
                    )
            )
        }
    }

    private func allowanceLedger(
        for environment: MemoMarkCommerceEnvironment
    ) -> AllowanceLedger {
        guard let data = defaults.data(
            forKey: Key.allowanceLedger(environment)
        ),
        let ledger = try? JSONDecoder().decode(
            AllowanceLedger.self,
            from: data
        ) else {
            return AllowanceLedger(
                appliedGiftIDs:
                    defaults.stringArray(
                        forKey:
                            appliedGiftIDsKey(
                                environment
                            )
                    ) ?? [],
                bonusAllowance:
                    defaults.integer(
                        forKey:
                            bonusAllowanceKey(
                                environment
                            )
                    )
            )
        }

        return ledger
    }

    private func saveAllowanceLedger(
        _ ledger: AllowanceLedger,
        environment: MemoMarkCommerceEnvironment
    ) -> Bool {
        guard let data = try? JSONEncoder().encode(ledger) else {
            return false
        }

        let key = Key.allowanceLedger(environment)
        let previousValue = defaults.object(forKey: key)
        defaults.set(data, forKey: key)
        _ = synchronizeDefaults()
        guard defaults.data(forKey: key) == data else {
            restore(previousValue, forKey: key)
            _ = synchronizeDefaults()
            return false
        }
        return true
    }

    private func countKey(
        _ environment:
            MemoMarkCommerceEnvironment
    ) -> String {
        "\(Key.prefix).\(environment.rawValue).successfulRecordCount"
    }

    private func restore(
        _ value: Any?,
        forKey key: String
    ) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    private func completedTaskIDsKey(
        _ environment:
            MemoMarkCommerceEnvironment
    ) -> String {
        "\(Key.prefix).\(environment.rawValue).completedTaskIDs"
    }

    private func bonusAllowanceKey(
        _ environment:
            MemoMarkCommerceEnvironment
    ) -> String {
        "\(Key.prefix).\(environment.rawValue).bonusAllowance"
    }

    private func appliedGiftIDsKey(
        _ environment:
            MemoMarkCommerceEnvironment
    ) -> String {
        "\(Key.prefix).\(environment.rawValue).appliedGiftIDs"
    }

    private func testFlightExperienceKey(
        _ environment:
            MemoMarkCommerceEnvironment
    ) -> String {
        "\(Key.prefix).\(environment.rawValue).testFlightExperience"
    }

    private func firstRecorderDateKey(
        _ environment:
            MemoMarkCommerceEnvironment
    ) -> String {
        "\(Key.prefix).\(environment.rawValue).firstRecorderDate"
    }
}
