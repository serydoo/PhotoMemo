#if !PHOTOMEMO_SHARE_EXTENSION
import Combine
import Foundation
import StoreKit
#if os(iOS)
import UIKit
#endif

@MainActor
final class MemoMarkCommerceStore:
    ObservableObject {

    static let plusProductID =
        "com.serydoo.PhotoMemo.iOS.memomarkplus.lifetime"

    @Published private(set) var product: Product?
    @Published private(set) var purchaseState:
        MemoMarkPurchaseState = .idle
    @Published private(set) var snapshot:
        MemoMarkCommerceSnapshot

    private let persistence:
        MemoMarkCommercePersistence
    private var transactionListener:
        Task<Void, Never>?

    init(
        persistence:
            MemoMarkCommercePersistence =
                MemoMarkCommercePersistence()
    ) {
        self.persistence = persistence
        self.snapshot =
            persistence.loadSharedSnapshot()
    }

    deinit {
        transactionListener?.cancel()
    }

    var isPlus: Bool {
        snapshot.isPlus
    }

    var displayPrice: String {
        product?.displayPrice ?? "—"
    }

    var remainingRecords: Int? {
        snapshot.remainingRecords
    }

    var environment:
        MemoMarkCommerceEnvironment {
        snapshot.environment
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
        purchaseState = .loading

        let environment =
            await resolvedEnvironment()

        do {
            product = try await Product.products(
                for: [Self.plusProductID]
            ).first
        } catch {
            product = nil
        }

        var plusTransaction: Transaction?

        for await result in
            Transaction.currentEntitlements {
            guard case .verified(let transaction) =
                    result,
                  transaction.productID
                    == Self.plusProductID,
                  transaction.revocationDate == nil else {
                continue
            }
            plusTransaction = transaction
            break
        }

        publishSnapshot(
            environment: environment,
            plusTransaction: plusTransaction
        )
        purchaseState =
            plusTransaction == nil
            ? .idle
            : .purchased
    }

    func purchasePlus() async {
        guard let product else {
            purchaseState =
                .failed(
                    "暂时无法连接 App Store，请稍后重试。"
                )
            return
        }

        purchaseState = .purchasing

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                await handleTransactionResult(
                    verification
                )
            case .pending:
                purchaseState = .pending
            case .userCancelled:
                purchaseState = .cancelled
            @unknown default:
                purchaseState =
                    .failed(
                        "购买状态暂时无法确认，请稍后恢复购买。"
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

#if os(iOS)
    func redeemOfferCode() async {
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
                    "暂时无法打开兑换页面，请稍后重试。"
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
            plusTransaction: nil
        )
    }

    func applyMajorVersionGiftIfNeeded(
        marketingVersion: String
    ) {
        guard !snapshot.isPlus,
              let major = Int(
                marketingVersion
                    .split(separator: ".")
                    .first ?? ""
              ),
              major >= 2 else {
            return
        }

        guard persistence.applyAllowanceGift(
            id: "major-\(major)",
            amount: 50,
            environment: snapshot.environment
        ) else {
            return
        }

        publishSnapshot(
            environment: snapshot.environment,
            plusTransaction: nil
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
                    "App Store 无法验证这笔交易。"
                )
            return
        }

        guard transaction.productID
                == Self.plusProductID else {
            await transaction.finish()
            return
        }

        let environment =
            commerceEnvironment(
                transaction.environment
            )
        publishSnapshot(
            environment: environment,
            plusTransaction:
                transaction.revocationDate == nil
                ? transaction
                : nil
        )
        purchaseState =
            transaction.revocationDate == nil
            ? .purchased
            : .idle
        await transaction.finish()
    }

    private func resolvedEnvironment() async
    -> MemoMarkCommerceEnvironment {
        do {
            switch try await AppTransaction.shared {
            case .verified(let transaction):
                return commerceEnvironment(
                    transaction.environment
                )
            case .unverified:
                return snapshot.environment
            }
        } catch {
            return snapshot.environment
        }
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
            return .sandbox
        }
    }

    private func publishSnapshot(
        environment:
            MemoMarkCommerceEnvironment,
        plusTransaction: Transaction?
    ) {
        let isPlus = plusTransaction != nil
        let bonus =
            persistence.bonusAllowance(
                environment: environment
            )
        let policy =
            isPlus
            ? MemoMarkCommercePolicy.plus
            : MemoMarkCommercePolicy.free(
                bonusAllowance: bonus
            )
        let nextSnapshot =
            MemoMarkCommerceSnapshot(
                environment: environment,
                isPlus: isPlus,
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
                    plusTransaction?
                    .originalPurchaseDate,
                updatedAt: Date()
            )

        snapshot = nextSnapshot
        persistence.saveSharedSnapshot(
            nextSnapshot
        )
    }
}
#endif
