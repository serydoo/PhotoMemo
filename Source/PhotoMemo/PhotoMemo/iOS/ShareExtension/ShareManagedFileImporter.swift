#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import CryptoKit
import Foundation
import UniformTypeIdentifiers
import UIKit

@MainActor
struct ShareManagedFileImporter {

    enum ManagedImportOutcome {

        case imported(
            ManagedImportRecord
        )

        case skippedDuplicate

        case skippedUnsupported(
            PhotoMemoMediaIntakeRejectionReport
        )

        case failed(
            PhotoMemoShareIntakeFailureContext
        )
    }

    struct ManagedImportRecord {

        let item:
            ExternalPhotoIntakeItem

        let dedupeKey: String

        let livePhotoStaticFallback:
            Bool

        init(
            item: ExternalPhotoIntakeItem,
            dedupeKey: String,
            livePhotoStaticFallback: Bool = false
        ) {
            self.item = item
            self.dedupeKey = dedupeKey
            self.livePhotoStaticFallback =
                livePhotoStaticFallback
        }

        var managedURL: URL {
            item.managedURL
        }
    }

    struct FileRepresentationLoadResult {

        let importRecord:
            ManagedImportRecord?

        let failureContext:
            PhotoMemoShareIntakeFailureContext?
    }

    private let intakeStore:
        ExternalPhotoIntakeStore

    private let providerLoader:
        ShareItemProviderLoader

    private let livePhotoRecovery:
        ShareLivePhotoRecovery

    private let diagnostics:
        ShareIntakeDiagnostics

    init(
        intakeStore: ExternalPhotoIntakeStore,
        providerLoader: ShareItemProviderLoader,
        livePhotoRecovery: ShareLivePhotoRecovery,
        diagnostics: ShareIntakeDiagnostics
    ) {
        self.intakeStore = intakeStore
        self.providerLoader = providerLoader
        self.livePhotoRecovery =
            livePhotoRecovery
        self.diagnostics = diagnostics
    }

    func loadManagedURL(
        from provider: NSItemProvider,
        requestID: UUID,
        index: Int,
        itemProviderCount: Int,
        supportedProviderCount: Int,
        seenSourceKeys: inout Set<String>
    ) async -> ManagedImportOutcome {

        let registeredTypeIdentifiers =
            provider
            .registeredTypeIdentifiers
        let preferredTypeIdentifier =
            providerLoader
            .preferredImportTypeIdentifier(
                from:
                    registeredTypeIdentifiers
            )
        let preferredStaticImageTypeIdentifier =
            providerLoader
            .preferredImageTypeIdentifier(
                from:
                    registeredTypeIdentifiers
            )
        let diagnosticsSeed =
            PhotoMemoShareIntakeOperationSeed(
                itemProviderCount:
                    itemProviderCount,
                supportedProviderCount:
                    supportedProviderCount,
                providerIndex: index,
                requestedTypeIdentifier:
                    UTType.image.identifier,
                preferredRegisteredTypeIdentifier:
                    preferredTypeIdentifier
            )

        ShareIntakeDiagnostics.notice(
            "Provider[\(index)] selectedUTType=\(UTType.image.identifier) preferredUTType=\(preferredTypeIdentifier ?? "unknown")"
        )

        if let livePhotoTypeIdentifier =
            providerLoader
            .preferredLivePhotoTypeIdentifier(
                from: registeredTypeIdentifiers
            ) {
            let liveFileLoadResult =
                await loadFileRepresentationResult(
                    from: provider,
                    requestID: requestID,
                    index: index,
                    diagnosticsSeed:
                        PhotoMemoShareIntakeOperationSeed(
                            itemProviderCount:
                                itemProviderCount,
                            supportedProviderCount:
                                supportedProviderCount,
                            providerIndex: index,
                            requestedTypeIdentifier:
                                livePhotoTypeIdentifier,
                            preferredRegisteredTypeIdentifier:
                                livePhotoTypeIdentifier
                        ),
                    requestedTypeIdentifier:
                        livePhotoTypeIdentifier,
                    allowsDirectoryPackage:
                        true
                )

            if let importRecord =
                liveFileLoadResult.importRecord {

                let resolvedImportRecord =
                    livePhotoRecovery
                    .recordStaticLivePhotoPayloadIfNeeded(
                        importRecord,
                        requestedTypeIdentifier:
                            livePhotoTypeIdentifier,
                        requestID: requestID,
                        index: index
                    )

                if let unsupportedOutcome =
                    unsupportedManagedImportOutcomeIfNeeded(
                        resolvedImportRecord,
                        diagnosticsSeed:
                            diagnosticsSeed
                    ) {
                    return unsupportedOutcome
                }

                let sourceKey =
                    resolvedImportRecord.dedupeKey

                guard seenSourceKeys.insert(sourceKey)
                    .inserted else {
                    intakeStore
                        .cleanupManagedSourceIfNeeded(
                            at: resolvedImportRecord.managedURL
                        )
                    return .skippedDuplicate
                }

                return .imported(
                    resolvedImportRecord
                )
            }
        }

        let staticDiagnosticsSeed =
            PhotoMemoShareIntakeOperationSeed(
                itemProviderCount:
                    itemProviderCount,
                supportedProviderCount:
                    supportedProviderCount,
                providerIndex: index,
                requestedTypeIdentifier:
                    UTType.image.identifier,
                preferredRegisteredTypeIdentifier:
                    preferredStaticImageTypeIdentifier
                    ?? UTType.image.identifier
            )
        let shouldMarkLivePhotoStaticFallback =
            providerLoader
            .supportsLivePhoto(
                registeredTypeIdentifiers
            )
        let fileLoadResult =
            await loadFileRepresentationResult(
                from: provider,
                requestID: requestID,
                index: index,
                diagnosticsSeed:
                    staticDiagnosticsSeed
            )

        if let importRecord =
            fileLoadResult.importRecord {

            let resolvedImportRecord =
                shouldMarkLivePhotoStaticFallback
                ? livePhotoRecovery
                .recordStaticLivePhotoPayloadIfNeeded(
                    importRecord,
                    requestedTypeIdentifier:
                        preferredTypeIdentifier
                        ?? "unknown",
                    requestID: requestID,
                    index: index
                )
                : importRecord

            if let unsupportedOutcome =
                unsupportedManagedImportOutcomeIfNeeded(
                    resolvedImportRecord,
                    diagnosticsSeed:
                        staticDiagnosticsSeed
                ) {
                return unsupportedOutcome
            }

            let sourceKey =
                resolvedImportRecord.dedupeKey

            guard
                seenSourceKeys.insert(sourceKey)
                    .inserted
            else {
                intakeStore
                    .cleanupManagedSourceIfNeeded(
                        at: resolvedImportRecord.managedURL
                    )
                return .skippedDuplicate
            }

            return .imported(
                resolvedImportRecord
            )
        }

        let fallbackResult =
            await loadFallbackItem(
                from: provider,
                requestID: requestID,
                index: index,
                diagnosticsSeed:
                    staticDiagnosticsSeed
            )

        if case .failed(let failureContext) =
            fallbackResult {
            return .failed(
                failureContext
            )
        }

        if case .imported(let imported) =
            fallbackResult {

            let resolvedImported =
                shouldMarkLivePhotoStaticFallback
                ? livePhotoRecovery
                .recordStaticLivePhotoPayloadIfNeeded(
                    imported,
                    requestedTypeIdentifier:
                        preferredTypeIdentifier
                        ?? "unknown",
                    requestID: requestID,
                    index: index
                )
                : imported

            if let unsupportedOutcome =
                unsupportedManagedImportOutcomeIfNeeded(
                    resolvedImported,
                    diagnosticsSeed:
                        staticDiagnosticsSeed
                ) {
                return unsupportedOutcome
            }

            let sourceKey =
                resolvedImported.dedupeKey

            guard
                seenSourceKeys.insert(sourceKey)
                    .inserted
            else {
                intakeStore
                    .cleanupManagedSourceIfNeeded(
                        at: resolvedImported
                        .managedURL
                    )
                return .skippedDuplicate
            }

            return .imported(
                resolvedImported
            )
        }

        if let failureContext =
            fileLoadResult
            .failureContext {
            return .failed(
                failureContext
            )
        }

        let error =
            PhotoMemoShareIntakeDiagnosticError
            .make(
                description:
                    "Share intake finished without a loadable file or fallback item.",
                code: 1006
            )

        return .failed(
            diagnosticsSeed
            .failureContext(
                stage: .completion,
                operation:
                    "loadManagedURL.noLoadableResult",
                error: error
            )
        )
    }
}

private extension ShareManagedFileImporter {

    func loadFileRepresentationResult(
        from provider: NSItemProvider,
        requestID: UUID,
        index: Int,
        diagnosticsSeed:
            PhotoMemoShareIntakeOperationSeed,
        requestedTypeIdentifier: String =
            UTType.image.identifier,
        allowsDirectoryPackage: Bool = false
    ) async -> FileRepresentationLoadResult {

        ShareIntakeDiagnostics.notice(
            "Provider[\(diagnosticsSeed.providerIndex ?? -1)] loadFileRepresentation start for \(requestedTypeIdentifier)"
        )

        let suggestedName =
            provider.suggestedName

        return await withCheckedContinuation {
            (
                continuation:
                    CheckedContinuation<
                        FileRepresentationLoadResult,
                        Never
                    >
            ) in

            provider.loadFileRepresentation(
                forTypeIdentifier:
                    requestedTypeIdentifier
            ) { [intakeStore] url, error in

                if let error {
                    let wrappedError =
                        PhotoMemoShareIntakeDiagnosticError
                        .make(
                            description:
                                "loadFileRepresentation returned an error.",
                            code: 3001,
                            underlyingError: error
                        )
                    let failureContext =
                        diagnosticsSeed
                        .failureContext(
                            stage: .load,
                            operation:
                                "loadFileRepresentation",
                            returnedURL:
                                url,
                            error:
                                wrappedError
                        )

                    ShareIntakeDiagnostics.error(
                        "Provider[\(diagnosticsSeed.providerIndex ?? -1)] loadFileRepresentation failed.\n\(failureContext.debugDescription)"
                    )

                    continuation.resume(
                        returning:
                            FileRepresentationLoadResult(
                                importRecord: nil,
                                failureContext:
                                    failureContext
                            )
                    )
                    return
                }

                guard let url else {
                    let failureContext =
                        diagnosticsSeed
                        .failureContext(
                            stage: .load,
                            operation:
                                "loadFileRepresentation.missingURL",
                            error:
                                PhotoMemoShareIntakeDiagnosticError
                                .make(
                                    description:
                                        "loadFileRepresentation completed without returning a URL.",
                                    code: 3002
                                )
                        )

                    ShareIntakeDiagnostics.error(
                        "Provider[\(diagnosticsSeed.providerIndex ?? -1)] loadFileRepresentation returned nil URL.\n\(failureContext.debugDescription)"
                    )

                    continuation.resume(
                        returning:
                            FileRepresentationLoadResult(
                                importRecord: nil,
                                failureContext:
                                    failureContext
                            )
                    )
                    return
                }

                ShareIntakeDiagnostics.notice(
                    "Provider[\(diagnosticsSeed.providerIndex ?? -1)] loadFileRepresentation returnedURL=\(url.standardizedFileURL.path)"
                )

                let sourceReadiness =
                    PhotoMemoImageFileReadiness
                    .probe(
                        at: url.standardizedFileURL
                    )
                ShareIntakeDiagnostics
                    .recordSourcePreparationIfNeeded(
                        sourceReadiness,
                        requestID: requestID,
                        index: index
                    )

                let originalFileName =
                    Self.resolvedOriginalFileName(
                        preferredName:
                            suggestedName,
                        sourceURL: url
                    )

                let copyResult =
                    intakeStore
                        .createManagedCopyDetailed(
                            from: url,
                            requestID: requestID,
                            index: index,
                            preferredOriginalFileName:
                                originalFileName,
                            requiresReadableImage:
                                !allowsDirectoryPackage,
                            diagnosticsSeed:
                                diagnosticsSeed
                        )

                ShareIntakeDiagnostics.notice(
                    "Provider[\(diagnosticsSeed.providerIndex ?? -1)] temporaryCopyResult=\(copyResult.temporaryCopyResult ?? "none") sharedContainerDestination=\(copyResult.sharedContainerDestination?.path ?? "nil")"
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
                    continuation.resume(
                        returning:
                            FileRepresentationLoadResult(
                                importRecord: nil,
                                failureContext:
                                    copyResult
                                    .failureContext
                                    ?? diagnosticsSeed
                                    .failureContext(
                                        stage: .copy,
                                        operation:
                                            "loadFileRepresentation.copyURL.missingManagedURL",
                                        returnedURL:
                                            url,
                                        temporaryCopyResult:
                                            copyResult
                                            .temporaryCopyResult
                                            ?? "missing-managed-url",
                                        sharedContainerDestination:
                                            copyResult
                                            .sharedContainerDestination,
                                        error:
                                            PhotoMemoShareIntakeDiagnosticError
                                            .make(
                                                description:
                                                    "File representation copy did not produce a managed URL.",
                                                code: 3007
                                            )
                                    )
                            )
                    )
                    return
                }

                ShareIntakeDiagnostics
                    .recordSourceReadyIfNeeded(
                        sourceReadiness,
                        requestID: requestID,
                        index: index
                    )

                continuation.resume(
                    returning:
                        FileRepresentationLoadResult(
                            importRecord:
                                ManagedImportRecord(
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
                                        url
                                        .standardizedFileURL
                                        .path
                                ),
                            failureContext: nil
                        )
                )
            }
        }
    }

    func loadFallbackItem(
        from provider: NSItemProvider,
        requestID: UUID,
        index: Int,
        diagnosticsSeed:
            PhotoMemoShareIntakeOperationSeed
    ) async -> ManagedImportOutcome {

        let suggestedName =
            provider.suggestedName

        let preferredExtension =
            providerLoader
            .preferredFileExtension(
                from:
                    provider
                    .registeredTypeIdentifiers
            )

        ShareIntakeDiagnostics.notice(
            "Provider[\(index)] loadItem start for \(UTType.image.identifier)"
        )

        return await withCheckedContinuation {
            (
                continuation:
                    CheckedContinuation<
                        ManagedImportOutcome,
                        Never
                    >
            ) in

            provider.loadItem(
                forTypeIdentifier:
                    UTType.image.identifier,
                options: nil
            ) { [intakeStore] item, error in

                if let error {
                    let wrappedError =
                        PhotoMemoShareIntakeDiagnosticError
                        .make(
                            description:
                                "Fallback loadItem returned an error.",
                            code: 3003,
                            underlyingError: error
                        )

                    let failureContext =
                        diagnosticsSeed
                        .failureContext(
                            stage: .load,
                            operation:
                                "loadItem",
                            error:
                                wrappedError
                        )

                    ShareIntakeDiagnostics.error(
                        "Provider[\(index)] loadItem failed.\n\(failureContext.debugDescription)"
                    )

                    continuation.resume(
                        returning:
                            .failed(
                                failureContext
                            )
                    )
                    return
                }

                if let url = item as? URL {
                    let normalizedURL =
                        url.standardizedFileURL

                    ShareIntakeDiagnostics.notice(
                        "Provider[\(index)] loadItem returnedURL=\(normalizedURL.path)"
                    )

                    let sourceReadiness =
                        PhotoMemoImageFileReadiness
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
                        Self.resolvedOriginalFileName(
                            preferredName:
                                suggestedName,
                            sourceURL:
                                normalizedURL
                        )

                    let copyResult =
                        intakeStore
                        .createManagedCopyDetailed(
                            from: normalizedURL,
                            requestID: requestID,
                            index: index,
                            preferredOriginalFileName:
                                originalFileName,
                            diagnosticsSeed:
                                diagnosticsSeed
                        )

                    ShareIntakeDiagnostics.notice(
                        "Provider[\(index)] fallback temporaryCopyResult=\(copyResult.temporaryCopyResult ?? "none") sharedContainerDestination=\(copyResult.sharedContainerDestination?.path ?? "nil")"
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
                        continuation.resume(
                            returning:
                                .failed(
                                    copyResult
                                    .failureContext
                                    ?? diagnosticsSeed
                                    .failureContext(
                                        stage: .copy,
                                        operation:
                                            "loadItem.copyURL.missingManagedURL",
                                        returnedURL:
                                            normalizedURL,
                                        temporaryCopyResult:
                                            copyResult
                                            .temporaryCopyResult
                                            ?? "missing-managed-url",
                                        sharedContainerDestination:
                                            copyResult
                                            .sharedContainerDestination,
                                        error:
                                            PhotoMemoShareIntakeDiagnosticError
                                            .make(
                                                description:
                                                    "Fallback URL copy did not produce a managed URL.",
                                                code: 3004
                                            )
                                    )
                                )
                        )
                        return
                    }

                    ShareIntakeDiagnostics
                        .recordSourceReadyIfNeeded(
                            sourceReadiness,
                            requestID: requestID,
                            index: index
                        )

                    continuation.resume(
                        returning:
                            .imported(
                                ManagedImportRecord(
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
                                        "url:\(normalizedURL.path)"
                                )
                            )
                    )
                    return
                }

                if let data = item as? Data {
                    ShareIntakeDiagnostics.notice(
                        "Provider[\(index)] loadItem returnedDataBytes=\(data.count)"
                    )

                    let copyResult =
                        intakeStore
                        .createManagedCopyDetailed(
                            fromData: data,
                            requestID: requestID,
                            index: index,
                            preferredFileExtension:
                                preferredExtension,
                            preferredBaseName:
                                suggestedName,
                            diagnosticsSeed:
                                diagnosticsSeed
                        )

                    ShareIntakeDiagnostics.notice(
                        "Provider[\(index)] fallback temporaryCopyResult=\(copyResult.temporaryCopyResult ?? "none") sharedContainerDestination=\(copyResult.sharedContainerDestination?.path ?? "nil")"
                    )

                    guard let managedURL =
                        copyResult.managedURL
                    else {
                        continuation.resume(
                            returning:
                                .failed(
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
                                            PhotoMemoShareIntakeDiagnosticError
                                            .make(
                                                description:
                                                    "Fallback data copy did not produce a managed URL.",
                                                code: 3005
                                            )
                                    )
                                )
                        )
                        return
                    }

                    continuation.resume(
                        returning:
                            .imported(
                                ManagedImportRecord(
                                    item:
                                        ExternalPhotoIntakeItem(
                                            managedURL:
                                                managedURL,
                                            originalFileName:
                                                Self.resolvedOriginalFileName(
                                                    preferredName:
                                                        suggestedName
                                                ),
                                            sourceIdentifier:
                                                Self
                                                .fallbackDataSourceIdentifier(
                                                    for: data,
                                                    suggestedName:
                                                        suggestedName,
                                                    contentTypeIdentifier:
                                                        diagnosticsSeed
                                                        .preferredRegisteredTypeIdentifier
                                                ),
                                            contentTypeIdentifier:
                                                diagnosticsSeed
                                                .preferredRegisteredTypeIdentifier
                                        ),
                                    dedupeKey:
                                        Self
                                        .dedupeKey(
                                            for: data,
                                            suggestedName:
                                                suggestedName
                                        )
                                )
                            )
                    )
                    return
                }

                let failureContext =
                    diagnosticsSeed
                    .failureContext(
                        stage: .load,
                        operation:
                            "loadItem.unsupportedPayload",
                        error:
                            PhotoMemoShareIntakeDiagnosticError
                            .make(
                                description:
                                    "Fallback loadItem returned an unsupported payload type.",
                                code: 3006
                            )
                    )

                ShareIntakeDiagnostics.error(
                    "Provider[\(index)] loadItem returned unsupported payload.\n\(failureContext.debugDescription)"
                )

                continuation.resume(
                    returning:
                        .failed(
                            failureContext
                        )
                )
            }
        }
    }

    func unsupportedManagedImportOutcomeIfNeeded(
        _ importRecord: ManagedImportRecord,
        diagnosticsSeed:
            PhotoMemoShareIntakeOperationSeed
    ) -> ManagedImportOutcome? {

        let verdict =
            PhotoProcessingInputPolicy(
                allowsLivePhoto: true
            )
            .verdict(
                fileURL:
                    importRecord.managedURL,
                declaredContentTypeIdentifier:
                    importRecord.item
                    .contentTypeIdentifier
            )

        guard !verdict.isSupported else {
            return nil
        }

        intakeStore.cleanupManagedSourceIfNeeded(
            at: importRecord.managedURL
        )

        ShareIntakeDiagnostics.notice(
            """
            Provider[\(diagnosticsSeed.providerIndex ?? -1)] skipped unsupported photo.
            reason=\(verdict.reason?.rawValue ?? "unknown")
            title=\(verdict.title)
            message=\(verdict.message)
            """
        )

        let rejectionReport =
            PhotoMemoMediaIntakeRejectionReport(
                verdict: verdict,
                fileName:
                    importRecord
                    .managedURL
                    .lastPathComponent,
                contentTypeIdentifier:
                    importRecord.item
                    .contentTypeIdentifier,
                pixelSize:
                    MediaPixelSize(
                        fileURL:
                            importRecord
                            .managedURL
                    )
            )

        return .skippedUnsupported(
            rejectionReport
        )
    }

    nonisolated static
    func fallbackDataSourceIdentifier(
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

    nonisolated static
    func resolvedOriginalFileName(
        preferredName: String?,
        sourceURL: URL? = nil
    ) -> String? {

        PhotoFileNameResolver
            .sanitizedOriginalFileName(
                preferredName
            )
            ?? PhotoFileNameResolver
            .sanitizedOriginalFileName(
                sourceURL?
                .lastPathComponent
            )
    }

    nonisolated static
    func dedupeKey(
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
