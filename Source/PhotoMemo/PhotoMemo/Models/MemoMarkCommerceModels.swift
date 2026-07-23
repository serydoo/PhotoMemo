import Foundation

nonisolated enum MemoMarkCommerceEnvironment:
    String,
    Codable,
    CaseIterable,
    Sendable {

    case xcode
    case sandbox
    case production
}

nonisolated enum MemoMarkCommerceMilestone:
    Equatable,
    Sendable {

    case none
    case approaching(remaining: Int)
    case allowanceCompleted
}

nonisolated enum MemoMarkPurchaseState:
    Equatable,
    Sendable {

    case idle
    case loading
    case purchasing
    case pending
    case purchased
    case cancelled
    case failed(String)
}

nonisolated struct MemoMarkCommercePolicy:
    Equatable,
    Sendable {

    static let baseFreeAllowance = 200
    static let freeBatchLimit = 20
    static let plusBatchLimit = 40

    let isPlus: Bool
    let totalAllowance: Int?
    let batchLimit: Int

    static let free = free()

    static let plus =
        MemoMarkCommercePolicy(
            isPlus: true,
            totalAllowance: nil,
            batchLimit: plusBatchLimit
        )

    static func free(
        bonusAllowance: Int = 0
    ) -> MemoMarkCommercePolicy {
        MemoMarkCommercePolicy(
            isPlus: false,
            totalAllowance:
                baseFreeAllowance
                + max(bonusAllowance, 0),
            batchLimit: freeBatchLimit
        )
    }

    func remainingRecords(
        after successfulRecordCount: Int
    ) -> Int? {
        guard let totalAllowance else {
            return nil
        }

        return max(
            totalAllowance
            - max(successfulRecordCount, 0),
            0
        )
    }

    func milestone(
        after successfulRecordCount: Int
    ) -> MemoMarkCommerceMilestone {
        guard !isPlus,
              let totalAllowance else {
            return .none
        }

        if successfulRecordCount == totalAllowance {
            return .allowanceCompleted
        }

        let remaining =
            totalAllowance - successfulRecordCount

        if remaining == 10 {
            return .approaching(
                remaining: remaining
            )
        }

        return .none
    }

    func maximumAdmissionCount(
        after successfulRecordCount: Int,
        reservedRecordCount: Int = 0
    ) -> Int {
        guard !isPlus else {
            return batchLimit
        }

        return min(
            batchLimit,
            max(
                (remainingRecords(
                    after: successfulRecordCount
                ) ?? batchLimit)
                - max(reservedRecordCount, 0),
                0
            )
        )
    }
}

nonisolated struct MemoMarkCommerceSnapshot:
    Codable,
    Equatable,
    Sendable {

    let environment:
        MemoMarkCommerceEnvironment
    let isPlus: Bool
    let successfulRecordCount: Int
    let totalAllowance: Int?
    let batchLimit: Int
    let firstRecorderDate: Date?
    let updatedAt: Date

    var remainingRecords: Int? {
        guard let totalAllowance else {
            return nil
        }

        return max(
            totalAllowance
            - successfulRecordCount,
            0
        )
    }

    static let initial =
        MemoMarkCommerceSnapshot(
            environment: .production,
            isPlus: false,
            successfulRecordCount: 0,
            totalAllowance:
                MemoMarkCommercePolicy
                .baseFreeAllowance,
            batchLimit:
                MemoMarkCommercePolicy
                .freeBatchLimit,
            firstRecorderDate: nil,
            updatedAt: .distantPast
        )
}
