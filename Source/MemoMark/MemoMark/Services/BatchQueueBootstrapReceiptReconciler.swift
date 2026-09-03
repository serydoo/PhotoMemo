#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Performs only the synchronous Photo Library receipt work that must happen
/// before the actor-backed queue begins accepting runtime commands. It never
/// projects queue state, persists jobs, records commerce usage, or cleans up
/// resources; those remain the `BatchQueueStore` facade's post-commit duties.
@MainActor
struct BatchQueueBootstrapReceiptReconciler {

    struct Completion: Equatable {

        let reference: BatchTaskReference
        let assetIdentifier: String
    }

    private let saveReceiptStore: PhotoLibrarySaveReceiptStore
    private let assetLocator: any PhotoLibraryReceiptAssetLocating

    init(
        saveReceiptStore: PhotoLibrarySaveReceiptStore,
        assetLocator: any PhotoLibraryReceiptAssetLocating
    ) {
        self.saveReceiptStore = saveReceiptStore
        self.assetLocator = assetLocator
    }

    func reconcileCommittedReceipts(
        in jobs: [BatchJob]
    ) -> [Completion] {

        jobs.flatMap { job in
            job.tasks.compactMap { task in
                guard task.phase == .savingToPhotoLibrary else {
                    return nil
                }

                let idempotencyKey = task.id.uuidString
                let recordedAssetIdentifier =
                    saveReceiptStore.assetIdentifier(
                        for: idempotencyKey
                    )
                let pendingAssetIdentifier =
                    saveReceiptStore.pendingAssetIdentifier(
                        for: idempotencyKey
                    )
                guard let assetIdentifier = assetLocator.visibleAssetIdentifier(
                    for: idempotencyKey,
                    recordedAssetIdentifier: recordedAssetIdentifier,
                    pendingAssetIdentifier: pendingAssetIdentifier
                ) else {
                    return nil
                }

                // A visible asset is not enough to complete the queue task.
                // The exact identity must first become durable, so a later
                // interruption can reconcile rather than save a duplicate.
                if saveReceiptStore.assetIdentifier(
                    for: idempotencyKey
                ) == nil,
                   !saveReceiptStore.materializePendingIntent(
                       for: idempotencyKey
                   ) {
                    return nil
                }
                guard saveReceiptStore.ensureCommitted(
                    for: idempotencyKey
                ) else {
                    return nil
                }

                return Completion(
                    reference: BatchTaskReference(
                        jobID: job.id,
                        taskID: task.id
                    ),
                    assetIdentifier: assetIdentifier
                )
            }
        }
    }

    func pruneReceipts(
        retaining jobs: [BatchJob]
    ) {
        saveReceiptStore.pruneReceipts(
            retaining: Set(
                jobs
                    .flatMap(\.tasks)
                    .map { $0.id.uuidString }
            )
        )
    }

    func unresolvedSavingTaskIDs(
        in jobs: [BatchJob]
    ) -> Set<UUID> {

        Set(
            jobs.flatMap(\.tasks)
                .compactMap { task in
                    guard task.phase == .savingToPhotoLibrary else {
                        return nil
                    }

                    let idempotencyKey = task.id.uuidString
                    guard saveReceiptStore.assetIdentifier(
                        for: idempotencyKey
                    ) != nil
                        || saveReceiptStore.hasPendingIntent(
                            for: idempotencyKey
                        ) else {
                        return nil
                    }
                    return task.id
                }
        )
    }
}
#endif
