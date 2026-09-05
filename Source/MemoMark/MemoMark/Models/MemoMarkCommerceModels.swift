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
            receiptURL: localReceiptURL,
            isDebugBuild:
                _isDebugAssertConfiguration()
        )
    }

    private static var localReceiptURL: URL? {
        let receiptDirectory = Bundle.main.bundleURL
            .appendingPathComponent("_MASReceipt", isDirectory: true)
        for name in ["sandboxReceipt", "receipt"] {
            let candidate = receiptDirectory.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
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
    /// Historical non-consumable purchase or a historical activation grant.
    case founderLifetime
    /// Current MemoMark+ auto-renewable subscription.
    case plusSubscription
    /// Backward-compatible spelling used by Commerce v1 snapshots.
    case verifiedPlus
}

nonisolated enum MemoMarkPurchaseState:
    Equatable,
    Sendable {

    case idle
    case loading
    case purchasing
    case restoring
    case redeeming
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
    static let firstRecorderCampaignEndDate: Date? = nil

    let isPlus: Bool
    let totalAllowance: Int?
    let batchLimit: Int

    static let free = free()

    // A local Debug build has no App Store receipt and is isolated under the
    // `.xcode` commerce environment. Keep that QA ledger independent from
    // production/TestFlight allowance while still exercising the real queue
    // and Share Extension admission paths.
    static let development =
        MemoMarkCommercePolicy(
            isPlus: false,
            totalAllowance: nil,
            batchLimit: plusBatchLimit
        )

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

    static func resolved(
        for environment: MemoMarkCommerceEnvironment,
        bonusAllowance: Int = 0
    ) -> MemoMarkCommercePolicy {
        guard environment == .xcode else {
            return free(
                bonusAllowance: bonusAllowance
            )
        }

        return development
    }

    static func shouldGrantFirstRecorderIdentity(
        originalPurchaseDate: Date,
        campaignEndDate: Date?,
        isFamilyShared: Bool
    ) -> Bool {
        guard !isFamilyShared else {
            return false
        }

        guard let campaignEndDate else {
            return true
        }

        return originalPurchaseDate <= campaignEndDate
    }

    static func isFirstRecorderCampaignOpen(
        at date: Date,
        campaignEndDate: Date?
    ) -> Bool {
        guard let campaignEndDate else {
            return true
        }

        return date <= campaignEndDate
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

nonisolated enum MemoMarkCommerceCapability:
    Equatable,
    Sendable {

    case free
    case plus
    case collaborativeDesign

    static let freeObjectLimit = 1
    static let freeTimeAnchorLimit = 1

    static func allowsFirstPartyExpressionStyle(
        _ style: MemoryAnchorExpressionStyle,
        accessSource: MemoMarkCommerceAccessSource
    ) -> Bool {
        switch style {
        case .birthdayNatural,
             .relationshipNatural,
             .marriageNatural,
             .examNatural,
             .customNatural:
            return true
        default:
            return accessSource == .founderLifetime
                || accessSource == .verifiedPlus
                || accessSource == .plusSubscription
                || accessSource == .testFlightTemporary
        }
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
    let validThrough: Date?
    let lastVerifiedAt: Date?
    let updatedAt: Date

    init(
        environment: MemoMarkCommerceEnvironment,
        accessSource: MemoMarkCommerceAccessSource,
        successfulRecordCount: Int,
        totalAllowance: Int?,
        batchLimit: Int,
        firstRecorderDate: Date?,
        validThrough: Date? = nil,
        lastVerifiedAt: Date? = nil,
        updatedAt: Date
    ) {
        self.environment = environment
        self.accessSource = accessSource
        self.successfulRecordCount = successfulRecordCount
        self.totalAllowance = totalAllowance
        self.batchLimit = batchLimit
        self.firstRecorderDate = firstRecorderDate
        self.validThrough = validThrough
        self.lastVerifiedAt = lastVerifiedAt
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
        case validThrough
        case lastVerifiedAt
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
        validThrough = try container.decodeIfPresent(
            Date.self,
            forKey: .validThrough
        )
        lastVerifiedAt = try container.decodeIfPresent(
            Date.self,
            forKey: .lastVerifiedAt
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
                : .founderLifetime
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
        try container.encodeIfPresent(
            validThrough,
            forKey: .validThrough
        )
        try container.encodeIfPresent(
            lastVerifiedAt,
            forKey: .lastVerifiedAt
        )
        try container.encode(updatedAt, forKey: .updatedAt)
    }

    var isPlus: Bool {
        switch accessSource {
        case .free:
            return false
        case .plusSubscription:
            return validThrough.map { $0 > Date() } ?? false
        case .testFlightTemporary,
             .founderLifetime,
             .verifiedPlus:
            return true
        }
    }

    var isFounderLifetime: Bool {
        accessSource == .founderLifetime
            || accessSource == .verifiedPlus
    }

    var isSubscription: Bool {
        accessSource == .plusSubscription
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
            validThrough: nil,
            lastVerifiedAt: nil,
            updatedAt: .distantPast
        )
}
