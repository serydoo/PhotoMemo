import Foundation
import Photos

enum PhotoLibrarySaveTransactionRecovery {

    static func resolve(
        idempotencyKey: String?,
        placeholderIdentifier: String?,
        assetExists: Bool,
        receiptLedger: PhotoLibrarySaveReceiptLedger
    ) async -> PhotoLibrarySaveTransactionFailureDecision {
        let decision = PhotoLibrarySaveTransactionFailurePolicy()
            .decision(assetExists: assetExists)

        guard let idempotencyKey else {
            return decision
        }

        switch decision {
        case .retrySave:
            let pendingAssetIdentifier =
                await receiptLedger.pendingAssetIdentifier(
                    for: idempotencyKey
                )
            let knownPlaceholderIdentifier =
                placeholderIdentifier ?? pendingAssetIdentifier

            // Once PhotoKit has supplied a placeholder, an immediately
            // invisible asset is still an ambiguous external outcome. Keep
            // the exact identifier and submitted receipt so a later retry can
            // reconcile the same asset instead of creating a duplicate.
            if let knownPlaceholderIdentifier {
                if await receiptLedger.assetIdentifier(
                    for: idempotencyKey
                ) == nil {
                    if !(await receiptLedger.materializePendingIntent(
                        for: idempotencyKey
                    )) {
                        _ = await receiptLedger.record(
                            assetIdentifier: knownPlaceholderIdentifier,
                            for: idempotencyKey
                        )
                    }
                }
                return .awaitReadback
            }

            await receiptLedger.removeReceipt(
                for: idempotencyKey
            )

        case .recoverExistingAsset:
            if await receiptLedger.assetIdentifier(
                for: idempotencyKey
            ) == nil {
                if !(await receiptLedger.materializePendingIntent(
                    for: idempotencyKey
                )), let placeholderIdentifier {
                    _ = await receiptLedger.record(
                        assetIdentifier: placeholderIdentifier,
                        for: idempotencyKey
                    )
                }
            }
            _ = await receiptLedger.ensureCommitted(
                for: idempotencyKey
            )

        case .awaitReadback:
            break
        }

        return decision
    }

}

enum PhotoLibrarySaveReceiptPhase:
    String,
    Codable,
    Equatable,
    Sendable {

    case transactionSubmitted
    case commitAcknowledged
}

struct PhotoLibrarySaveReceipt:
    Codable,
    Equatable,
    Sendable {

    let assetIdentifier: String
    let recordedAt: Date?
    let phase: PhotoLibrarySaveReceiptPhase
}

struct PhotoLibrarySaveIntent:
    Codable,
    Equatable,
    Sendable {

    let startedAt: Date
    let assetIdentifier: String?
}

protocol PhotoLibraryReceiptAssetLocating {

    /// Reports whether PhotoKit can currently perform the exact receipt
    /// readback. A denied state is distinct from an asset that is merely not
    /// visible yet: neither authorizes a replacement save, but only the
    /// former needs an actionable permission recovery state.
    func isReadbackAuthorized() -> Bool

    func visibleAssetIdentifier(
        for idempotencyKey: String,
        recordedAssetIdentifier: String?,
        pendingAssetIdentifier: String?
    ) -> String?
}

extension PhotoLibraryReceiptAssetLocating {

    func isReadbackAuthorized() -> Bool {
        true
    }
}

struct PhotoLibrarySaveReceiptAssetLocator:
    PhotoLibraryReceiptAssetLocating {

    func isReadbackAuthorized() -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(
            for: .readWrite
        )
        return status == .authorized
            || status == .limited
    }

    func visibleAssetIdentifier(
        for idempotencyKey: String,
        recordedAssetIdentifier: String?,
        pendingAssetIdentifier: String?
    ) -> String? {
        _ = idempotencyKey
        guard let recordedIdentifier =
                recordedAssetIdentifier
                ?? pendingAssetIdentifier else {
            return nil
        }

        return PHAsset.fetchAssets(
            withLocalIdentifiers: [recordedIdentifier],
            options: nil
        )
        .firstObject?
        .localIdentifier
    }
}

nonisolated final class PhotoLibrarySaveReceiptStore:
    @unchecked Sendable {

    private struct StoredReceipt: Codable {

        let assetIdentifier: String
        let recordedAt: Date?
        let phase: PhotoLibrarySaveReceiptPhase

        init(
            assetIdentifier: String,
            recordedAt: Date?,
            phase: PhotoLibrarySaveReceiptPhase
        ) {
            self.assetIdentifier = assetIdentifier
            self.recordedAt = recordedAt
            self.phase = phase
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(
                keyedBy: CodingKeys.self
            )
            assetIdentifier = try container.decode(
                String.self,
                forKey: .assetIdentifier
            )
            recordedAt = try container.decodeIfPresent(
                Date.self,
                forKey: .recordedAt
            )
            phase = try container.decodeIfPresent(
                PhotoLibrarySaveReceiptPhase.self,
                forKey: .phase
            ) ?? .transactionSubmitted
        }

        private enum CodingKeys: String, CodingKey {
            case assetIdentifier
            case recordedAt
            case phase
        }
    }

    private struct StoredIntent: Codable {

        let startedAt: Date
        let assetIdentifier: String?

        init(
            startedAt: Date,
            assetIdentifier: String? = nil
        ) {
            self.startedAt = startedAt
            self.assetIdentifier = assetIdentifier
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(
                keyedBy: CodingKeys.self
            )
            startedAt = try container.decode(
                Date.self,
                forKey: .startedAt
            )
            assetIdentifier = try container.decodeIfPresent(
                String.self,
                forKey: .assetIdentifier
            )
        }

        private enum CodingKeys: String, CodingKey {

            case startedAt
            case assetIdentifier
        }
    }

    private let defaults: UserDefaults
    private let receiptDataWriter:
        (Data, String, UserDefaults) -> Void
    private let synchronize: () -> Bool
    private static let persistenceLock = NSLock()
    private let receiptSchemaV1KeyPrefix =
        "photomemo.photoLibrarySaveReceipt.v1"
    private let intentSchemaV1KeyPrefix =
        "photomemo.photoLibrarySaveIntent.v1"

    init(
        defaults: UserDefaults =
            MemoMarkSharedContainer
            .sharedUserDefaults,
        receiptDataWriter:
            ((Data, String, UserDefaults) -> Void)? = nil,
        synchronize: (() -> Bool)? = nil
    ) {
        self.defaults = defaults
        self.receiptDataWriter =
            receiptDataWriter
            ?? { data, key, defaults in
                defaults.set(data, forKey: key)
            }
        self.synchronize =
            synchronize
            ?? { defaults.synchronize() }
    }

    func assetIdentifier(
        for idempotencyKey: String
    ) -> String? {
        guard let key = storageKey(
            for: idempotencyKey
        ) else {
            return nil
        }

        return Self.persistenceLock.withLock {
            storedReceipt(forStorageKey: key)?
                .assetIdentifier
        }
    }

    func recordedAt(
        for idempotencyKey: String
    ) -> Date? {
        guard let key = storageKey(
            for: idempotencyKey
        ) else {
            return nil
        }

        return Self.persistenceLock.withLock {
            storedReceipt(forStorageKey: key)?
                .recordedAt
        }
    }

    func receipt(
        for idempotencyKey: String
    ) -> PhotoLibrarySaveReceipt? {
        guard let key = storageKey(
            for: idempotencyKey
        ) else {
            return nil
        }

        return Self.persistenceLock.withLock {
            guard let storedReceipt = storedReceipt(
                forStorageKey: key
            ) else {
                return nil
            }

            return PhotoLibrarySaveReceipt(
                assetIdentifier:
                    storedReceipt.assetIdentifier,
                recordedAt:
                    storedReceipt.recordedAt,
                phase:
                    storedReceipt.phase
            )
        }
    }

    func hasPendingIntent(
        for idempotencyKey: String
    ) -> Bool {
        guard let key = intentStorageKey(
            for: idempotencyKey
        ) else {
            return false
        }

        return Self.persistenceLock.withLock {
            defaults.object(forKey: key) != nil
        }
    }

    func intent(
        for idempotencyKey: String
    ) -> PhotoLibrarySaveIntent? {
        guard let key = intentStorageKey(
            for: idempotencyKey
        ) else {
            return nil
        }

        return Self.persistenceLock.withLock {
            guard let storedIntent = storedIntent(
                forStorageKey: key
            ) else {
                return nil
            }

            return PhotoLibrarySaveIntent(
                startedAt: storedIntent.startedAt,
                assetIdentifier:
                    storedIntent.assetIdentifier
            )
        }
    }

    func pendingAssetIdentifier(
        for idempotencyKey: String
    ) -> String? {
        intent(for: idempotencyKey)?.assetIdentifier
    }

    @discardableResult
    func recordIntent(
        for idempotencyKey: String
    ) -> Bool {
        guard let key = storageKey(
            for: idempotencyKey
        ),
        let intentKey = intentStorageKey(
            for: idempotencyKey
        ),
        let encodedIntent = try? JSONEncoder()
            .encode(
                StoredIntent(
                    startedAt: Date()
                )
            ) else {
            return false
        }

        return Self.persistenceLock.withLock {
            guard storedReceipt(
                forStorageKey: key
            ) == nil,
            defaults.object(forKey: intentKey) == nil else {
                return false
            }

            return writeAndVerify(
                encodedIntent,
                forKey: intentKey
            )
        }
    }

    @discardableResult
    func recordIntentAssetIdentifier(
        _ assetIdentifier: String,
        for idempotencyKey: String
    ) -> Bool {
        let normalizedIdentifier =
            assetIdentifier
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        guard !normalizedIdentifier.isEmpty,
              let intentKey = intentStorageKey(
                  for: idempotencyKey
              ) else {
            return false
        }

        return Self.persistenceLock.withLock {
            guard let existingIntent = storedIntent(
                forStorageKey: intentKey
            ) else {
                return false
            }

            let updatedIntent = StoredIntent(
                startedAt: existingIntent.startedAt,
                assetIdentifier: normalizedIdentifier
            )
            guard let encodedIntent = try? JSONEncoder()
                .encode(updatedIntent) else {
                return false
            }

            return writeAndVerify(
                encodedIntent,
                forKey: intentKey
            )
        }
    }

    func removeIntent(
        for idempotencyKey: String
    ) {
        guard let intentKey = intentStorageKey(
            for: idempotencyKey
        ) else {
            return
        }

        Self.persistenceLock.withLock {
            removeIntent(forStorageKey: intentKey)
        }
    }

    @discardableResult
    func markCommitted(
        for idempotencyKey: String
    ) -> Bool {
        guard let key = storageKey(
            for: idempotencyKey
        ) else {
            return false
        }

        return Self.persistenceLock.withLock {
            guard let existingReceipt = storedReceipt(
                forStorageKey: key
            ) else {
                return false
            }

            let committedReceipt = StoredReceipt(
                assetIdentifier:
                    existingReceipt.assetIdentifier,
                recordedAt:
                    existingReceipt.recordedAt,
                phase:
                    .commitAcknowledged
            )
            guard let encodedReceipt = try? JSONEncoder()
                .encode(committedReceipt) else {
                return false
            }

            guard writeAndVerify(
                encodedReceipt,
                forKey: key
            ) else {
                return false
            }
            defaults.removeObject(
                forKey:
                    timestampStorageKey(
                        forStorageKey: key
                    )
            )
            removeIntent(
                forStorageKey:
                    intentStorageKey(
                        forStorageKey: key
                    )
            )
            _ = synchronize()

            return defaults.data(forKey: key)
                == encodedReceipt
        }
    }

    @discardableResult
    func ensureCommitted(
        for idempotencyKey: String
    ) -> Bool {
        guard let receipt = receipt(
            for: idempotencyKey
        ) else {
            return false
        }

        guard receipt.phase
                != .commitAcknowledged else {
            return true
        }

        return markCommitted(
            for: idempotencyKey
        )
    }

    @discardableResult
    func materializePendingIntent(
        for idempotencyKey: String
    ) -> Bool {
        guard assetIdentifier(for: idempotencyKey) == nil else {
            return true
        }
        guard let pendingIdentifier = pendingAssetIdentifier(
            for: idempotencyKey
        ) else {
            return false
        }

        return record(
            assetIdentifier: pendingIdentifier,
            for: idempotencyKey
        )
    }

    @discardableResult
    func record(
        assetIdentifier: String,
        for idempotencyKey: String
    ) -> Bool {
        let normalizedIdentifier =
            assetIdentifier
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        guard !normalizedIdentifier.isEmpty,
              let key = storageKey(
                  for: idempotencyKey
              ) else {
            return false
        }

        let receipt = StoredReceipt(
            assetIdentifier: normalizedIdentifier,
            recordedAt: Date(),
            phase: .transactionSubmitted
        )
        guard let encodedReceipt = try? JSONEncoder()
            .encode(receipt) else {
            return false
        }

        return Self.persistenceLock.withLock {
            guard writeAndVerify(
                encodedReceipt,
                forKey: key
            ) else {
                return false
            }
            defaults.removeObject(
                forKey:
                    timestampStorageKey(
                        forStorageKey: key
                    )
            )
            removeIntent(
                forStorageKey:
                    intentStorageKey(
                        forStorageKey: key
                    )
            )
            _ = synchronize()
            return true
        }
    }

    func removeReceipt(
        for idempotencyKey: String
    ) {
        guard let key = storageKey(
            for: idempotencyKey
        ) else {
            return
        }

        Self.persistenceLock.withLock {
            defaults.removeObject(forKey: key)
            defaults.removeObject(
                forKey:
                    timestampStorageKey(
                        forStorageKey: key
                    )
            )
            removeIntent(
                forStorageKey:
                    intentStorageKey(
                        forStorageKey: key
                    )
            )
            _ = synchronize()
        }
    }

    func removeReceipts(
        for idempotencyKeys: Set<String>
    ) {
        let keys = idempotencyKeys.compactMap {
            storageKey(for: $0)
        }

        Self.persistenceLock.withLock {
            for key in keys {
                defaults.removeObject(forKey: key)
                defaults.removeObject(
                    forKey:
                        timestampStorageKey(
                            forStorageKey: key
                        )
                )
                removeIntent(
                    forStorageKey:
                        intentStorageKey(
                            forStorageKey: key
                        )
                )
            }
            _ = synchronize()
        }
    }

    func pruneReceipts(
        retaining idempotencyKeys: Set<String>
    ) {
        let retainedStorageKeys = Set(
            idempotencyKeys
                .compactMap {
                    storageKey(for: $0)
                }
        )
        let retainedIntentStorageKeys = Set(
            idempotencyKeys
                .compactMap {
                    intentStorageKey(for: $0)
                }
        )

        Self.persistenceLock.withLock {
            for key in retainedStorageKeys {
                migrateLegacyReceiptIfNeeded(
                    forStorageKey: key
                )
            }

            let staleStorageKeys = defaults
                .dictionaryRepresentation()
                .keys
                .filter {
                    (
                        $0.hasPrefix(receiptSchemaV1KeyPrefix + ".")
                        || $0.hasPrefix(intentSchemaV1KeyPrefix + ".")
                    )
                    && (
                        $0.hasSuffix(".recordedAt")
                        || (
                            !$0.hasPrefix(intentSchemaV1KeyPrefix + ".")
                            && !retainedStorageKeys.contains($0)
                        )
                        || (
                            $0.hasPrefix(intentSchemaV1KeyPrefix + ".")
                            && !retainedIntentStorageKeys.contains($0)
                        )
                    )
                }

            for key in staleStorageKeys {
                defaults.removeObject(forKey: key)
            }
            _ = synchronize()
        }
    }

    private func storageKey(
        for idempotencyKey: String
    ) -> String? {
        let normalizedKey =
            idempotencyKey
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .replacingOccurrences(
                of: "/",
                with: "-"
            )
        guard !normalizedKey.isEmpty else {
            return nil
        }

        return "\(receiptSchemaV1KeyPrefix).\(normalizedKey)"
    }

    private func timestampStorageKey(
        forStorageKey storageKey: String
    ) -> String {
        "\(storageKey).recordedAt"
    }

    private func intentStorageKey(
        for idempotencyKey: String
    ) -> String? {
        let normalizedKey =
            idempotencyKey
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .replacingOccurrences(
                of: "/",
                with: "-"
            )
        guard !normalizedKey.isEmpty else {
            return nil
        }

        return "\(intentSchemaV1KeyPrefix).\(normalizedKey)"
    }

    private func intentStorageKey(
        forStorageKey storageKey: String
    ) -> String {
        let suffix = storageKey
            .dropFirst((receiptSchemaV1KeyPrefix + ".").count)
        return "\(intentSchemaV1KeyPrefix).\(suffix)"
    }

    private func storedReceipt(
        forStorageKey storageKey: String
    ) -> StoredReceipt? {
        if let data = defaults.data(forKey: storageKey),
           let receipt = try? JSONDecoder()
            .decode(StoredReceipt.self, from: data) {
            return receipt
        }

        guard let legacyIdentifier = defaults
            .string(forKey: storageKey) else {
            return nil
        }

        return StoredReceipt(
            assetIdentifier: legacyIdentifier,
            recordedAt:
                defaults.object(
                    forKey:
                        timestampStorageKey(
                        forStorageKey: storageKey
                    )
                ) as? Date,
            phase: .transactionSubmitted
        )
    }

    private func storedIntent(
        forStorageKey storageKey: String
    ) -> StoredIntent? {
        guard let data = defaults.data(
            forKey: storageKey
        ) else {
            return nil
        }

        return try? JSONDecoder()
            .decode(
                StoredIntent.self,
                from: data
            )
    }

    private func removeIntent(
        forStorageKey storageKey: String
    ) {
        defaults.removeObject(forKey: storageKey)
        _ = synchronize()
    }

    private func writeAndVerify(
        _ data: Data,
        forKey key: String
    ) -> Bool {
        let previousValue = defaults.object(forKey: key)
        receiptDataWriter(data, key, defaults)
        _ = synchronize()

        guard defaults.data(forKey: key) == data else {
            if let previousValue {
                defaults.set(previousValue, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
            _ = synchronize()
            return false
        }

        return true
    }

    private func migrateLegacyReceiptIfNeeded(
        forStorageKey storageKey: String
    ) {
        guard defaults.data(forKey: storageKey) == nil,
              let receipt = storedReceipt(
                forStorageKey: storageKey
              ),
              let encodedReceipt = try? JSONEncoder()
                .encode(receipt) else {
            return
        }

        _ = writeAndVerify(
            encodedReceipt,
            forKey: storageKey
        )
    }
}
