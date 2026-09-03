#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Collects the factual outcomes of receipt-backed PhotoKit readback during
/// queue resume. It owns neither queue projection nor persistence: the queue
/// facade applies these commands through its durable ledger.
@MainActor
struct PhotoLibraryReceiptResumeRecoveryPlanner {

    enum Command: Sendable {

        case complete(
            reference: BatchTaskReference,
            assetIdentifier: String
        )

        case permissionRecoveryRequired(
            reference: BatchTaskReference,
            failure: BatchTaskFailure
        )
    }

    private let receiptLedger: PhotoLibrarySaveReceiptLedger

    private let assetLocator: any PhotoLibraryReceiptAssetLocating

    init(
        receiptLedger: PhotoLibrarySaveReceiptLedger,
        assetLocator: any PhotoLibraryReceiptAssetLocating
    ) {
        self.receiptLedger = receiptLedger
        self.assetLocator = assetLocator
    }

    func commands(
        for jobs: [BatchJob]
    ) async -> [Command] {
        var commands: [Command] = []

        for job in jobs {
            for task in job.tasks
            where task.phase == .savingToPhotoLibrary {
                let idempotencyKey = task.id.uuidString
                let reference = BatchTaskReference(
                    jobID: job.id,
                    taskID: task.id
                )

                guard assetLocator.isReadbackAuthorized() else {
                    // Access loss makes exact receipt-backed lookup
                    // inconclusive, not negative-commit proof. Keep the
                    // receipt and let the queue publish an actionable retry.
                    commands.append(
                        .permissionRecoveryRequired(
                            reference: reference,
                            failure: permissionFailure(for: task)
                        )
                    )
                    continue
                }

                let recordedAssetIdentifier =
                    await receiptLedger.assetIdentifier(
                        for: idempotencyKey
                    )
                let pendingAssetIdentifier =
                    await receiptLedger.pendingAssetIdentifier(
                        for: idempotencyKey
                    )
                guard let assetIdentifier =
                        assetLocator.visibleAssetIdentifier(
                            for: idempotencyKey,
                            recordedAssetIdentifier:
                                recordedAssetIdentifier,
                            pendingAssetIdentifier:
                                pendingAssetIdentifier
                        ) else {
                    continue
                }
                if recordedAssetIdentifier == nil,
                   !(await receiptLedger.materializePendingIntent(
                    for: idempotencyKey
                   )) {
                    continue
                }
                guard await receiptLedger.ensureCommitted(
                    for: idempotencyKey
                ) else {
                    continue
                }
                commands.append(
                    .complete(
                        reference: reference,
                        assetIdentifier: assetIdentifier
                    )
                )
            }
        }

        return commands
    }

    private func permissionFailure(
        for task: BatchTask
    ) -> BatchTaskFailure {
        let diagnosticFailure =
            ProductionDiagnosticFailureClassifier.processing(
                phase: task.phase.rawValue,
                classification:
                    BatchTaskFailure.Classification
                    .processingFailure
                    .rawValue,
                operationID: task.id,
                error: PhotoLibraryExportError.unauthorized,
                language: .interfaceStored
            )
        return BatchTaskFailure(
            phase: task.phase,
            message: diagnosticFailure.userMessage,
            classification: .processingFailure,
            canRetry: BatchTaskFailurePolicy
                .canRetryTaskAfterFailure(
                    sourceURL: task.sourceURL
                ),
            diagnosticCode: diagnosticFailure.code.rawValue,
            supportID: diagnosticFailure.supportID
        )
    }
}
#endif
