import Foundation

nonisolated final class MemoMarkCommercePersistence:
    @unchecked Sendable {

    private enum Key {
        static let prefix =
            "memomark.commerce.v1"
        static let sharedSnapshot =
            "memomark.commerce.v1.sharedSnapshot"
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
            defaults.integer(
                forKey:
                    bonusAllowanceKey(
                        environment
                    )
            )
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
            let appliedKey =
                appliedGiftIDsKey(
                    environment
                )
            var appliedIDs =
                Set(
                    defaults.stringArray(
                        forKey: appliedKey
                    ) ?? []
                )

            guard appliedIDs.insert(
                normalizedID
            ).inserted else {
                return false
            }

            defaults.set(
                appliedIDs.sorted(),
                forKey: appliedKey
            )
            defaults.set(
                defaults.integer(
                    forKey:
                        bonusAllowanceKey(
                            environment
                        )
                ) + amount,
                forKey:
                    bonusAllowanceKey(
                        environment
                    )
            )
            return true
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
