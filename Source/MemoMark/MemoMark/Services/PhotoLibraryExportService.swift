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

protocol PhotoLibraryExporting:
    PhotoLibraryAlbumAccessing {

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
    private let receiptLedger:
        PhotoLibrarySaveReceiptLedger
    private let placeholderIntentWriter:
        PhotoLibraryPendingIntentPlaceholderWriter
    private let photoLibraryGateway:
        PhotoLibraryTransactionGateway
    private let receiptReconciliationPolicy =
        PhotoLibrarySaveReceiptReconciliationPolicy()

    init(
        receiptStore:
            PhotoLibrarySaveReceiptStore? = nil,
        photoLibraryGateway:
            PhotoLibraryTransactionGateway? = nil
    ) {
        let receiptLedger =
            receiptStore.map {
                PhotoLibrarySaveReceiptLedger(
                    store: $0
                )
            }
            ?? .shared
        self.receiptLedger = receiptLedger
        placeholderIntentWriter =
            receiptLedger.placeholderIntentWriter
        self.photoLibraryGateway =
            photoLibraryGateway
            ?? PhotoLibraryTransactionGateway.shared
    }

    func fetchAlbumOptions() async throws -> [PhotoAlbumOption] {

        let status = await requestAuthorizationIfNeeded()

        guard isAuthorized(status) else {
            throw PhotoLibraryExportError.unauthorized
        }

        var albums: [PhotoAlbumOption] = []

        for collection in photoLibraryGateway.albumCollections() {

            guard
                let title = collection.localizedTitle?
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),
                !title.isEmpty
            else {
                continue
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

        // Album lookup and creation form one logical critical section. Without
        // the shared gate, two configuration or batch tasks can both observe a
        // missing title and create duplicate Photo Library albums.
        return try await PhotoLibrarySaveGate.shared.run { [self] in
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
                try await existingAsset(
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
                guard await receiptLedger.recordIntent(
                    for: idempotencyKey
                ) else {
                    throw PhotoLibraryExportError
                        .savedAssetReadbackPending
                }

                do {
                    try Task.checkCancellation()
                } catch {
                    await receiptLedger.removeIntent(
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
                        self.placeholderIntentWriter.record(
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
            } catch {
                let decision =
                    await PhotoLibrarySaveTransactionRecovery.resolve(
                        idempotencyKey: idempotencyKey,
                        placeholderIdentifier: placeholderIdentifier,
                        assetExists: placeholderIdentifier
                            .flatMap(fetchAsset(with:)) != nil,
                        receiptLedger: receiptLedger
                    )
                let receipt: PhotoLibrarySaveReceipt?
                if let idempotencyKey {
                    receipt = await receiptLedger.receipt(
                        for: idempotencyKey
                    )
                } else {
                    receipt = nil
                }
                switch PhotoLibraryAmbiguousCommitRecoveryPolicy()
                    .resolution(
                        decision: decision,
                        wasCancelled: error is CancellationError,
                        idempotencyKey: idempotencyKey,
                        receipt: receipt
                    ) {
                case .reportRecoveredAsset:
                    guard let placeholderIdentifier else {
                        throw error
                    }
                    return PhotoLibrarySaveResult(
                        albumTitle: album?.localizedTitle ?? "",
                        assetLocalIdentifier: placeholderIdentifier
                    )
                case .awaitReadback:
                    throw PhotoLibraryExportError
                        .savedAssetReadbackPending
                case .rethrowFailure:
                    throw error
                }
            }

            try Task.checkCancellation()

            guard placeholderIdentifier != nil else {
                if idempotencyKey != nil {
                    // The external transaction has already returned. A
                    // missing placeholder is therefore an ambiguous local
                    // observation, not proof that the asset was not created.
                    // Keep the submitted intent/receipt so a retry cannot
                    // issue a second PhotoKit write.
                    throw PhotoLibraryExportError
                        .savedAssetReadbackPending
                }
                throw PhotoLibraryExportError.assetSaveFailed
            }

            let savedAssetIdentifier = placeholderIdentifier ?? ""

            if let idempotencyKey {
                guard didPersistPlaceholderIntent,
                      await receiptLedger.record(
                          assetIdentifier: savedAssetIdentifier,
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
                guard await receiptLedger.markCommitted(
                    for: idempotencyKey
                ) else {
                    throw PhotoLibraryExportError.savedAssetReadbackPending
                }

                // A successful PhotoKit completion callback is not by itself
                // enough to project this durable batch task as completed. The
                // exact receipt-backed asset must be visible through the
                // direct identifier lookup; otherwise retain the receipt and
                // let normal reconciliation resolve delayed visibility.
                guard PhotoLibraryStaticSaveReadbackPolicy()
                    .decision(
                        assetExists:
                            photoLibraryGateway.asset(
                                with: savedAssetIdentifier
                            ) != nil
                    ) == .complete else {
                    throw PhotoLibraryExportError.savedAssetReadbackPending
                }
            }

            return PhotoLibrarySaveResult(
                albumTitle:
                    album?.localizedTitle
                    ?? "",
                assetLocalIdentifier:
                    savedAssetIdentifier
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

        let temporaryURL: URL
        do {
            temporaryURL = try await photoLibraryGateway
                .exportPhotoResourceToTemporaryFile(
                    for: asset
                )
        } catch is PhotoLibraryTransactionGateway.Error {
            throw PhotoLibraryExportError.assetSaveFailed
        }

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
    ) async throws -> PHAsset? {
        let recordedIdentifier =
            await receiptLedger.assetIdentifier(
                for: idempotencyKey
            )
        let pendingIdentifier =
            await receiptLedger.pendingAssetIdentifier(
                for: idempotencyKey
            )
        guard let assetIdentifier =
                recordedIdentifier
                ?? pendingIdentifier else {
            return nil
        }

        let asset = fetchAsset(
            with: assetIdentifier
        )

        switch receiptReconciliationPolicy
            .decision(
                assetExists: asset != nil,
                recordedAt:
                    await receiptLedger.recordedAt(
                        for: idempotencyKey
                    )
            ) {
        case .reuseAsset:
            guard let asset else {
                throw PhotoLibraryExportError
                    .savedAssetReadbackPending
            }
            guard await receiptLedger.materializePendingIntent(
                for: idempotencyKey
            ), await receiptLedger.ensureCommitted(
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

        await photoLibraryGateway
            .requestReadWriteAuthorization()
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

        photoLibraryGateway.album(
            with: localIdentifier
        )
    }

    func fetchAsset(
        with localIdentifier: String
    ) -> PHAsset? {

        photoLibraryGateway.asset(
            with: localIdentifier
        )
    }

    func fetchAlbum(
        withTitle title: String
    ) -> PHAssetCollection? {

        photoLibraryGateway.album(titled: title)
    }

    func createDefaultAlbum() async throws -> PHAssetCollection {

        try await createAlbum(
            named: defaultAlbumTitle
        )
    }

    func createAlbum(
        named title: String
    ) async throws -> PHAssetCollection {

        let albumTitle =
            normalizedAlbumTitle(title)
        let createdAlbum: PHAssetCollection?
        do {
            createdAlbum = try await photoLibraryGateway.createAlbum(
                named: albumTitle
            )
        } catch is PhotoLibraryTransactionGateway.Error {
            throw PhotoLibraryExportError.albumCreateFailed
        }
        guard let createdAlbum else {
            throw PhotoLibraryExportError.albumCreateFailed
        }

        return createdAlbum
    }

    func performChanges(
        _ changes: @escaping () -> Void
    ) async throws {

        do {
            try await photoLibraryGateway.performChanges(
                changes
            )
        } catch is PhotoLibraryTransactionGateway.Error {
            throw PhotoLibraryExportError.assetSaveFailed
        }
    }

}
