import Foundation
#if canImport(Photos)
import Photos
#endif

@MainActor
final class PhotoKitLivePhotoAssetWriter:
    LivePhotoAssetWriting {

    private let savePerformer:
        any LivePhotoAssetSavePerforming
    private let pairingIdentityVerifier:
        any LivePhotoPairingIdentityVerifying
    private let assetReadbackVerifier:
        any LivePhotoAssetReadbackVerifying
    private let readbackAttemptCount: Int
    private let readbackRetryDelayNanoseconds:
        UInt64
    private let fileManager: FileManager
    private let runtimeGate:
        MediaPipelineRuntimeGate

    init(
        savePerformer:
            (any LivePhotoAssetSavePerforming)? = nil,
        pairingIdentityVerifier:
            (any LivePhotoPairingIdentityVerifying)? = nil,
        assetReadbackVerifier:
            (any LivePhotoAssetReadbackVerifying)? = nil,
        receiptStore:
            PhotoLibrarySaveReceiptStore? = nil,
        photoLibraryGateway:
            PhotoLibraryTransactionGateway? = nil,
        readbackAttemptCount: Int = 8,
        readbackRetryDelayNanoseconds:
            UInt64 = 250_000_000,
        fileManager: FileManager = .default,
        runtimeGate:
            MediaPipelineRuntimeGate = .defaultOff
    ) {
        self.savePerformer =
            savePerformer
            ?? PhotoKitLivePhotoAssetSavePerformer(
                receiptLedger:
                    receiptStore.map {
                        PhotoLibrarySaveReceiptLedger(
                            store: $0
                        )
                    }
                    ?? .shared,
                photoLibraryGateway:
                    photoLibraryGateway
                    ?? PhotoLibraryTransactionGateway.shared
            )
        self.pairingIdentityVerifier =
            pairingIdentityVerifier
            ?? LivePhotoPairingIdentityVerifier()
        self.assetReadbackVerifier =
            assetReadbackVerifier
            ?? PhotoKitLivePhotoAssetReadbackVerifier()
        self.readbackAttemptCount =
            max(readbackAttemptCount, 1)
        self.readbackRetryDelayNanoseconds =
            readbackRetryDelayNanoseconds
        self.fileManager = fileManager
        self.runtimeGate =
            runtimeGate
    }

    func saveAsset(
        _ request: LivePhotoSaveRequest
    ) async throws -> PhotoLibrarySaveResult {

        guard fileManager.fileExists(
            atPath: request.stillPhotoFileURL.path
        ) else {
            throw LivePhotoAssetWritingError
                .stillPhotoFileMissing
        }

        guard fileManager.fileExists(
            atPath: request.pairedVideoFileURL.path
        ) else {
            throw LivePhotoAssetWritingError
                .pairedVideoFileMissing
        }

        let stillPhotoOriginalFilename =
            resolvedOriginalFilename(
                preferred:
                    request.stillPhotoOriginalFilename,
                fallbackURL:
                    request.stillPhotoFileURL,
                defaultName:
                    "MemoMark.heic"
            )
        let pairedVideoOriginalFilename =
            resolvedOriginalFilename(
                preferred:
                    request.pairedVideoOriginalFilename,
                fallbackURL:
                    request.pairedVideoFileURL,
                defaultName:
                    "MemoMark.mov"
            )
        guard outputBaseName(
            stillPhotoOriginalFilename
        ) == outputBaseName(
            pairedVideoOriginalFilename
        ) else {
            throw LivePhotoAssetWritingError
                .outputFilenameBaseMismatch
        }

        do {
            _ = try await pairingIdentityVerifier
                .verifyPair(
                    stillPhotoURL:
                        request.stillPhotoFileURL,
                    pairedVideoURL:
                        request.pairedVideoFileURL
                )
        } catch let error as LivePhotoPairingIdentityVerificationError {
            throw LivePhotoAssetWritingError
                .pairingIdentityVerificationFailed(
                    error
                )
        }

        guard runtimeGate.permitsPhotoLibraryWrites else {
            throw LivePhotoAssetWritingError
                .photoLibraryWritesDisabledByRuntimeGate
        }

        try Task.checkCancellation()

        let saveResult = try await savePerformer
            .save(
                operation:
                    LivePhotoAssetWriteOperation(
                        creationDate:
                            request.captureDate,
                        preferredAlbumIdentifier:
                            request.preferredAlbumIdentifier,
                        resources: [
                            LivePhotoAssetResourceWriteRequest(
                                kind: .photo,
                                fileURL:
                                    request
                                    .stillPhotoFileURL,
                                originalFilename:
                                    stillPhotoOriginalFilename
                            ),
                            LivePhotoAssetResourceWriteRequest(
                                kind: .pairedVideo,
                                fileURL:
                                    request
                                    .pairedVideoFileURL,
                                originalFilename:
                                    pairedVideoOriginalFilename
                            )
                        ],
                        idempotencyKey:
                            request.idempotencyKey
                    )
            )

        try await verifySavedLivePhoto(
            saveResult
        )
        return saveResult
    }
}

private extension PhotoKitLivePhotoAssetWriter {

    func verifySavedLivePhoto(
        _ saveResult: PhotoLibrarySaveResult
    ) async throws {

        var didReadInvalidAsset = false

        for attempt in 0..<readbackAttemptCount {
            try Task.checkCancellation()
            do {
                let report =
                    try assetReadbackVerifier
                    .verifyAsset(
                        localIdentifier:
                            saveResult
                            .assetLocalIdentifier
                    )
                if report
                    .satisfiesLivePhotoPairingContract {
                    MemoMarkShareDiagnostics.record(
                        stage: .livePhotoAssetReadback,
                        message:
                            "result=verified, attempt=\(attempt + 1), livePhoto=true, stillResource=true, pairedVideoResource=true, positiveDuration=true, positivePixelSize=true"
                    )
                    return
                }
                didReadInvalidAsset = true
                MemoMarkShareDiagnostics.record(
                    stage: .livePhotoAssetReadback,
                    message:
                        "result=invalid, attempt=\(attempt + 1), livePhoto=\(report.isLivePhoto), stillResource=\(report.hasStillPhotoResource), pairedVideoResource=\(report.hasPairedVideoResource), positiveDuration=\(report.duration > 0), positivePixelSize=\(report.pixelWidth > 0 && report.pixelHeight > 0)"
                )
            } catch {
                if Task.isCancelled {
                    throw CancellationError()
                }
                let systemError = error as NSError
                MemoMarkShareDiagnostics.record(
                    stage: .livePhotoAssetReadback,
                    message:
                        "result=unavailable, attempt=\(attempt + 1), errorDomain=\(systemError.domain), errorCode=\(systemError.code)"
                )
            }

            if attempt < readbackAttemptCount - 1,
               readbackRetryDelayNanoseconds > 0 {
                try await Task.sleep(
                    nanoseconds:
                        readbackRetryDelayNanoseconds
                )
            }
        }

        MemoMarkShareDiagnostics.record(
            stage: .livePhotoAssetReadback,
            message:
                "result=failed, attempts=\(readbackAttemptCount), reason=\(didReadInvalidAsset ? "invalidLivePhotoContract" : "assetUnavailable")"
        )
        throw didReadInvalidAsset
            ? LivePhotoAssetWritingError
                .savedAssetNotLivePhoto
            : LivePhotoAssetWritingError
                .savedAssetReadbackFailed
    }

    func resolvedOriginalFilename(
        preferred: String?,
        fallbackURL: URL,
        defaultName: String
    ) -> String {

        if let resolved =
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                preferred
            ) {
            return resolved
        }

        let fallbackName =
            fallbackURL.lastPathComponent
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !fallbackName.isEmpty {
            return fallbackName
        }

        return defaultName
    }

    func outputBaseName(
        _ fileName: String
    ) -> String {
        URL(fileURLWithPath: fileName)
            .deletingPathExtension()
            .lastPathComponent
            .lowercased()
    }
}

#if canImport(Photos)
@MainActor
private final class PhotoKitLivePhotoAssetSavePerformer:
    LivePhotoAssetSavePerforming {

    private let defaultAlbumTitle =
        MemoMarkAlbumSelection
        .defaultAlbumTitle
    private let receiptLedger:
        PhotoLibrarySaveReceiptLedger
    private let placeholderIntentWriter:
        PhotoLibraryPendingIntentPlaceholderWriter
    private let photoLibraryGateway:
        PhotoLibraryTransactionGateway
    private let receiptReconciliationPolicy =
        PhotoLibrarySaveReceiptReconciliationPolicy()

    init(
        receiptLedger:
            PhotoLibrarySaveReceiptLedger,
        photoLibraryGateway:
            PhotoLibraryTransactionGateway
    ) {
        self.receiptLedger = receiptLedger
        placeholderIntentWriter =
            receiptLedger.placeholderIntentWriter
        self.photoLibraryGateway = photoLibraryGateway
    }

    func save(
        operation: LivePhotoAssetWriteOperation
    ) async throws -> PhotoLibrarySaveResult {

        let status =
            await requestAuthorizationIfNeeded()

        guard isAuthorized(status) else {
            throw LivePhotoAssetWritingError
                .unauthorized
        }

        return try await PhotoLibrarySaveGate.shared.run { [self] in
            let album =
                try await resolvedAlbum(
                    operation
                    .preferredAlbumIdentifier
                )

            if let idempotencyKey = operation.idempotencyKey,
               let existingAsset = try await existingAsset(
                   for: idempotencyKey
               ) {
                return PhotoLibrarySaveResult(
                    albumTitle: album?.localizedTitle ?? "",
                    assetLocalIdentifier: existingAsset.localIdentifier
                )
            }

            try Task.checkCancellation()

            if let idempotencyKey = operation.idempotencyKey {
                guard await receiptLedger.recordIntent(
                    for: idempotencyKey
                ) else {
                    throw LivePhotoAssetWritingError
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
                    operation.creationDate

                for resource in operation.resources {
                    let options =
                        PHAssetResourceCreationOptions()
                    options.shouldMoveFile = false
                    options.originalFilename =
                        resource.originalFilename

                    assetRequest.addResource(
                        with:
                            resource.kind
                            .photoKitResourceType,
                        fileURL:
                            resource.fileURL,
                        options: options
                    )
                }

                guard let placeholder =
                    assetRequest.placeholderForCreatedAsset
                else {
                    return
                }

                placeholderIdentifier =
                    placeholder.localIdentifier

                if let idempotencyKey =
                    operation.idempotencyKey {
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
                        idempotencyKey: operation.idempotencyKey,
                        placeholderIdentifier: placeholderIdentifier,
                        assetExists: placeholderIdentifier
                            .flatMap(fetchAsset(with:)) != nil,
                        receiptLedger: receiptLedger
                    )
                let receipt: PhotoLibrarySaveReceipt?
                if let idempotencyKey = operation.idempotencyKey {
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
                        idempotencyKey: operation.idempotencyKey,
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
                    throw LivePhotoAssetWritingError
                        .savedAssetReadbackPending
                case .rethrowFailure:
                    throw error
                }
            }

            try Task.checkCancellation()

            guard let placeholderIdentifier else {
                if operation.idempotencyKey != nil {
                    // The external transaction has already returned. A
                    // missing placeholder is therefore an ambiguous local
                    // observation, not proof that the asset was not created.
                    // Keep the submitted intent/receipt so a retry cannot
                    // issue a second PhotoKit write.
                    throw LivePhotoAssetWritingError
                        .savedAssetReadbackPending
                }
                throw LivePhotoAssetWritingError
                    .assetSaveFailed
            }

            if let idempotencyKey = operation.idempotencyKey {
                guard didPersistPlaceholderIntent,
                      await receiptLedger.record(
                          assetIdentifier: placeholderIdentifier,
                          for: idempotencyKey
                      ) else {
                    // PhotoKit has already accepted the external transaction.
                    // Retain the pending placeholder evidence so a retry can
                    // reconcile the visible asset instead of creating a
                    // duplicate Live Photo.
                    throw LivePhotoAssetWritingError
                        .savedAssetReadbackPending
                }
            }

            try await PhotoLibraryCommitInterruptionTestHook
                .pauseIfRequested()
            if let idempotencyKey = operation.idempotencyKey {
                // Keep the transaction-submitted receipt as the safe fallback
                // when the post-commit acknowledgement cannot be persisted.
                guard await receiptLedger.markCommitted(
                    for: idempotencyKey
                ) else {
                    throw LivePhotoAssetWritingError.savedAssetReadbackPending
                }
            }

            return PhotoLibrarySaveResult(
                albumTitle:
                    album?.localizedTitle
                    ?? "",
                assetLocalIdentifier:
                    placeholderIdentifier
            )
        }
    }
}

private extension PhotoKitLivePhotoAssetSavePerformer {

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
                throw LivePhotoAssetWritingError
                    .savedAssetReadbackPending
            }
            guard await receiptLedger.materializePendingIntent(
                for: idempotencyKey
            ), await receiptLedger.ensureCommitted(
                for: idempotencyKey
            ) else {
                throw LivePhotoAssetWritingError
                    .savedAssetReadbackPending
            }
            return asset

        case .awaitVisibility:
            throw LivePhotoAssetWritingError
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

        if !normalizedIdentifier.isEmpty {
            guard
                let existingAlbum =
                    fetchAlbum(
                        with: normalizedIdentifier
                    )
            else {
                throw LivePhotoAssetWritingError
                    .albumNotFound
            }

            return existingAlbum
        }

        if let existingDefaultAlbum =
            fetchAlbum(
                withTitle: defaultAlbumTitle
            ) {
            return existingDefaultAlbum
        }

        return try await createAlbum(
            named: defaultAlbumTitle
        )
    }

    func fetchAlbum(
        with localIdentifier: String
    ) -> PHAssetCollection? {
        photoLibraryGateway.album(
            with: localIdentifier
        )
    }

    func fetchAlbum(
        withTitle title: String
    ) -> PHAssetCollection? {
        photoLibraryGateway.album(titled: title)
    }

    func fetchAsset(
        with localIdentifier: String
    ) -> PHAsset? {
        photoLibraryGateway.asset(
            with: localIdentifier
        )
    }

    func createAlbum(
        named title: String
    ) async throws -> PHAssetCollection {
        let createdAlbum: PHAssetCollection?
        do {
            createdAlbum = try await photoLibraryGateway.createAlbum(
                named: title
            )
        } catch is PhotoLibraryTransactionGateway.Error {
            throw LivePhotoAssetWritingError.albumCreateFailed
        }
        guard let createdAlbum else {
            throw LivePhotoAssetWritingError
                .albumCreateFailed
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
            throw LivePhotoAssetWritingError.assetSaveFailed
        }
    }
}

private extension LivePhotoWritableResourceKind {

    var photoKitResourceType:
        PHAssetResourceType {

        switch self {
        case .photo:
            return .photo
        case .pairedVideo:
            return .pairedVideo
        }
    }
}
#endif
