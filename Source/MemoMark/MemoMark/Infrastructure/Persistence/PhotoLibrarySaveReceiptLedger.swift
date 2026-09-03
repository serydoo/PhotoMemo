#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// The only synchronous receipt capability exposed to PhotoKit's
/// `performChanges` callback. PhotoKit creates its placeholder identifier
/// inside that non-async closure, and the identifier must be durable before
/// the external transaction can finish. This capability cannot create an
/// intent, materialize a receipt, acknowledge a commit, query state, or remove
/// recovery evidence.
nonisolated struct PhotoLibraryPendingIntentPlaceholderWriter:
    Sendable {

    private let store: PhotoLibrarySaveReceiptStore

    fileprivate init(
        store: PhotoLibrarySaveReceiptStore
    ) {
        self.store = store
    }

    @discardableResult
    func record(
        assetIdentifier: String,
        for idempotencyKey: String
    ) -> Bool {
        store.recordIntentAssetIdentifier(
            assetIdentifier,
            for: idempotencyKey
        )
    }
}

/// Serializes the durable receipt lifecycle shared by static-photo, Live
/// Photo, and queue-recovery transactions while preserving the existing
/// UserDefaults keys and encoded payloads in `PhotoLibrarySaveReceiptStore`.
actor PhotoLibrarySaveReceiptLedger {

    nonisolated static let sharedStore =
        PhotoLibrarySaveReceiptStore()

    nonisolated static let shared =
        PhotoLibrarySaveReceiptLedger(
            store: sharedStore
        )

    private let store: PhotoLibrarySaveReceiptStore

    nonisolated let placeholderIntentWriter:
        PhotoLibraryPendingIntentPlaceholderWriter

    init(
        store: PhotoLibrarySaveReceiptStore =
            PhotoLibrarySaveReceiptStore()
    ) {
        self.store = store
        placeholderIntentWriter =
            PhotoLibraryPendingIntentPlaceholderWriter(
                store: store
            )
    }

    func assetIdentifier(
        for idempotencyKey: String
    ) -> String? {
        store.assetIdentifier(for: idempotencyKey)
    }

    func recordedAt(
        for idempotencyKey: String
    ) -> Date? {
        store.recordedAt(for: idempotencyKey)
    }

    func receipt(
        for idempotencyKey: String
    ) -> PhotoLibrarySaveReceipt? {
        store.receipt(for: idempotencyKey)
    }

    func hasPendingIntent(
        for idempotencyKey: String
    ) -> Bool {
        store.hasPendingIntent(for: idempotencyKey)
    }

    func intent(
        for idempotencyKey: String
    ) -> PhotoLibrarySaveIntent? {
        store.intent(for: idempotencyKey)
    }

    func pendingAssetIdentifier(
        for idempotencyKey: String
    ) -> String? {
        store.pendingAssetIdentifier(
            for: idempotencyKey
        )
    }

    func hasRecoveryEvidence(
        for idempotencyKey: String
    ) -> Bool {
        store.assetIdentifier(
            for: idempotencyKey
        ) != nil
        || store.hasPendingIntent(
            for: idempotencyKey
        )
    }

    @discardableResult
    func recordIntent(
        for idempotencyKey: String
    ) -> Bool {
        store.recordIntent(for: idempotencyKey)
    }

    func removeIntent(
        for idempotencyKey: String
    ) {
        store.removeIntent(for: idempotencyKey)
    }

    @discardableResult
    func record(
        assetIdentifier: String,
        for idempotencyKey: String
    ) -> Bool {
        store.record(
            assetIdentifier: assetIdentifier,
            for: idempotencyKey
        )
    }

    @discardableResult
    func markCommitted(
        for idempotencyKey: String
    ) -> Bool {
        store.markCommitted(for: idempotencyKey)
    }

    @discardableResult
    func ensureCommitted(
        for idempotencyKey: String
    ) -> Bool {
        store.ensureCommitted(for: idempotencyKey)
    }

    @discardableResult
    func materializePendingIntent(
        for idempotencyKey: String
    ) -> Bool {
        store.materializePendingIntent(
            for: idempotencyKey
        )
    }

    func removeReceipt(
        for idempotencyKey: String
    ) {
        store.removeReceipt(for: idempotencyKey)
    }

    func removeReceipts(
        for idempotencyKeys: Set<String>
    ) {
        store.removeReceipts(for: idempotencyKeys)
    }

    func pruneReceipts(
        retaining idempotencyKeys: Set<String>
    ) {
        store.pruneReceipts(
            retaining: idempotencyKeys
        )
    }
}
#endif
