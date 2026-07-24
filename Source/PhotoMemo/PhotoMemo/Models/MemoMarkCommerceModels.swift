import Foundation

nonisolated enum MemoMarkCommerceEnvironment:
    String,
    Codable,
    CaseIterable,
    Sendable {

    case xcode
    case sandbox
    case production

    static func resolved(
        verified: MemoMarkCommerceEnvironment?
    ) -> MemoMarkCommerceEnvironment {
        verified ?? .production
    }

    static func runtime(
        receiptURL: URL?,
        isDebugBuild: Bool
    ) -> MemoMarkCommerceEnvironment {
        if receiptURL?.lastPathComponent
            == "sandboxReceipt" {
            return .sandbox
        }

        if isDebugBuild,
           receiptURL == nil {
            return .xcode
        }

        return .production
    }

    static var currentRuntime:
        MemoMarkCommerceEnvironment {
        runtime(
            receiptURL:
                Bundle.main.appStoreReceiptURL,
            isDebugBuild:
                _isDebugAssertConfiguration()
        )
    }
}

nonisolated enum MemoMarkCommerceMilestone:
    Equatable,
    Sendable {

    case none
    case approaching(remaining: Int)
    case allowanceCompleted
}

nonisolated enum MemoMarkCommerceAccessSource:
    String,
    Codable,
    Sendable {

    case free
    case testFlightTemporary
    case verifiedPlus
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
    static let firstRecorderProgramActive = true

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

    static func shouldGrantFirstRecorderIdentity(
        isProgramActive: Bool,
        isFamilyShared: Bool
    ) -> Bool {
        isProgramActive && !isFamilyShared
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
    let accessSource:
        MemoMarkCommerceAccessSource
    let successfulRecordCount: Int
    let totalAllowance: Int?
    let batchLimit: Int
    let firstRecorderDate: Date?
    let updatedAt: Date

    init(
        environment: MemoMarkCommerceEnvironment,
        accessSource: MemoMarkCommerceAccessSource,
        successfulRecordCount: Int,
        totalAllowance: Int?,
        batchLimit: Int,
        firstRecorderDate: Date?,
        updatedAt: Date
    ) {
        self.environment = environment
        self.accessSource = accessSource
        self.successfulRecordCount = successfulRecordCount
        self.totalAllowance = totalAllowance
        self.batchLimit = batchLimit
        self.firstRecorderDate = firstRecorderDate
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case environment
        case accessSource
        case isPlus
        case successfulRecordCount
        case totalAllowance
        case batchLimit
        case firstRecorderDate
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )
        environment = try container.decode(
            MemoMarkCommerceEnvironment.self,
            forKey: .environment
        )
        successfulRecordCount = try container.decode(
            Int.self,
            forKey: .successfulRecordCount
        )
        totalAllowance = try container.decodeIfPresent(
            Int.self,
            forKey: .totalAllowance
        )
        batchLimit = try container.decode(
            Int.self,
            forKey: .batchLimit
        )
        firstRecorderDate = try container.decodeIfPresent(
            Date.self,
            forKey: .firstRecorderDate
        )
        updatedAt = try container.decode(
            Date.self,
            forKey: .updatedAt
        )

        if let source = try container.decodeIfPresent(
            MemoMarkCommerceAccessSource.self,
            forKey: .accessSource
        ) {
            accessSource = source
        } else if try container.decodeIfPresent(
            Bool.self,
            forKey: .isPlus
        ) == true {
            accessSource = firstRecorderDate == nil
                && environment == .sandbox
                ? .testFlightTemporary
                : .verifiedPlus
        } else {
            accessSource = .free
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )
        try container.encode(environment, forKey: .environment)
        try container.encode(accessSource, forKey: .accessSource)
        try container.encode(isPlus, forKey: .isPlus)
        try container.encode(
            successfulRecordCount,
            forKey: .successfulRecordCount
        )
        try container.encodeIfPresent(
            totalAllowance,
            forKey: .totalAllowance
        )
        try container.encode(batchLimit, forKey: .batchLimit)
        try container.encodeIfPresent(
            firstRecorderDate,
            forKey: .firstRecorderDate
        )
        try container.encode(updatedAt, forKey: .updatedAt)
    }

    var isPlus: Bool {
        accessSource != .free
    }

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
            accessSource: .free,
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
