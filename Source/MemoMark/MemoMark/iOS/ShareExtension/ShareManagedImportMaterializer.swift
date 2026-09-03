#if os(iOS) && MEMOMARK_SHARE_EXTENSION
import Foundation
import CryptoKit
import Photos
import UniformTypeIdentifiers

/// Converts a provider-owned file URL into a durable App Group intake record.
///
/// Provider loading and fallback order remain owned by `ShareManagedFileImporter`.
/// This collaborator owns only source readiness evidence, the managed copy, and
/// the resulting `ExternalPhotoIntakeItem` so every URL representation follows
/// the same durable-copy contract.
struct ShareManagedImportMaterializer {

    private let intakeStore:
        ExternalPhotoIntakeStore

    init(
        intakeStore: ExternalPhotoIntakeStore
    ) {
        self.intakeStore = intakeStore
    }

    func materializeFileURL(
        _ sourceURL: URL,
        requestID: UUID,
        index: Int,
        preferredName: String?,
        diagnosticsSeed: MemoMarkShareIntakeOperationSeed,
        requiresReadableImage: Bool = true,
        dedupeKey: String,
        copyDiagnosticPrefix: String,
        missingManagedURLOperation: String,
        missingManagedURLDescription: String,
        missingManagedURLErrorCode: Int
    ) -> ShareManagedFileImporter.FileRepresentationLoadResult {

        let normalizedURL = sourceURL.standardizedFileURL
        let sourceReadiness =
            MemoMarkImageFileReadiness
            .probe(
                at: normalizedURL
            )
        ShareIntakeDiagnostics
            .recordSourcePreparationIfNeeded(
                sourceReadiness,
                requestID: requestID,
                index: index
            )

        let originalFileName =
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                preferredName
            )
            ?? PhotoFileNameResolver
            .sanitizedOriginalFileName(
                normalizedURL.lastPathComponent
            )

        let copyResult =
            intakeStore
            .createManagedCopyDetailed(
                from: sourceURL,
                requestID: requestID,
                index: index,
                preferredOriginalFileName:
                    originalFileName,
                requiresReadableImage:
                    requiresReadableImage,
                diagnosticsSeed:
                    diagnosticsSeed
            )

        ShareIntakeDiagnostics.notice(
            "Provider[\(index)] \(copyDiagnosticPrefix) temporaryCopyResult=\(copyResult.temporaryCopyResult ?? "none") managedDestinationCreated=\(copyResult.sharedContainerDestination != nil)"
        )

        guard let managedURL =
            copyResult.managedURL
        else {
            ShareIntakeDiagnostics
                .recordSourceUnavailableIfNeeded(
                    sourceReadiness,
                    copyResult:
                        copyResult,
                    requestID:
                        requestID,
                    index:
                        index
                )

            return ShareManagedFileImporter
                .FileRepresentationLoadResult(
                    importRecord: nil,
                    failureContext:
                        copyResult
                        .failureContext
                        ?? diagnosticsSeed
                        .failureContext(
                            stage: .copy,
                            operation:
                                missingManagedURLOperation,
                            returnedURL:
                                sourceURL,
                            temporaryCopyResult:
                                copyResult
                                .temporaryCopyResult
                                ?? "missing-managed-url",
                            sharedContainerDestination:
                                copyResult
                                .sharedContainerDestination,
                            error:
                                MemoMarkShareIntakeDiagnosticError
                                .make(
                                    description:
                                        missingManagedURLDescription,
                                    code:
                                        missingManagedURLErrorCode
                                )
                        )
                )
        }

        ShareIntakeDiagnostics
            .recordSourceReadyIfNeeded(
                sourceReadiness,
                requestID: requestID,
                index: index
            )

        return ShareManagedFileImporter
            .FileRepresentationLoadResult(
                importRecord:
                    ShareManagedFileImporter
                    .ManagedImportRecord(
                        item:
                            ExternalPhotoIntakeItem(
                                managedURL:
                                    managedURL,
                                originalFileName:
                                    originalFileName,
                                contentTypeIdentifier:
                                    diagnosticsSeed
                                    .preferredRegisteredTypeIdentifier
                            ),
                        dedupeKey:
                            dedupeKey
                    ),
                failureContext: nil
            )
    }

    /// Materializes the object-only Live Photo representation that recent
    /// Photos share providers expose when they cannot vend a file package.
    /// The paired resources are copied into a fresh directory with a shared
    /// basename so the existing production Live Photo path can consume it.
    @MainActor
    func materializeLivePhotoObject(
        _ livePhoto: PHLivePhoto,
        requestID: UUID,
        index: Int,
        preferredName: String?,
        diagnosticsSeed: MemoMarkShareIntakeOperationSeed
    ) async -> ShareManagedFileImporter.FileRepresentationLoadResult {

        do {
            try Task.checkCancellation()
        } catch {
            return livePhotoObjectFailure(
                requestID: requestID,
                diagnosticsSeed: diagnosticsSeed,
                operation: "loadObject(PHLivePhoto).cancelled",
                description: "Live Photo resource materialization was cancelled before it could begin.",
                code: 3204,
                underlyingError: error
            )
        }

        let resources =
            PHAssetResource.assetResources(
                for: livePhoto
            )
        guard let stillResource =
                preferredStillResource(
                    from: resources
                ),
              let pairedVideoResource =
                preferredPairedVideoResource(
                    from: resources
                )
        else {
            return livePhotoObjectFailure(
                requestID: requestID,
                diagnosticsSeed: diagnosticsSeed,
                operation:
                    "loadObject(PHLivePhoto).resolvePairedResources",
                description:
                    "The PHLivePhoto object did not expose both a still image and paired video resource.",
                code: 3201
            )
        }

        let temporaryBundleURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                "MemoMark-LivePhoto-\(UUID().uuidString)",
                isDirectory: true
            )
            .appendingPathExtension(
                "livephoto"
            )

        do {
            try FileManager.default.createDirectory(
                at: temporaryBundleURL,
                withIntermediateDirectories: true
            )
            defer {
                try? FileManager.default.removeItem(
                    at: temporaryBundleURL
                )
            }

            let baseName =
                livePhotoBundleBaseName(
                    preferredName: preferredName
                )
            let stillURL =
                temporaryBundleURL
                .appendingPathComponent(
                    baseName
                )
                .appendingPathExtension(
                    preferredFilenameExtension(
                        for: stillResource,
                        fallback: "heic"
                    )
                )
            let pairedVideoURL =
                temporaryBundleURL
                .appendingPathComponent(
                    baseName
                )
                .appendingPathExtension(
                    preferredFilenameExtension(
                        for: pairedVideoResource,
                        fallback: "mov"
                    )
                )

            try await writeLivePhotoResource(
                stillResource,
                to: stillURL
            )
            try Task.checkCancellation()
            try await writeLivePhotoResource(
                pairedVideoResource,
                to: pairedVideoURL
            )
            try Task.checkCancellation()

            MemoMarkShareDiagnostics.record(
                stage:
                    .extensionLivePhotoRepresentationProbe,
                message: [
                    "operation=loadObject(PHLivePhoto)",
                    "providerIndex=\(index)",
                    "result=pairedResourcesMaterialized",
                    "stillType=\(stillResource.uniformTypeIdentifier)",
                    "videoType=\(pairedVideoResource.uniformTypeIdentifier)"
                ]
                .joined(separator: ", "),
                requestID: requestID
            )

            return materializeFileURL(
                temporaryBundleURL,
                requestID: requestID,
                index: index,
                preferredName: preferredName,
                diagnosticsSeed: diagnosticsSeed,
                requiresReadableImage:
                    false,
                dedupeKey:
                    "live-photo-object:\(requestID.uuidString)-\(index)",
                copyDiagnosticPrefix:
                    "Live Photo object",
                missingManagedURLOperation:
                    "loadObject(PHLivePhoto).copyBundle.missingManagedURL",
                missingManagedURLDescription:
                    "The Live Photo object resources could not be copied into the shared container.",
                missingManagedURLErrorCode: 3202
            )
        } catch {
            return livePhotoObjectFailure(
                requestID: requestID,
                diagnosticsSeed: diagnosticsSeed,
                operation:
                    "loadObject(PHLivePhoto).writePairedResources",
                description:
                    "The PHLivePhoto paired resources could not be materialized.",
                code: 3203,
                underlyingError: error
            )
        }
    }

    func materializeData(
        _ data: Data,
        requestID: UUID,
        index: Int,
        preferredFileExtension: String?,
        preferredBaseName: String?,
        diagnosticsSeed: MemoMarkShareIntakeOperationSeed
    ) -> ShareManagedFileImporter.FileRepresentationLoadResult {

        let copyResult =
            intakeStore
            .createManagedCopyDetailed(
                fromData: data,
                requestID: requestID,
                index: index,
                preferredFileExtension:
                    preferredFileExtension,
                preferredBaseName:
                    preferredBaseName,
                diagnosticsSeed:
                    diagnosticsSeed
            )

        ShareIntakeDiagnostics.notice(
            "Provider[\(index)] fallback temporaryCopyResult=\(copyResult.temporaryCopyResult ?? "none") managedDestinationCreated=\(copyResult.sharedContainerDestination != nil)"
        )

        guard let managedURL =
            copyResult.managedURL
        else {
            return ShareManagedFileImporter
                .FileRepresentationLoadResult(
                    importRecord: nil,
                    failureContext:
                        copyResult
                        .failureContext
                        ?? diagnosticsSeed
                        .failureContext(
                            stage: .copy,
                            operation:
                                "loadItem.copyData.missingManagedURL",
                            temporaryCopyResult:
                                copyResult
                                .temporaryCopyResult
                                ?? "missing-managed-url",
                            sharedContainerDestination:
                                copyResult
                                .sharedContainerDestination,
                            error:
                                MemoMarkShareIntakeDiagnosticError
                                .make(
                                    description:
                                        "Fallback data copy did not produce a managed URL.",
                                    code: 3005
                                )
                        )
                )
        }

        let contentTypeIdentifier =
            diagnosticsSeed
            .preferredRegisteredTypeIdentifier

        return ShareManagedFileImporter
            .FileRepresentationLoadResult(
                importRecord:
                    ShareManagedFileImporter
                    .ManagedImportRecord(
                        item:
                            ExternalPhotoIntakeItem(
                                managedURL:
                                    managedURL,
                                originalFileName:
                                    PhotoFileNameResolver
                                    .sanitizedOriginalFileName(
                                        preferredBaseName
                                    ),
                                sourceIdentifier:
                                    fallbackDataSourceIdentifier(
                                        for: data,
                                        suggestedName:
                                            preferredBaseName,
                                        contentTypeIdentifier:
                                            contentTypeIdentifier
                                    ),
                                contentTypeIdentifier:
                                    contentTypeIdentifier
                            ),
                        dedupeKey:
                            dedupeKey(
                                for: data,
                                suggestedName:
                                    preferredBaseName
                            )
                    ),
                failureContext: nil
            )
    }

    private func preferredStillResource(
        from resources: [PHAssetResource]
    ) -> PHAssetResource? {

        resources.first {
            $0.type == .fullSizePhoto
        }
        ?? resources.first {
            $0.type == .photo
        }
        ?? resources.first {
            $0.type == .alternatePhoto
        }
    }

    private func preferredPairedVideoResource(
        from resources: [PHAssetResource]
    ) -> PHAssetResource? {

        resources.first {
            $0.type == .fullSizePairedVideo
        }
        ?? resources.first {
            $0.type == .pairedVideo
        }
    }

    private func preferredFilenameExtension(
        for resource: PHAssetResource,
        fallback: String
    ) -> String {

        if let type = UTType(
            resource.uniformTypeIdentifier
        ),
           let filenameExtension =
            type.preferredFilenameExtension {
            return filenameExtension
        }

        let resourceExtension =
            URL(
                fileURLWithPath:
                    resource.originalFilename
            )
            .pathExtension

        return resourceExtension.isEmpty
            ? fallback
            : resourceExtension
    }

    private func livePhotoBundleBaseName(
        preferredName: String?
    ) -> String {

        let sanitizedName =
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                preferredName
            )
        let candidate =
            sanitizedName.map {
                URL(fileURLWithPath: $0)
                    .deletingPathExtension()
                    .lastPathComponent
            }
            ?? "MemoMark Live Photo"
        let trimmed =
            candidate.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty
            ? "MemoMark Live Photo"
            : trimmed
    }

    private func writeLivePhotoResource(
        _ resource: PHAssetResource,
        to targetURL: URL
    ) async throws {

        let options =
            PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true

        try await withCheckedThrowingContinuation {
            (
                continuation:
                    CheckedContinuation<Void, Error>
            ) in

            PHAssetResourceManager.default()
                .writeData(
                    for: resource,
                    toFile: targetURL,
                    options: options
                ) { error in
                    if let error {
                        continuation.resume(
                            throwing: error
                        )
                        return
                    }

                    continuation.resume()
                }
        }
    }

    private func livePhotoObjectFailure(
        requestID: UUID,
        diagnosticsSeed: MemoMarkShareIntakeOperationSeed,
        operation: String,
        description: String,
        code: Int,
        underlyingError: Error? = nil
    ) -> ShareManagedFileImporter.FileRepresentationLoadResult {

        let failureContext =
            diagnosticsSeed
            .failureContext(
                stage: .load,
                operation: operation,
                error:
                    MemoMarkShareIntakeDiagnosticError
                    .make(
                        description: description,
                        code: code,
                        underlyingError: underlyingError
                    )
            )

        ShareIntakeDiagnostics.error(
            "Provider[\(diagnosticsSeed.providerIndex ?? -1)] \(operation) failed.\n\(failureContext.debugDescription)"
        )
        MemoMarkShareDiagnostics.record(
            stage:
                .extensionLivePhotoRepresentationProbe,
            message: [
                "operation=\(operation)",
                "providerIndex=\(diagnosticsSeed.providerIndex ?? -1)",
                "result=failed",
                "error=\(failureContext.errorSummary?.domain ?? "unknown")/\(failureContext.errorSummary?.code ?? 0)"
            ]
            .joined(separator: ", "),
            requestID: requestID
        )

        return ShareManagedFileImporter
            .FileRepresentationLoadResult(
                importRecord: nil,
                failureContext: failureContext
            )
    }

    private func fallbackDataSourceIdentifier(
        for data: Data,
        suggestedName: String?,
        contentTypeIdentifier: String?
    ) -> String? {

        guard !PhotoProcessingInputPolicy
            .isLivePhotoContentType(
                contentTypeIdentifier
                .flatMap(UTType.init)
            )
        else {
            return nil
        }

        return dedupeKey(
            for: data,
            suggestedName:
                suggestedName
        )
    }

    private func dedupeKey(
        for data: Data,
        suggestedName: String?
    ) -> String {

        let digest =
            SHA256.hash(data: data)
                .compactMap {
                    String(
                        format: "%02x",
                        $0
                    )
                }
                .joined()

        let normalizedName =
            suggestedName?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        if normalizedName.isEmpty {
            return "data:\(digest)"
        }

        return "data:\(digest):\(normalizedName)"
    }
}
#endif
