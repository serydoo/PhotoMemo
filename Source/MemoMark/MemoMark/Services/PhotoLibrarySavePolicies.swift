import Foundation

enum PhotoLibrarySaveReceiptReconciliationDecision:
    Equatable {

    case reuseAsset
    case awaitVisibility
}

struct PhotoLibrarySaveReceiptReconciliationPolicy {

    func decision(
        assetExists: Bool,
        recordedAt: Date?
    ) -> PhotoLibrarySaveReceiptReconciliationDecision {

        if assetExists {
            return .reuseAsset
        }

        // A missing fetch result does not prove that PhotoKit failed to
        // commit. Permission and visibility can change independently.
        _ = recordedAt
        return .awaitVisibility
    }
}

/// Keeps the static-output completion boundary aligned with the export commit
/// protocol: a successful PhotoKit callback establishes a submitted receipt,
/// but the queue may report completion only after direct lookup finds that
/// exact asset identifier. A missing lookup remains an ambiguous visibility
/// state and must reuse the durable receipt rather than issue another write.
enum PhotoLibraryStaticSaveReadbackDecision: Equatable {

    case complete
    case awaitVisibility
}

struct PhotoLibraryStaticSaveReadbackPolicy {

    func decision(
        assetExists: Bool
    ) -> PhotoLibraryStaticSaveReadbackDecision {
        assetExists ? .complete : .awaitVisibility
    }
}

enum PhotoLibrarySaveTransactionFailureDecision:
    Equatable {

    case retrySave
    case recoverExistingAsset
    case awaitReadback
}

struct PhotoLibrarySaveTransactionFailurePolicy {

    func decision(
        assetExists: Bool
    ) -> PhotoLibrarySaveTransactionFailureDecision {
        assetExists
            ? .recoverExistingAsset
            : .retrySave
    }
}

/// Defines when an ambiguous PhotoKit completion may become a user-visible
/// success. A visible asset is not sufficient for idempotent work: its durable
/// receipt must also acknowledge the commit, otherwise a future retry cannot
/// prove it will not create a duplicate.
struct PhotoLibraryAmbiguousCommitRecoveryPolicy {

    enum Resolution: Equatable {

        case reportRecoveredAsset
        case awaitReadback
        case rethrowFailure
    }

    func resolution(
        decision: PhotoLibrarySaveTransactionFailureDecision,
        wasCancelled: Bool,
        idempotencyKey: String?,
        receipt: PhotoLibrarySaveReceipt?
    ) -> Resolution {
        guard !wasCancelled else {
            return .rethrowFailure
        }
        if decision == .awaitReadback {
            return .awaitReadback
        }
        guard decision == .recoverExistingAsset else {
            return .rethrowFailure
        }
        guard idempotencyKey != nil else {
            return .reportRecoveredAsset
        }
        return receipt?.phase == .commitAcknowledged
            ? .reportRecoveredAsset
            : .awaitReadback
    }
}
