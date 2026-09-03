#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Photo Library ambiguous commit recovery policy")
struct PhotoLibraryAmbiguousCommitRecoveryPolicyTests {

    @Test("idempotent recovery waits for durable commit acknowledgement")
    func idempotentRecoveryRequiresCommitAcknowledgement() {
        let policy = PhotoLibraryAmbiguousCommitRecoveryPolicy()

        #expect(
            policy.resolution(
                decision: .recoverExistingAsset,
                wasCancelled: false,
                idempotencyKey: "job-1/task-1",
                receipt: .init(
                    assetIdentifier: "asset-1",
                    recordedAt: Date(timeIntervalSince1970: 1),
                    phase: .transactionSubmitted
                )
            ) == .awaitReadback
        )
    }

    @Test("recovery reports only confirmed or non-idempotent assets")
    func recoveryReportsOnlyConfirmedOrNonIdempotentAsset() {
        let policy = PhotoLibraryAmbiguousCommitRecoveryPolicy()

        #expect(
            policy.resolution(
                decision: .recoverExistingAsset,
                wasCancelled: false,
                idempotencyKey: "job-1/task-1",
                receipt: .init(
                    assetIdentifier: "asset-1",
                    recordedAt: Date(timeIntervalSince1970: 1),
                    phase: .commitAcknowledged
                )
            ) == .reportRecoveredAsset
        )
        #expect(
            policy.resolution(
                decision: .recoverExistingAsset,
                wasCancelled: false,
                idempotencyKey: nil,
                receipt: nil
            ) == .reportRecoveredAsset
        )
    }

    @Test("retryable and cancelled failures preserve the original error")
    func nonRecoverableFailuresRethrow() {
        let policy = PhotoLibraryAmbiguousCommitRecoveryPolicy()

        #expect(
            policy.resolution(
                decision: .recoverExistingAsset,
                wasCancelled: true,
                idempotencyKey: nil,
                receipt: nil
            ) == .rethrowFailure
        )
        #expect(
            policy.resolution(
                decision: .retrySave,
                wasCancelled: false,
                idempotencyKey: nil,
                receipt: nil
            ) == .rethrowFailure
        )
    }

    @Test("ambiguous visibility keeps a placeholder pending instead of retrying")
    func ambiguousVisibilityWaitsForReadback() {
        let policy = PhotoLibraryAmbiguousCommitRecoveryPolicy()

        #expect(
            policy.resolution(
                decision: .awaitReadback,
                wasCancelled: false,
                idempotencyKey: "job-1/task-2",
                receipt: .init(
                    assetIdentifier: "asset-2",
                    recordedAt: Date(timeIntervalSince1970: 2),
                    phase: .transactionSubmitted
                )
            ) == .awaitReadback
        )
    }
}
#endif
