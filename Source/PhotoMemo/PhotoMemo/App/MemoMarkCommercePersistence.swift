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
    private let lock = NSLock()

    init(
        defaults: UserDefaults =
            PhotoMemoSharedContainer
            .sharedUserDefaults
    ) {
        self.defaults = defaults
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

            defaults.set(
                completedTaskIDs.sorted(),
                forKey: completedKey
            )
            defaults.set(
                defaults.integer(
                    forKey:
                        countKey(environment)
                ) + 1,
                forKey:
                    countKey(environment)
            )
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
            guard defaults.object(
                forKey: key
            ) == nil else {
                return false
            }

            defaults.set(date, forKey: key)
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

        lock.withLock {
            defaults.set(
                true,
                forKey:
                    testFlightExperienceKey(
                        environment
                    )
            )
        }
        return true
    }

    @discardableResult
    func deactivateTestFlightExperience(
        environment:
            MemoMarkCommerceEnvironment
    ) -> Bool {
        guard environment == .sandbox else {
            return false
        }

        lock.withLock {
            defaults.removeObject(
                forKey:
                    testFlightExperienceKey(
                        environment
                    )
            )
        }
        return true
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

    func saveSharedSnapshot(
        _ snapshot: MemoMarkCommerceSnapshot
    ) {
        lock.withLock {
            guard let data = try? JSONEncoder()
                .encode(snapshot) else {
                return
            }

            defaults.set(
                data,
                forKey: Key.sharedSnapshot
            )
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

        guard snapshot.environment
                == environment else {
            let policy =
                MemoMarkCommercePolicy.free(
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

        defaults.set(
            data,
            forKey: Key.allowanceLedger(environment)
        )
        return true
    }

    private func countKey(
        _ environment:
            MemoMarkCommerceEnvironment
    ) -> String {
        "\(Key.prefix).\(environment.rawValue).successfulRecordCount"
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
