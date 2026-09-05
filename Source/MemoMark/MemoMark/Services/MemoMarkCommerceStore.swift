#if !MEMOMARK_SHARE_EXTENSION
import Combine
import Foundation
import os
import StoreKit
#if os(iOS)
import UIKit
#endif

@MainActor
final class MemoMarkCommerceStore:
    ObservableObject {

    static let plusProductID =
        "com.serydoo.PhotoMemo.iOS.memomarkplus.subscription.annual"
    static let legacyLifetimeProductID =
        "com.serydoo.PhotoMemo.iOS.memomarkplus.lifetime"

    @Published private(set) var product: Product?
    @Published private(set) var purchaseState:
        MemoMarkPurchaseState = .idle
    @Published private(set) var snapshot:
        MemoMarkCommerceSnapshot

    private let persistence:
        MemoMarkCommercePersistence
    private let productLoader:
        ([String]) async throws -> [Product]
    private var transactionListener:
        Task<Void, Never>?

    init(
        persistence:
            MemoMarkCommercePersistence =
                MemoMarkCommercePersistence(),
        productLoader:
            @escaping ([String]) async throws -> [Product] = {
                productIDs in
                try await Product.products(
                    for: productIDs
                )
            }
    ) {
        self.persistence = persistence
        self.productLoader = productLoader
        self.snapshot =
            persistence.loadSharedSnapshot(
                compatibleWith:
                    .currentRuntime
            )
    }

    deinit {
        transactionListener?.cancel()
    }

    var isPlus: Bool {
        snapshot.isPlus
    }

    var hasVerifiedPlusEntitlement: Bool {
        snapshot.isPlus
    }

    var hasFounderLifetimeEntitlement: Bool {
        snapshot.isFounderLifetime
    }

    var hasActiveSubscription: Bool {
        snapshot.isSubscription && snapshot.isPlus
    }

    var hasFirstRecorderIdentity: Bool {
        snapshot.firstRecorderDate != nil
    }

    var isTestFlightExperienceActive: Bool {
        snapshot.accessSource
            == .testFlightTemporary
        && persistence
            .isTestFlightExperienceActive(
                environment: .sandbox
            )
    }

    var displayPrice: String {
        product?.displayPrice ?? "—"
    }

    var isPurchaseActionInProgress: Bool {
        purchaseState == .loading
        || purchaseState == .purchasing
        || purchaseState == .restoring
        || purchaseState == .redeeming
    }

    var remainingRecords: Int? {
        snapshot.remainingRecords
    }

    var environment:
        MemoMarkCommerceEnvironment {
        snapshot.environment
    }

    var isFirstRecorderCampaignOpen: Bool {
        MemoMarkCommercePolicy
            .isFirstRecorderCampaignOpen(
                at: Date(),
                campaignEndDate:
                    MemoMarkCommercePolicy
                    .firstRecorderCampaignEndDate
            )
    }

    func start() async {
        guard transactionListener == nil else {
            return
        }

        transactionListener =
            Task { [weak self] in
                for await result in
                    Transaction.updates {
                    guard !Task.isCancelled else {
                        return
                    }
                    await self?
                        .handleTransactionResult(
                            result
                        )
                }
            }

        await refresh()
    }

    func refresh() async {
        purchaseState = .restoring

        let environment =
            await resolvedEnvironment()

        product = await loadProduct()

        var lifetimeTransaction: Transaction?
        var subscriptionTransaction: Transaction?

        for await result in
            Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.revocationDate == nil else {
                continue
            }
            if transaction.productID == Self.legacyLifetimeProductID {
                lifetimeTransaction = transaction
            } else if transaction.productID == Self.plusProductID,
                      transaction.expirationDate.map({ $0 > Date() }) ?? true {
                subscriptionTransaction = transaction
            }
        }

        publishSnapshot(
            environment: environment,
            lifetimeTransaction: lifetimeTransaction,
            subscriptionTransaction: subscriptionTransaction
        )
        if lifetimeTransaction != nil || subscriptionTransaction != nil {
            purchaseState = .purchased
        } else if product != nil {
            purchaseState = .idle
        } else {
            purchaseState = unavailableStoreState
        }
    }

    func purchasePlus() async {
#if DEBUG
        print("MemoMark.StoreKit: purchase action received")
#endif
        let productToPurchase: Product

        if let product {
            productToPurchase = product
        } else {
            purchaseState = .loading

            guard let loadedProduct = await loadProduct() else {
                purchaseState = unavailableStoreState
                return
            }

            product = loadedProduct
            productToPurchase = loadedProduct
        }

        purchaseState = .purchasing

        do {
#if DEBUG
            print("MemoMark.StoreKit: calling Product.purchase()")
#endif
            let result = try await productToPurchase.purchase()

            switch result {
            case .success(let verification):
#if DEBUG
                print("MemoMark.StoreKit: purchase result is success")
#endif
                await handleTransactionResult(
                    verification
                )
            case .pending:
#if DEBUG
                print("MemoMark.StoreKit: purchase result is pending")
#endif
                purchaseState = .pending
            case .userCancelled:
#if DEBUG
                print("MemoMark.StoreKit: purchase result is cancelled")
#endif
                purchaseState = .cancelled
            @unknown default:
                purchaseState =
                    .failed(
                        localized(
                            "commerce.error.unknown_purchase_state",
                            fallback: "购买状态暂时无法确认，请稍后恢复购买。"
                        )
                    )
            }
        } catch {
            purchaseState =
                .failed(error.localizedDescription)
        }
    }

    func restorePurchases() async {
        purchaseState = .loading

        do {
            try await AppStore.sync()
            await refresh()
        } catch {
            purchaseState =
                .failed(error.localizedDescription)
        }
    }

    @discardableResult
    func deactivateTestFlightExperience() -> Bool {
        guard isTestFlightExperienceActive,
              persistence
                .deactivateTestFlightExperience(
                    environment: .sandbox
                ) else {
            return false
        }

        publishSnapshot(
            environment: .sandbox,
            lifetimeTransaction: nil,
            subscriptionTransaction: nil
        )
        return true
    }

#if os(iOS)
    func redeemOfferCode() async {
        purchaseState = .redeeming
        guard let scene =
                UIApplication.shared
                .connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: {
                    $0.activationState
                    == .foregroundActive
                }) else {
            purchaseState =
                .failed(
                    localized(
                        "commerce.error.redemption_unavailable",
                        fallback: "暂时无法打开兑换页面，请稍后重试。"
                    )
                )
            return
        }

        do {
            try await AppStore
                .presentOfferCodeRedeemSheet(
                    in: scene
                )
            await refresh()
        } catch {
            purchaseState =
                .failed(error.localizedDescription)
        }
    }
#endif

    func noteSuccessfulSave(
        taskID: UUID
    ) {
        guard !snapshot.isPlus else {
            return
        }

        guard persistence.recordSuccessfulSave(
            taskID: taskID,
            environment: snapshot.environment
        ) else {
            return
        }

        publishSnapshot(
            environment: snapshot.environment,
            lifetimeTransaction: nil,
            subscriptionTransaction: nil
        )
    }

    func applyMajorVersionGiftIfNeeded(
        marketingVersion: String
    ) {
        guard !snapshot.isPlus,
              persistence
                .applyMajorVersionGiftIfEligible(
                    marketingVersion: marketingVersion,
                    amount: 100,
                    environment: snapshot.environment
                ) else {
            return
        }

        publishSnapshot(
            environment: snapshot.environment,
            lifetimeTransaction: nil,
            subscriptionTransaction: nil
        )
    }

    func adoptSharedSnapshot(
        _ sharedSnapshot:
            MemoMarkCommerceSnapshot
    ) {
        guard sharedSnapshot.environment
                == snapshot.environment,
              sharedSnapshot.updatedAt
                > snapshot.updatedAt else {
            return
        }

        snapshot = sharedSnapshot
    }

    private func handleTransactionResult(
        _ result:
            VerificationResult<Transaction>
    ) async {
        guard case .verified(let transaction) =
                result else {
            purchaseState =
                .failed(
                    localized(
                        "commerce.error.unverified_transaction",
                        fallback: "App Store 无法验证这笔交易。"
                    )
                )
            return
        }

        guard transaction.productID == Self.plusProductID
                || transaction.productID == Self.legacyLifetimeProductID else {
            return
        }

        let environment =
            commerceEnvironment(
                transaction.environment
            )
        publishSnapshot(
            environment: environment,
            lifetimeTransaction:
                transaction.productID == Self.legacyLifetimeProductID
                && transaction.revocationDate == nil
                ? transaction : nil,
            subscriptionTransaction:
                transaction.productID == Self.plusProductID
                && transaction.revocationDate == nil
                && (transaction.expirationDate.map { $0 > Date() } ?? true)
                ? transaction : nil
        )
        purchaseState =
            transaction.revocationDate == nil
            ? .purchased
            : .idle
        await transaction.finish()
    }

    private var unavailableStoreState:
        MemoMarkPurchaseState {
        .failed(
            localized(
                "commerce.error.store_unavailable",
                fallback: "暂时无法连接 App Store，请稍后重试。"
            )
        )
    }

    private func loadProduct() async -> Product? {
        do {
#if DEBUG
            print("MemoMark.StoreKit: requesting product")
#endif
            let product = try await productLoader(
                [Self.plusProductID]
            ).first

            guard let product else {
                commerceLogger.error(
                    "StoreKit returned no MemoMark+ product."
                )
#if DEBUG
                print("MemoMark.StoreKit: product request returned no product")
#endif
                return nil
            }

#if DEBUG
            print("MemoMark.StoreKit: configured product loaded")
#endif
            return product
        } catch {
            commerceLogger.error(
                "StoreKit product request failed: \(error.localizedDescription, privacy: .private(mask: .hash))"
            )
#if DEBUG
            print("MemoMark.StoreKit: product request failed")
#endif
            return nil
        }
    }

    private func resolvedEnvironment() async
    -> MemoMarkCommerceEnvironment {
        let verifiedEnvironment:
            MemoMarkCommerceEnvironment?

        do {
            switch try await AppTransaction.shared {
            case .verified(let transaction):
                verifiedEnvironment = commerceEnvironment(
                    transaction.environment
                )
            case .unverified:
                verifiedEnvironment = nil
            }
        } catch {
            verifiedEnvironment = nil
        }

        return MemoMarkCommerceEnvironment
            .resolved(verified: verifiedEnvironment)
    }

    private func commerceEnvironment(
        _ environment:
            AppStore.Environment
    ) -> MemoMarkCommerceEnvironment {
        switch environment {
        case .production:
            return .production
        case .sandbox:
            return .sandbox
        case .xcode:
            return .xcode
        default:
            return .production
        }
    }

    private func publishSnapshot(
        environment:
            MemoMarkCommerceEnvironment,
        lifetimeTransaction: Transaction?,
        subscriptionTransaction: Transaction?
    ) {
        if snapshot.environment == environment,
           let existingDate =
                snapshot.firstRecorderDate {
            persistence
                .grantFirstRecorderIdentityIfNeeded(
                    date: existingDate,
                    environment: environment
                )
        }

        if let lifetimeTransaction,
           MemoMarkCommercePolicy
            .shouldGrantFirstRecorderIdentity(
                originalPurchaseDate:
                    lifetimeTransaction
                    .originalPurchaseDate,
                campaignEndDate:
                    MemoMarkCommercePolicy
                    .firstRecorderCampaignEndDate,
                isFamilyShared:
                    lifetimeTransaction.ownershipType
                    == .familyShared
            ) {
            persistence
                .grantFirstRecorderIdentityIfNeeded(
                    date:
                        lifetimeTransaction
                        .originalPurchaseDate,
                    environment: environment
                )
        }

        let isTestFlightExperienceActive =
            lifetimeTransaction == nil
            && subscriptionTransaction == nil
            && persistence
                .isTestFlightExperienceActive(
                    environment: environment
                )
        let isPlus =
            lifetimeTransaction != nil
            || subscriptionTransaction != nil
            || isTestFlightExperienceActive
        let accessSource:
            MemoMarkCommerceAccessSource =
            lifetimeTransaction != nil
            ? .founderLifetime
            : subscriptionTransaction != nil
            ? .plusSubscription
            : isTestFlightExperienceActive
                ? .testFlightTemporary
                : .free
        let bonus =
            persistence.bonusAllowance(
                environment: environment
            )
        let policy =
            isPlus
            ? MemoMarkCommercePolicy.plus
            : MemoMarkCommercePolicy.resolved(
                for: environment,
                bonusAllowance: bonus
            )
        let nextSnapshot =
            MemoMarkCommerceSnapshot(
                environment: environment,
                accessSource: accessSource,
                successfulRecordCount:
                    persistence
                    .successfulRecordCount(
                        environment: environment
                    ),
                totalAllowance:
                    policy.totalAllowance,
                batchLimit:
                    policy.batchLimit,
                firstRecorderDate:
                    persistence
                    .firstRecorderDate(
                        environment: environment
                    ),
                validThrough:
                    subscriptionTransaction?.expirationDate,
                lastVerifiedAt: Date(),
                updatedAt: Date()
            )

        guard persistence.saveSharedSnapshot(nextSnapshot) else {
            commerceLogger.error(
                "shared commerce snapshot read-back failed; retaining the previous in-memory snapshot"
            )
            return
        }
        snapshot = nextSnapshot
    }

    private func localized(
        _ key: String,
        fallback: String
    ) -> String {
        MemoMarkLanguage.interfaceStored
            .localized(
                key: key,
                fallback: fallback
            )
    }
}

private let commerceLogger = Logger(
    subsystem: "com.serydoo.PhotoMemo",
    category: "commerce"
)
#endif
