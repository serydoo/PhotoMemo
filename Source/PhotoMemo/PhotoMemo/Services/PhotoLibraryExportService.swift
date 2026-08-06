import Foundation
import Photos

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
    }

    private let defaults: UserDefaults
    private let lock = NSLock()
    private let keyPrefix =
        "photomemo.photoLibrarySaveReceipt.v1"

    init(
        defaults: UserDefaults =
            PhotoMemoSharedContainer
            .sharedUserDefaults
    ) {
        self.defaults = defaults
    }

    func assetIdentifier(
        for idempotencyKey: String
    ) -> String? {
        guard let key = storageKey(
            for: idempotencyKey
        ) else {
            return nil
        }

        return lock.withLock {
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

        return lock.withLock {
            storedReceipt(forStorageKey: key)?
                .recordedAt
        }
    }

    func record(
        assetIdentifier: String,
        for idempotencyKey: String
    ) {
        let normalizedIdentifier =
            assetIdentifier
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        guard !normalizedIdentifier.isEmpty,
              let key = storageKey(
                for: idempotencyKey
              ) else {
            return
        }

        let receipt = StoredReceipt(
            assetIdentifier: normalizedIdentifier,
            recordedAt: Date()
        )
        guard let encodedReceipt = try? JSONEncoder()
            .encode(receipt) else {
            return
        }

        lock.withLock {
            defaults.set(encodedReceipt, forKey: key)
            defaults.removeObject(
                forKey:
                    timestampStorageKey(
                        forStorageKey: key
                    )
            )
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

        lock.withLock {
            defaults.removeObject(forKey: key)
            defaults.removeObject(
                forKey:
                    timestampStorageKey(
                        forStorageKey: key
                    )
            )
        }
    }

    func removeReceipts(
        for idempotencyKeys: Set<String>
    ) {
        let keys = idempotencyKeys.compactMap {
            storageKey(for: $0)
        }

        lock.withLock {
            for key in keys {
                defaults.removeObject(forKey: key)
                defaults.removeObject(
                    forKey:
                        timestampStorageKey(
                            forStorageKey: key
                        )
                )
            }
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

        lock.withLock {
            for key in retainedStorageKeys {
                migrateLegacyReceiptIfNeeded(
                    forStorageKey: key
                )
            }

            let staleStorageKeys = defaults
                .dictionaryRepresentation()
                .keys
                .filter {
                    $0.hasPrefix(keyPrefix + ".")
                    && (
                        $0.hasSuffix(".recordedAt")
                        || !retainedStorageKeys.contains($0)
                    )
                }

            for key in staleStorageKeys {
                defaults.removeObject(forKey: key)
            }
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
                ) as? Date
        )
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

        defaults.set(encodedReceipt, forKey: storageKey)
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
        PhotoMemoAlbumSelection
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
        PhotoMemoAlbumSelection
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

            var placeholderIdentifier: String?

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
                    self.receiptStore.record(
                        assetIdentifier:
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

            guard placeholderIdentifier != nil else {
                throw PhotoLibraryExportError.assetSaveFailed
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
            PhotoMemoAlbumSelection
            .normalizedIdentifier(
                localIdentifier ?? ""
            )

        if normalizedIdentifier
            == PhotoMemoAlbumSelection
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
            resource.originalFilename
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
