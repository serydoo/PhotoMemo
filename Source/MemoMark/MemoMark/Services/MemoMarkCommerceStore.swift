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

    static let annualProductID =
        MemoMarkSubscriptionPeriod.annual.productID
    static let monthlyProductID =
        MemoMarkSubscriptionPeriod.monthly.productID
    static let subscriptionProductIDs =
        MemoMarkSubscriptionPeriod.allCases.map(\.productID)
    // The annual StoreKit identifier remains
    // `memomarkplus.subscription.annual`; keep that contract explicit while
    // the period model owns the actual string.
    /// Compatibility name for callers that only knew the annual product.
    static let plusProductID = annualProductID
    static let legacyLifetimeProductID =
        "com.serydoo.PhotoMemo.iOS.memomarkplus.lifetime"

    @Published private(set) var products:
        [String: Product] = [:]
    @Published private(set) var selectedSubscriptionPeriod:
        MemoMarkSubscriptionPeriod = .annual
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
        selectedSubscriptionProduct?.displayPrice ?? "—"
    }

    func displayPrice(
        for period: MemoMarkSubscriptionPeriod
    ) -> String {
        products[period.productID]?.displayPrice ?? "—"
    }

    var availableSubscriptionPeriods:
        [MemoMarkSubscriptionPeriod] {
        MemoMarkSubscriptionPeriod.allCases.filter {
            products[$0.productID] != nil
        }
    }

    var selectedSubscriptionProduct: Product? {
        products[selectedSubscriptionPeriod.productID]
    }

    /// Compatibility projection for callers that previously exposed one
    /// selected Plus product before annual/monthly subscriptions were split.
    var product: Product? {
        selectedSubscriptionProduct
    }

    func selectSubscriptionPeriod(
        _ period: MemoMarkSubscriptionPeriod
    ) {
        selectedSubscriptionPeriod = period
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
        await refresh(preservingHistoricalActivationGrant: true)
    }

    private func refresh(
        preservingHistoricalActivationGrant: Bool
    ) async {
        purchaseState = .restoring

        let environment =
            await resolvedEnvironment()

        products = await loadProducts()
        selectAvailableSubscriptionPeriodIfNeeded()

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
            } else if Self.subscriptionProductIDs.contains(
                        transaction.productID
                      ),
                      transaction.expirationDate.map({ $0 > Date() }) ?? true {
                subscriptionTransaction = transaction
            }
        }

        if let subscriptionTransaction,
           let period = MemoMarkSubscriptionPeriod.allCases.first(
               where: { $0.productID == subscriptionTransaction.productID }
           ) {
            selectedSubscriptionPeriod = period
        }

        publishSnapshot(
            environment: environment,
            lifetimeTransaction: lifetimeTransaction,
            subscriptionTransaction: subscriptionTransaction,
            preservingHistoricalActivationGrant:
                preservingHistoricalActivationGrant
        )
        if lifetimeTransaction != nil || subscriptionTransaction != nil {
            purchaseState = .purchased
        } else if !products.isEmpty {
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

        if let selectedSubscriptionProduct {
            productToPurchase = selectedSubscriptionProduct
        } else {
            purchaseState = .loading

            let loadedProducts = await loadProducts()
            products = loadedProducts
            selectAvailableSubscriptionPeriodIfNeeded()

            guard let loadedProduct = loadedProducts[
                selectedSubscriptionPeriod.productID
            ] else {
                purchaseState = unavailableStoreState
                return
            }

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

        guard Self.subscriptionProductIDs.contains(transaction.productID)
                || transaction.productID == Self.legacyLifetimeProductID else {
            return
        }

        await transaction.finish()

        // A transaction update is only an invalidation signal. Resolve the
        // complete current-entitlements set again so a monthly/annual event
        // can never overwrite a historical lifetime or activation grant.
        await refresh(
            preservingHistoricalActivationGrant: true
        )
        purchaseState =
            transaction.revocationDate == nil
            ? .purchased
            : .idle
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

    private func loadProducts() async -> [String: Product] {
        do {
#if DEBUG
            print("MemoMark.StoreKit: requesting product")
#endif
            let loadedProducts = try await productLoader(
                Self.subscriptionProductIDs
            )
            let products = Dictionary(
                uniqueKeysWithValues: loadedProducts.map {
                    ($0.id, $0)
                }
            )

            guard !products.isEmpty else {
                commerceLogger.error(
                    "StoreKit returned no MemoMark+ subscription products."
                )
#if DEBUG
                print("MemoMark.StoreKit: product request returned no products")
#endif
                return [:]
            }

#if DEBUG
            print("MemoMark.StoreKit: configured subscription products loaded")
#endif
            return products
        } catch {
            commerceLogger.error(
                "StoreKit product request failed: \(error.localizedDescription, privacy: .private(mask: .hash))"
            )
#if DEBUG
            print("MemoMark.StoreKit: product request failed")
#endif
            return [:]
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
        subscriptionTransaction: Transaction?,
        preservingHistoricalActivationGrant:
            Bool = false
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
        let preservedFounderSource:
            MemoMarkCommerceAccessSource? =
            preservingHistoricalActivationGrant
            && snapshot.hasDurableLegacyActivationGrant
            ? snapshot.accessSource
            : nil
        let isPlus =
            lifetimeTransaction != nil
            || subscriptionTransaction != nil
            || preservedFounderSource != nil
            || isTestFlightExperienceActive
        let accessSource:
            MemoMarkCommerceAccessSource =
            lifetimeTransaction != nil
            ? .founderLifetime
            : preservedFounderSource
            ??
            (subscriptionTransaction != nil
            ? .plusSubscription
            : isTestFlightExperienceActive
                ? .testFlightTemporary
                : .free)
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
                hasDurableLegacyActivationGrant:
                    snapshot.hasDurableLegacyActivationGrant,
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

    private func selectAvailableSubscriptionPeriodIfNeeded() {
        guard products[selectedSubscriptionPeriod.productID] == nil else {
            return
        }

        if let firstAvailablePeriod = MemoMarkSubscriptionPeriod.allCases
            .first(where: { products[$0.productID] != nil }) {
            selectedSubscriptionPeriod = firstAvailablePeriod
        }
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
