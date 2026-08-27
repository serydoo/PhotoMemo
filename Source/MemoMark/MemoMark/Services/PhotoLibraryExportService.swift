import Foundation
import Photos

enum PhotoLibraryCommitInterruptionTestHook {

    #if DEBUG
    static let launchArgument = "-qaPauseAfterPhotoLibraryCommit"

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(
            launchArgument
        )
    }

    static func pauseIfRequested() async throws {
        guard isEnabled else {
            return
        }

        // This seam exists only for the signed device QA target. It holds the
        // process after PhotoKit has accepted the transaction and before the
        // local commit acknowledgement, allowing the harness to force a real
        // process termination at the TX-001 boundary.
        try await Task.sleep(
            nanoseconds: 120_000_000_000
        )
    }
    #else
    static func pauseIfRequested() async throws {}
    #endif
}

actor PhotoLibrarySaveGate {

    static let shared = PhotoLibrarySaveGate()

    private struct Waiter {

        let id: UUID
        let continuation:
            CheckedContinuation<Void, any Error>
    }

    private var isSaving = false
    private var waiters: [Waiter] = []

    func run<Result>(
        _ operation: () async throws -> Result
    ) async throws -> Result {

        try await acquire()

        do {
            try Task.checkCancellation()
            let result = try await operation()
            release()
            return result
        } catch {
            release()
            throw error
        }
    }

    private func acquire() async throws {
        try Task.checkCancellation()

        guard !isSaving else {
            let waiterID = UUID()
            try await withTaskCancellationHandler(
                operation: {
                    try await withCheckedThrowingContinuation {
                        (continuation:
                            CheckedContinuation<
                                Void,
                                any Error
                            >) in

                        guard !Task.isCancelled else {
                            continuation.resume(
                                throwing:
                                    CancellationError()
                            )
                            return
                        }

                        waiters.append(
                            Waiter(
                                id: waiterID,
                                continuation: continuation
                            )
                        )
                    }
                },
                onCancel: {
                    Task<Void, Never> {
                        await self.cancelWaiter(
                            id: waiterID
                        )
                    }
                }
            )
            return
        }

        isSaving = true
    }

    private func release() {
        guard !waiters.isEmpty else {
            isSaving = false
            return
        }

        let waiter = waiters.removeFirst()
        waiter.continuation.resume()
    }

    private func cancelWaiter(id: UUID) {
        guard let index = waiters.firstIndex(
            where: { $0.id == id }
        ) else {
            return
        }

        let waiter = waiters.remove(at: index)
        waiter.continuation.resume(
            throwing: CancellationError()
        )
    }
}

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

enum PhotoLibrarySaveTransactionFailureDecision:
    Equatable {

    case retrySave
    case recoverExistingAsset
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

enum PhotoLibrarySaveTransactionRecovery {

    static func resolve(
        idempotencyKey: String?,
        placeholderIdentifier: String?,
        assetExists: Bool,
        receiptStore: PhotoLibrarySaveReceiptStore
    ) -> PhotoLibrarySaveTransactionFailureDecision {
        let decision = PhotoLibrarySaveTransactionFailurePolicy()
            .decision(assetExists: assetExists)

        guard let idempotencyKey else {
            return decision
        }

        switch decision {
        case .retrySave:
            // A completion error is explicit evidence that this transaction
            // did not commit. Remove every local pointer to the failed
            // attempt so the next invocation cannot be trapped in
            // `awaitVisibility` forever.
            receiptStore.removeReceipt(for: idempotencyKey)

        case .recoverExistingAsset:
            // A few PhotoKit failures are reported after the asset becomes
            // visible. Preserve that asset rather than creating a duplicate.
            // The placeholder is normally already attached to the pending
            // intent; the fallback record also handles older intent formats.
            if receiptStore.assetIdentifier(for: idempotencyKey) == nil {
                if !receiptStore.materializePendingIntent(
                    for: idempotencyKey
                ),
                   let placeholderIdentifier {
                    _ = receiptStore.record(
                        assetIdentifier: placeholderIdentifier,
                        for: idempotencyKey
                    )
                }
            }
            _ = receiptStore.ensureCommitted(for: idempotencyKey)
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

    func visibleAssetIdentifier(
        for idempotencyKey: String
    ) -> String?
}

struct PhotoLibrarySaveReceiptAssetLocator:
    PhotoLibraryReceiptAssetLocating {

    private let receiptStore:
        PhotoLibrarySaveReceiptStore

    init(
        receiptStore: PhotoLibrarySaveReceiptStore
    ) {
        self.receiptStore = receiptStore
    }

    func visibleAssetIdentifier(
        for idempotencyKey: String
    ) -> String? {
        guard let recordedIdentifier =
                receiptStore.assetIdentifier(
                    for: idempotencyKey
                )
                ?? receiptStore.pendingAssetIdentifier(
                    for: idempotencyKey
                ) else {
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
    private let keyPrefix =
        "photomemo.photoLibrarySaveReceipt.v1"
    private let intentKeyPrefix =
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
                        $0.hasPrefix(keyPrefix + ".")
                        || $0.hasPrefix(intentKeyPrefix + ".")
                    )
                    && (
                        $0.hasSuffix(".recordedAt")
                        || (
                            !$0.hasPrefix(intentKeyPrefix + ".")
                            && !retainedStorageKeys.contains($0)
                        )
                        || (
                            $0.hasPrefix(intentKeyPrefix + ".")
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

        return "\(keyPrefix).\(normalizedKey)"
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

        return "\(intentKeyPrefix).\(normalizedKey)"
    }

    private func intentStorageKey(
        forStorageKey storageKey: String
    ) -> String {
        let suffix = storageKey
            .dropFirst((keyPrefix + ".").count)
        return "\(intentKeyPrefix).\(suffix)"
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

protocol PhotoLibraryExporting {

    func fetchAlbumOptions() async throws -> [PhotoAlbumOption]

    func ensureAlbum(
        named title: String
    ) async throws -> PhotoAlbumOption

    func saveImageResult(
        at fileURL: URL,
        metadata: PhotoMetadata,
        preferredAlbumIdentifier: String?
    ) async throws -> PhotoLibrarySaveResult

    func saveImageResult(
        at fileURL: URL,
        metadata: PhotoMetadata,
        preferredAlbumIdentifier: String?,
        idempotencyKey: String?
    ) async throws -> PhotoLibrarySaveResult
}

extension PhotoLibraryExporting {

    func saveImageResult(
        at fileURL: URL,
        metadata: PhotoMetadata,
        preferredAlbumIdentifier: String?,
        idempotencyKey: String?
    ) async throws -> PhotoLibrarySaveResult {

        try await saveImageResult(
            at: fileURL,
            metadata: metadata,
            preferredAlbumIdentifier: preferredAlbumIdentifier
        )
    }
}

struct PhotoLibrarySaveResult: Hashable {

    let albumTitle: String

    let assetLocalIdentifier: String
}

struct PhotoAlbumOption: Identifiable, Hashable {

    static let automaticIdentifier =
        MemoMarkAlbumSelection
        .automaticIdentifier

    let id: String

    let title: String

    let localIdentifier: String?

    static let automatic = PhotoAlbumOption(
        id: automaticIdentifier,
        title: "自动存入时光记",
        localIdentifier: nil
    )
}

enum PhotoLibraryExportError: LocalizedError {

    case unauthorized

    case albumNotFound

    case albumCreateFailed

    case assetSaveFailed

    case savedAssetReadbackPending

    var diagnosticCode: String {
        switch self {
        case .unauthorized:
            return "photoLibrary.permission.denied"
        case .albumNotFound:
            return "photoLibrary.album.notFound"
        case .albumCreateFailed:
            return "photoLibrary.album.createFailed"
        case .assetSaveFailed:
            return "photoLibrary.asset.saveFailed"
        case .savedAssetReadbackPending:
            return "photoLibrary.asset.readbackPending"
        }
    }

    var errorDescription: String? {

        switch self {

        case .unauthorized:
            return "请先允许时光记访问你的系统相册。"

        case .albumNotFound:
            return "未找到你选择的相册，请刷新后重试。"

        case .albumCreateFailed:
            return "无法创建时光记相册。"

        case .assetSaveFailed:
            return "图片已生成，但写入系统相册失败。"

        case .savedAssetReadbackPending:
            return "照片正在写入系统相册，请稍后重试。"
        }
    }
}

@MainActor
final class PhotoLibraryExportService:
    PhotoLibraryExporting {

    private let defaultAlbumTitle =
        MemoMarkAlbumSelection
        .defaultAlbumTitle

    private let metadataReader =
        PhotoMetadataReader()
    private let receiptStore:
        PhotoLibrarySaveReceiptStore
    private let receiptReconciliationPolicy =
        PhotoLibrarySaveReceiptReconciliationPolicy()

    init(
        receiptStore:
            PhotoLibrarySaveReceiptStore =
                PhotoLibrarySaveReceiptStore()
    ) {
        self.receiptStore = receiptStore
    }

    func fetchAlbumOptions() async throws -> [PhotoAlbumOption] {

        let status = await requestAuthorizationIfNeeded()

        guard isAuthorized(status) else {
            throw PhotoLibraryExportError.unauthorized
        }

        var albums: [PhotoAlbumOption] = []

        let fetchResult = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: nil
        )

        fetchResult.enumerateObjects { collection, _, _ in

            guard
                let title = collection.localizedTitle?
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),
                !title.isEmpty
            else {
                return
            }

            albums.append(
                PhotoAlbumOption(
                    id: collection.localIdentifier,
                    title: title,
                    localIdentifier: collection.localIdentifier
                )
            )
        }

        let uniqueAlbums =
            Array(
                Dictionary(
                    albums.map { ($0.id, $0) },
                    uniquingKeysWith: { first, _ in first }
                ).values
            )
            .sorted {
                $0.title.localizedStandardCompare($1.title)
                == .orderedAscending
            }

        return uniqueAlbums
    }

    func ensureAlbum(
        named title: String
    ) async throws -> PhotoAlbumOption {

        let status = await requestAuthorizationIfNeeded()

        guard isAuthorized(status) else {
            throw PhotoLibraryExportError.unauthorized
        }

        let albumTitle =
            normalizedAlbumTitle(title)

        if let existingAlbum =
            fetchAlbum(withTitle: albumTitle) {

            return PhotoAlbumOption(
                id: existingAlbum.localIdentifier,
                title:
                    existingAlbum.localizedTitle
                    ?? albumTitle,
                localIdentifier:
                    existingAlbum.localIdentifier
            )
        }

        let createdAlbum =
            try await createAlbum(
                named: albumTitle
            )

        return PhotoAlbumOption(
            id: createdAlbum.localIdentifier,
            title:
                createdAlbum.localizedTitle
                ?? albumTitle,
            localIdentifier:
                createdAlbum.localIdentifier
        )
    }

    func saveImage(
        at fileURL: URL,
        metadata: PhotoMetadata,
        preferredAlbumIdentifier: String?
    ) async throws -> String {

        try await saveImageResult(
            at: fileURL,
            metadata: metadata,
            preferredAlbumIdentifier:
                preferredAlbumIdentifier
        ).albumTitle
    }

    func saveImageResult(
        at fileURL: URL,
        metadata: PhotoMetadata,
        preferredAlbumIdentifier: String?
    ) async throws -> PhotoLibrarySaveResult {

        try await saveImageResult(
            at: fileURL,
            metadata: metadata,
            preferredAlbumIdentifier: preferredAlbumIdentifier,
            idempotencyKey: nil
        )
    }

    func saveImageResult(
        at fileURL: URL,
        metadata: PhotoMetadata,
        preferredAlbumIdentifier: String?,
        idempotencyKey: String?
    ) async throws -> PhotoLibrarySaveResult {

        let status = await requestAuthorizationIfNeeded()

        guard isAuthorized(status) else {
            throw PhotoLibraryExportError.unauthorized
        }

        return try await PhotoLibrarySaveGate.shared.run { [self] in
            let album =
                try await resolvedAlbum(
                    preferredAlbumIdentifier
                )

            if let idempotencyKey,
               let existingAsset =
                try existingAsset(
                    for: idempotencyKey
                ) {
                return PhotoLibrarySaveResult(
                    albumTitle:
                        album?.localizedTitle
                        ?? "",
                    assetLocalIdentifier:
                        existingAsset.localIdentifier
                )
            }

            try Task.checkCancellation()

            if let idempotencyKey {
                guard receiptStore.recordIntent(
                    for: idempotencyKey
                ) else {
                    throw PhotoLibraryExportError
                        .savedAssetReadbackPending
                }

                do {
                    try Task.checkCancellation()
                } catch {
                    receiptStore.removeIntent(
                        for: idempotencyKey
                    )
                    throw error
                }
            }

            var placeholderIdentifier: String?
            var didPersistPlaceholderIntent = false

            do {
                try await performChanges {

                let assetRequest =
                    PHAssetCreationRequest.forAsset()

                assetRequest.creationDate =
                    metadata.captureDate

                let resourceOptions =
                    PHAssetResourceCreationOptions()

                resourceOptions.shouldMoveFile = false
                resourceOptions.originalFilename =
                    self.assetOriginalFilename(
                        for: fileURL,
                        idempotencyKey: idempotencyKey
                    )

                assetRequest.addResource(
                    with: .photo,
                    fileURL: fileURL,
                    options: resourceOptions
                )

                guard let placeholder =
                    assetRequest.placeholderForCreatedAsset
                else {
                    return
                }

                placeholderIdentifier =
                    placeholder.localIdentifier

                if let idempotencyKey {
                    didPersistPlaceholderIntent =
                        self.receiptStore
                        .recordIntentAssetIdentifier(
                            placeholder.localIdentifier,
                            for: idempotencyKey
                        )
                }

                if let album,
                   let albumChangeRequest =
                    PHAssetCollectionChangeRequest(
                        for: album
                    ) {

                    albumChangeRequest.addAssets(
                        [placeholder] as NSArray
                    )
                }
                }
            } catch {
                let decision =
                    PhotoLibrarySaveTransactionRecovery.resolve(
                        idempotencyKey: idempotencyKey,
                        placeholderIdentifier: placeholderIdentifier,
                        assetExists: placeholderIdentifier
                            .flatMap(fetchAsset(with:)) != nil,
                        receiptStore: receiptStore
                    )
                if decision == .recoverExistingAsset,
                   !(error is CancellationError),
                   let placeholderIdentifier {
                    if let idempotencyKey {
                        guard receiptStore
                            .receipt(for: idempotencyKey)?
                            .phase == .commitAcknowledged else {
                            // The PhotoKit asset is visible, but the local
                            // idempotency proof is not durable yet. Do not
                            // report success without the proof that prevents
                            // a later retry from creating a duplicate.
                            throw PhotoLibraryExportError
                                .savedAssetReadbackPending
                        }
                    }
                    return PhotoLibrarySaveResult(
                        albumTitle: album?.localizedTitle ?? "",
                        assetLocalIdentifier: placeholderIdentifier
                    )
                }
                throw error
            }

            try Task.checkCancellation()

            guard placeholderIdentifier != nil else {
                if let idempotencyKey {
                    receiptStore.removeReceipt(for: idempotencyKey)
                }
                throw PhotoLibraryExportError.assetSaveFailed
            }

            if let idempotencyKey {
                guard didPersistPlaceholderIntent,
                      receiptStore.record(
                          assetIdentifier: placeholderIdentifier ?? "",
                          for: idempotencyKey
                      ) else {
                    // The PhotoKit transaction has already completed. A
                    // local receipt write failure is therefore ambiguous,
                    // not proof that the asset is absent. Keep the pending
                    // intent so a later invocation either reuses the
                    // recorded asset identifier or remains blocked awaiting
                    // reconciliation instead of creating a duplicate.
                    throw PhotoLibraryExportError
                        .savedAssetReadbackPending
                }
            }

            try await PhotoLibraryCommitInterruptionTestHook
                .pauseIfRequested()
            if let idempotencyKey {
                // The submission receipt remains the safe fallback if this
                // acknowledgement cannot be persisted. Direct asset lookup
                // still prevents a second PhotoKit write.
                guard receiptStore.markCommitted(for: idempotencyKey) else {
                    throw PhotoLibraryExportError.savedAssetReadbackPending
                }
            }

            return PhotoLibrarySaveResult(
                albumTitle:
                    album?.localizedTitle
                    ?? "",
                assetLocalIdentifier:
                    placeholderIdentifier ?? ""
            )
        }
    }

    func assetOriginalFilename(
        for fileURL: URL,
        idempotencyKey _: String? = nil
    ) -> String {

        let fileName =
            fileURL.lastPathComponent
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !fileName.isEmpty else {
            return "MemoMark.jpg"
        }

        return fileName
    }

    func readMetadata(
        forSavedAsset localIdentifier: String
    ) async throws -> PhotoMetadata {

        let asset =
            fetchAsset(
                with: localIdentifier
            )

        guard let asset else {
            throw PhotoLibraryExportError.assetSaveFailed
        }

        let temporaryURL =
            try await exportAssetResourceToTemporaryFile(
                for: asset
            )

        defer {
            try? FileManager.default.removeItem(
                at: temporaryURL
            )
        }

        return metadataReader.read(
            from: temporaryURL
        )
    }
}

private extension PhotoLibraryExportService {

    func existingAsset(
        for idempotencyKey: String
    ) throws -> PHAsset? {
        guard let assetIdentifier =
                receiptStore.assetIdentifier(
                    for: idempotencyKey
                )
                ?? receiptStore.pendingAssetIdentifier(
                    for: idempotencyKey
                ) else {
            return nil
        }

        let asset =
            PHAsset.fetchAssets(
                withLocalIdentifiers: [
                    assetIdentifier
                ],
                options: nil
            )
            .firstObject

        switch receiptReconciliationPolicy
            .decision(
                assetExists: asset != nil,
                recordedAt:
                    receiptStore.recordedAt(
                        for: idempotencyKey
                    )
            ) {
        case .reuseAsset:
            guard let asset else {
                throw PhotoLibraryExportError
                    .savedAssetReadbackPending
            }
            guard receiptStore.materializePendingIntent(
                for: idempotencyKey
            ), receiptStore.ensureCommitted(
                for: idempotencyKey
            ) else {
                throw PhotoLibraryExportError
                    .savedAssetReadbackPending
            }
            return asset

        case .awaitVisibility:
            throw PhotoLibraryExportError
                .savedAssetReadbackPending
        }
    }

    func isAuthorized(
        _ status: PHAuthorizationStatus
    ) -> Bool {

        status == .authorized
            || status == .limited
    }

    func requestAuthorizationIfNeeded() async -> PHAuthorizationStatus {

        let currentStatus =
            PHPhotoLibrary.authorizationStatus(
                for: .readWrite
            )

        if currentStatus != .notDetermined {
            return currentStatus
        }

        return await withCheckedContinuation { continuation in

            PHPhotoLibrary.requestAuthorization(
                for: .readWrite
            ) { status in

                continuation.resume(returning: status)
            }
        }
    }

    func resolvedAlbum(
        _ localIdentifier: String?
    ) async throws -> PHAssetCollection? {

        let normalizedIdentifier =
            MemoMarkAlbumSelection
            .normalizedIdentifier(
                localIdentifier ?? ""
            )

        if normalizedIdentifier
            == MemoMarkAlbumSelection
            .systemLibraryIdentifier {
            return nil
        }

        if !normalizedIdentifier.isEmpty,
           let existingAlbum =
            fetchAlbum(
                with: normalizedIdentifier
            ) {

            return existingAlbum
        }

        if let existingDefaultAlbum =
            fetchAlbum(
                withTitle: defaultAlbumTitle
            ) {

            return existingDefaultAlbum
        }

        return try await createDefaultAlbum()
    }

    func normalizedAlbumTitle(
        _ title: String
    ) -> String {

        let trimmedTitle =
            title.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmedTitle.isEmpty
            ? defaultAlbumTitle
            : trimmedTitle
    }

    func fetchAlbum(
        with localIdentifier: String
    ) -> PHAssetCollection? {

        PHAssetCollection
            .fetchAssetCollections(
                withLocalIdentifiers: [localIdentifier],
                options: nil
            )
            .firstObject
    }

    func fetchAsset(
        with localIdentifier: String
    ) -> PHAsset? {

        PHAsset.fetchAssets(
            withLocalIdentifiers: [localIdentifier],
            options: nil
        ).firstObject
    }

    func fetchAlbum(
        withTitle title: String
    ) -> PHAssetCollection? {

        let fetchResult =
            PHAssetCollection.fetchAssetCollections(
                with: .album,
                subtype: .any,
                options: nil
            )

        var matchedAlbum: PHAssetCollection?

        fetchResult.enumerateObjects { collection, _, stop in

            guard
                collection.localizedTitle == title
            else {
                return
            }

            matchedAlbum = collection
            stop.pointee = true
        }

        return matchedAlbum
    }

    func createDefaultAlbum() async throws -> PHAssetCollection {

        try await createAlbum(
            named: defaultAlbumTitle
        )
    }

    func createAlbum(
        named title: String
    ) async throws -> PHAssetCollection {

        var createdIdentifier: String?
        let albumTitle =
            normalizedAlbumTitle(title)

        try await performChanges {

            let request =
                PHAssetCollectionChangeRequest
                .creationRequestForAssetCollection(
                    withTitle: albumTitle
                )

            createdIdentifier =
                request.placeholderForCreatedAssetCollection
                .localIdentifier
        }

        guard
            let createdIdentifier,
            let createdAlbum = fetchAlbum(
                with: createdIdentifier
            )
        else {
            throw PhotoLibraryExportError.albumCreateFailed
        }

        return createdAlbum
    }

    func performChanges(
        _ changes: @escaping () -> Void
    ) async throws {

        try await withCheckedThrowingContinuation {
            (
                continuation:
                    CheckedContinuation<Void, Error>
            ) in

            PHPhotoLibrary.shared().performChanges(
                changes
            ) { success, error in

                if let error {
                    continuation.resume(
                        throwing: error
                    )
                    return
                }

                guard success else {
                    continuation.resume(
                        throwing:
                            PhotoLibraryExportError
                            .assetSaveFailed
                    )
                    return
                }

                continuation.resume()
            }
        }
    }

    func exportAssetResourceToTemporaryFile(
        for asset: PHAsset
    ) async throws -> URL {

        let resources =
            PHAssetResource.assetResources(
                for: asset
            )

        guard let resource =
            resources.first(where: {
                $0.type == .photo
                    || $0.type == .fullSizePhoto
            }) ?? resources.first
        else {
            throw PhotoLibraryExportError.assetSaveFailed
        }

        let temporaryFolder =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "MemoMarkPhotoLibraryValidation",
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: temporaryFolder,
            withIntermediateDirectories: true
        )

        let baseName =
            PhotoKitResourceFileName.value(
                for: resource
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let fileName =
            baseName.isEmpty
            ? "\(asset.localIdentifier).jpg"
            : baseName

        let targetURL =
            temporaryFolder.appendingPathComponent(
                UUID().uuidString + "_" + fileName
            )

        return try await withCheckedThrowingContinuation {
            (
                continuation:
                    CheckedContinuation<URL, Error>
            ) in

            PHAssetResourceManager.default()
                .writeData(
                    for: resource,
                    toFile: targetURL,
                    options: nil
                ) { error in

                    if let error {
                        continuation.resume(
                            throwing: error
                        )
                        return
                    }

                    continuation.resume(
                        returning: targetURL
                    )
                }
        }
    }
}
