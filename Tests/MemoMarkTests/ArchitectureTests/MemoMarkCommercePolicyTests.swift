import Foundation
import Testing
@testable import MemoMark

@Suite("MemoMark commerce policy")
struct MemoMarkCommercePolicyTests {

    @Test("unverified App transaction falls back to Production")
    func unverifiedEnvironmentUsesProductionSafeDefault() {
        #expect(
            MemoMarkCommerceEnvironment.resolved(
                verified: nil
            ) == .production
        )
    }

    @Test("verified App transaction selects its environment")
    func verifiedEnvironmentWins() {
        #expect(
            MemoMarkCommerceEnvironment.resolved(
                verified: .sandbox
            ) == .sandbox
        )
    }

    @Test("First Recorder identity follows purchase date and direct ownership")
    func firstRecorderIdentityUsesCampaignBoundary() {
        let deadline = Date(timeIntervalSince1970: 200)

        #expect(
            MemoMarkCommercePolicy
                .shouldGrantFirstRecorderIdentity(
                    originalPurchaseDate:
                        Date(timeIntervalSince1970: 100),
                    campaignEndDate: deadline,
                    isFamilyShared: false
                )
        )
        #expect(
            !MemoMarkCommercePolicy
                .shouldGrantFirstRecorderIdentity(
                    originalPurchaseDate:
                        Date(timeIntervalSince1970: 100),
                    campaignEndDate: deadline,
                    isFamilyShared: true
                )
        )
        #expect(
            !MemoMarkCommercePolicy
                .shouldGrantFirstRecorderIdentity(
                    originalPurchaseDate:
                        Date(timeIntervalSince1970: 201),
                    campaignEndDate: deadline,
                    isFamilyShared: false
                )
        )
        #expect(
            MemoMarkCommercePolicy
                .shouldGrantFirstRecorderIdentity(
                    originalPurchaseDate:
                        Date(timeIntervalSince1970: 10_000),
                    campaignEndDate: nil,
                    isFamilyShared: false
                )
        )
    }

    @Test("First Recorder purchase copy closes at the campaign boundary")
    func firstRecorderCampaignOpenStateUsesCurrentDate() {
        let deadline = Date(timeIntervalSince1970: 200)

        #expect(
            MemoMarkCommercePolicy
                .isFirstRecorderCampaignOpen(
                    at: Date(timeIntervalSince1970: 200),
                    campaignEndDate: deadline
                )
        )
        #expect(
            !MemoMarkCommercePolicy
                .isFirstRecorderCampaignOpen(
                    at: Date(timeIntervalSince1970: 201),
                    campaignEndDate: deadline
                )
        )
        #expect(
            MemoMarkCommercePolicy
                .isFirstRecorderCampaignOpen(
                    at: Date(timeIntervalSince1970: 10_000),
                    campaignEndDate: nil
                )
        )
    }

    @Test("free and Plus policies keep distinct allowance and batch limits")
    func freeAndPlusPoliciesStayDistinct() {
        #expect(MemoMarkCommercePolicy.free.batchLimit == 20)
        #expect(MemoMarkCommercePolicy.plus.batchLimit == 40)
        #expect(
            MemoMarkCommercePolicy.free
                .remainingRecords(after: 190) == 10
        )
        #expect(
            MemoMarkCommercePolicy.plus
                .remainingRecords(after: 9_999) == nil
        )
    }

    @Test("Xcode QA policy is isolated from customer allowance")
    func xcodeQAPolicyIsUnlimitedButNotPlus() {
        let policy = MemoMarkCommercePolicy.resolved(
            for: .xcode,
            bonusAllowance: 0
        )

        #expect(!policy.isPlus)
        #expect(policy.totalAllowance == nil)
        #expect(policy.batchLimit == 40)
        #expect(
            policy.maximumAdmissionCount(
                after: 20_000,
                reservedRecordCount: 0
            ) == 40
        )
    }

    @Test("free milestones appear only at 190 and 200 successful records")
    func milestonesFollowSuccessfulRecordCount() {
        #expect(
            MemoMarkCommercePolicy.free
                .milestone(after: 189) == .none
        )
        #expect(
            MemoMarkCommercePolicy.free
                .milestone(after: 190)
            == .approaching(remaining: 10)
        )
        #expect(
            MemoMarkCommercePolicy.free
                .milestone(after: 200)
            == .allowanceCompleted
        )
        #expect(
            MemoMarkCommercePolicy.plus
                .milestone(after: 200) == .none
        )
    }

    @Test("bonus allowance extends free records without resetting usage")
    func bonusAllowanceExtendsFreeUse() {
        let policy =
            MemoMarkCommercePolicy.free(
                bonusAllowance: 50
            )

        #expect(policy.totalAllowance == 250)
        #expect(policy.remainingRecords(after: 200) == 50)
    }

    @Test("admission respects both batch limit and remaining allowance")
    func admissionRespectsAllowance() {
        #expect(
            MemoMarkCommercePolicy.free
                .maximumAdmissionCount(
                    after: 0
                ) == 20
        )
        #expect(
            MemoMarkCommercePolicy.free
                .maximumAdmissionCount(
                    after: 199
                ) == 1
        )
        #expect(
            MemoMarkCommercePolicy.free
                .maximumAdmissionCount(
                    after: 200
                ) == 0
        )
        #expect(
            MemoMarkCommercePolicy.plus
                .maximumAdmissionCount(
                    after: 9_999
                ) == 40
        )
    }

    @Test("admission reserves allowance for work already in flight")
    func admissionAccountsForReservedRecords() {
        #expect(
            MemoMarkCommercePolicy.free
                .maximumAdmissionCount(
                    after: 170,
                    reservedRecordCount: 20
                ) == 10
        )
        #expect(
            MemoMarkCommercePolicy.free
                .maximumAdmissionCount(
                    after: 180,
                    reservedRecordCount: 20
                ) == 0
        )
        #expect(
            MemoMarkCommercePolicy.plus
                .maximumAdmissionCount(
                    after: 9_999,
                    reservedRecordCount: 500
        ) == 40
        )
    }

    @Test("subscription and founder access include every first-party style")
    func paidAccessIncludesFirstPartyStyles() {
        let paidStyles = MemoryAnchorExpressionStyle.availableStyles(
            for: .birthday
        ).filter {
            MemoMarkCommerceCapability.allowsFirstPartyExpressionStyle(
                $0,
                accessSource: .plusSubscription
            )
        }
        #expect(
            paidStyles.count
            == MemoryAnchorExpressionStyle.availableStyles(
                for: .birthday
            ).count
        )
        #expect(
            !MemoMarkCommerceCapability
                .allowsFirstPartyExpressionStyle(
                    .birthdayCeremonial,
                    accessSource: .free
                )
        )
        #expect(
            MemoMarkCommerceCapability
                .allowsFirstPartyExpressionStyle(
                    .birthdayNatural,
                    accessSource: .free
                )
        )
    }

    @Test("expired subscription snapshot no longer grants plus access")
    func expiredSubscriptionSnapshotIsNotPlus() {
        let snapshot = MemoMarkCommerceSnapshot(
            environment: .production,
            accessSource: .plusSubscription,
            successfulRecordCount: 0,
            totalAllowance: nil,
            batchLimit: 40,
            firstRecorderDate: nil,
            validThrough: Date(timeIntervalSince1970: 100),
            updatedAt: Date(timeIntervalSince1970: 100)
        )
        #expect(!snapshot.isPlus)
        #expect(snapshot.isSubscription)
        #expect(!snapshot.isFounderLifetime)
    }

    @Test("free access keeps one object and one time anchor")
    func freeAccessUsesTheFoundationalLimits() {
        #expect(MemoMarkCommerceCapability.freeObjectLimit == 1)
        #expect(MemoMarkCommerceCapability.freeTimeAnchorLimit == 1)
        #expect(
            MemoMarkCommerceCapability
                .allowsFirstPartyExpressionStyle(
                    .birthdayNatural,
                    accessSource: .free
                )
        )
        #expect(
            !MemoMarkCommerceCapability
                .allowsFirstPartyExpressionStyle(
                    .birthdayWarm,
                    accessSource: .free
                )
        )
    }
}
