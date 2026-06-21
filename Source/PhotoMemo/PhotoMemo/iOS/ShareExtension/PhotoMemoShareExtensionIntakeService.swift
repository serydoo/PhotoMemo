#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import Foundation
import CryptoKit
import UniformTypeIdentifiers
import UIKit

struct PhotoMemoShareExtensionError:
    LocalizedError {

    enum Kind {

        case noSupportedImages

        case allImportsFailed

        case persistFailed
    }

    let kind: Kind

    let importResult:
        PhotoMemoShareExtensionImportResult?

    let failureContext:
        PhotoMemoShareIntakeFailureContext?

    init(
        kind: Kind,
        importResult:
            PhotoMemoShareExtensionImportResult? = nil,
        failureContext:
            PhotoMemoShareIntakeFailureContext? = nil
    ) {
        self.kind = kind
        self.importResult = importResult
        self.failureContext =
            failureContext
    }

    static let noSupportedImages =
        PhotoMemoShareExtensionError(
            kind: .noSupportedImages
        )

    static func allImportsFailed(
        result:
            PhotoMemoShareExtensionImportResult,
        failureContext:
            PhotoMemoShareIntakeFailureContext?
    ) -> PhotoMemoShareExtensionError {

        PhotoMemoShareExtensionError(
            kind: .allImportsFailed,
            importResult: result,
            failureContext:
                failureContext
        )
    }

    static func persistFailed(
        result:
            PhotoMemoShareExtensionImportResult,
        failureContext:
            PhotoMemoShareIntakeFailureContext?
    ) -> PhotoMemoShareExtensionError {

        PhotoMemoShareExtensionError(
            kind: .persistFailed,
            importResult: result,
            failureContext:
                failureContext
        )
    }

    var resolvedFailureContext:
        PhotoMemoShareIntakeFailureContext? {

        failureContext
        ?? importResult?.failureContext
    }

    var errorDescription: String? {

        switch kind {

        case .noSupportedImages:
            return "这次分享里没有找到可直接处理的照片。"

        case .allImportsFailed:
            return "这次分享里的照片暂时没有成功交给 PhotoMemo。"

        case .persistFailed:
            return "PhotoMemo 暂时无法记录这次分享。"
        }
    }

    var failureTitle: String {

        switch kind {

        case .noSupportedImages:
            return "没有识别到可处理照片"

        case .allImportsFailed:
            return "照片没有成功交给 PhotoMemo"

        case .persistFailed:
            return "这次分享没有保存下来"
        }
    }

    var recoverySuggestion: String {

        switch kind {

        case .noSupportedImages:
            return "请尽量从系统相册直接分享原始照片；如果来自其他 App，请确认分享的是原图而不是预览图。"

        case .allImportsFailed:
            return "请直接点击重试；如果仍失败，请返回系统相册重新分享，或打开 PhotoMemo 检查默认风格。"

        case .persistFailed:
            return "请先重试一次；如果重复出现，请打开 PhotoMemo 检查共享容器、默认风格和系统相册权限。"
        }
    }

    var diagnosticSummaryLine: String? {

        guard let failureContext =
            resolvedFailureContext
        else {
            return nil
        }

        var parts = [
            "失败阶段：\(failureContext.stage.title)"
        ]

        if let errorSummary =
            failureContext.errorSummary {
            parts.append(
                "\(errorSummary.domain) / \(errorSummary.code)"
            )
        }

        return parts.joined(
            separator: " · "
        )
    }

    var diagnosticsDescription: String? {
        resolvedFailureContext?
            .debugDescription
    }
}

@MainActor
final class PhotoMemoShareExtensionIntakeService {

    private let intakeStore:
        ExternalPhotoIntakeStore

    private let snapshotService:
        SharedBatchConfigurationSnapshotService

    init(
        intakeStore: ExternalPhotoIntakeStore,
        snapshotService:
            SharedBatchConfigurationSnapshotService
    ) {
        self.intakeStore = intakeStore
        self.snapshotService =
            snapshotService
    }

    convenience init() {
        self.init(
            intakeStore: .shared,
            snapshotService:
                SharedBatchConfigurationSnapshotService()
        )
    }

    func persistSharedItems(
        _ items: [NSExtensionItem]
    ) async throws -> PhotoMemoShareExtensionImportResult {

        let itemProviders =
            allItemProviders(
                in: items
            )
        let providers =
            supportedImageProviders(
                in: items
            )

        PhotoMemoShareIntakeLog.notice(
            "Extension received \(itemProviders.count) item providers."
        )
        PhotoMemoShareIntakeLog.notice(
            "Supported providers count: \(providers.count)."
        )

        guard !providers.isEmpty else {
            throw PhotoMemoShareExtensionError
                .noSupportedImages
        }

        let requestID = UUID()
        var managedItems:
            [ExternalPhotoIntakeItem] = []
        var seenSourceKeys = Set<String>()
        var skippedCount = 0
        var failedCount = 0
        var lastFailureContext:
            PhotoMemoShareIntakeFailureContext?

        for (
            index,
            provider
        ) in providers.enumerated() {

            let outcome =
                await loadManagedURL(
                    from: provider,
                    requestID: requestID,
                    index: index,
                    itemProviderCount:
                        itemProviders.count,
                    supportedProviderCount:
                        providers.count,
                    seenSourceKeys:
                        &seenSourceKeys
                )

            switch outcome {

            case .imported(let importRecord):
                managedItems.append(
                    importRecord.item
                )

            case .skippedDuplicate:
                skippedCount += 1

            case .failed(let failureContext):
                failedCount += 1
                lastFailureContext =
                    failureContext
                logFailureContext(
                    failureContext,
                    prefix:
                        "Share intake provider failed"
                )
            }
        }

        let importSummary =
            ExternalPhotoImportSummary(
                importedCount:
                    managedItems.count,
                skippedCount:
                    skippedCount,
                failedCount:
                    failedCount
            )

        guard !managedItems.isEmpty else {
            let result =
                PhotoMemoShareExtensionImportResult(
                    itemProviderCount:
                        itemProviders.count,
                    supportedProviderCount:
                        providers.count,
                    requestedCount:
                        providers.count,
                    summary:
                        importSummary,
                    failureStage:
                        lastFailureContext?
                        .stage,
                    failureContext:
                        lastFailureContext
                )

            logImportResult(
                result,
                label:
                    "persistSharedItems.allImportsFailed"
            )

            throw PhotoMemoShareExtensionError
                .allImportsFailed(
                    result: result,
                    failureContext:
                        lastFailureContext
                )
        }

        let persistSeed =
            PhotoMemoShareIntakeOperationSeed(
                itemProviderCount:
                    itemProviders.count,
                supportedProviderCount:
                    providers.count,
                requestedTypeIdentifier:
                    UTType.image.identifier
            )

        let persistResult =
            intakeStore
            .persistManagedRequestDetailed(
                id: requestID,
                urls: managedItems.map(
                    \.managedURL
                ),
                items: managedItems,
                source: .shareExtension,
                importSummary:
                    importSummary,
                configurationSnapshot:
                    snapshotService
                    .loadSnapshot(),
                diagnosticsSeed:
                    persistSeed
            )

        guard let request =
            persistResult.request
        else {
            managedItems.map(\.managedURL).forEach {
                intakeStore
                    .cleanupManagedSourceIfNeeded(
                        at: $0
                    )
            }

            let result =
                PhotoMemoShareExtensionImportResult(
                    itemProviderCount:
                        itemProviders.count,
                    supportedProviderCount:
                        providers.count,
                    requestedCount:
                        providers.count,
                    summary:
                        importSummary,
                    failureStage:
                        persistResult
                        .failureContext?
                        .stage,
                    failureContext:
                        persistResult
                        .failureContext
                )

            if let failureContext =
                persistResult
                .failureContext {
                logFailureContext(
                    failureContext,
                    prefix:
                        "Share intake persist failed"
                )
            }

            logImportResult(
                result,
                label:
                    "persistSharedItems.persistFailed"
            )

            throw PhotoMemoShareExtensionError
                .persistFailed(
                    result: result,
                    failureContext:
                        persistResult
                        .failureContext
                )
        }

        PhotoMemoShareIntakeLog.notice(
            "persistSharedItems result: persistedRequestID=\(request.id.uuidString)"
        )

        let result =
            PhotoMemoShareExtensionImportResult(
                itemProviderCount:
                    itemProviders.count,
                supportedProviderCount:
                    providers.count,
                requestedCount:
                    providers.count,
                summary:
                    importSummary,
                failureStage:
                    lastFailureContext?
                    .stage,
                failureContext:
                    lastFailureContext
            )

        logImportResult(
            result,
            label:
                "persistSharedItems.success"
        )

        return result
    }

    func supportedPhotoCount(
        in items: [NSExtensionItem]
    ) -> Int {

        supportedImageProviders(
            in: items
        ).count
    }
}

private extension PhotoMemoShareExtensionIntakeService {

    enum ManagedImportOutcome {

        case imported(
            ManagedImportRecord
        )

        case skippedDuplicate

        case failed(
            PhotoMemoShareIntakeFailureContext
        )
    }

    struct ManagedImportRecord {

        let item:
            ExternalPhotoIntakeItem

        let dedupeKey: String

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

    func allItemProviders(
        in items: [NSExtensionItem]
    ) -> [NSItemProvider] {

        items.flatMap { item in
            item.attachments ?? []
        }
    }

    func supportedImageProviders(
        in items: [NSExtensionItem]
    ) -> [NSItemProvider] {

        allItemProviders(
            in: items
        )
        .filter {
            $0.hasItemConformingToTypeIdentifier(
                UTType.image.identifier
            )
        }
    }

    func loadManagedURL(
        from provider: NSItemProvider,
        requestID: UUID,
        index: Int,
        itemProviderCount: Int,
        supportedProviderCount: Int,
        seenSourceKeys: inout Set<String>
    ) async -> ManagedImportOutcome {

        let preferredTypeIdentifier =
            preferredImageTypeIdentifier(
                from:
                    provider
                    .registeredTypeIdentifiers
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

        PhotoMemoShareIntakeLog.notice(
            "Provider[\(index)] selectedUTType=\(UTType.image.identifier) preferredUTType=\(preferredTypeIdentifier ?? "unknown")"
        )

        let fileLoadResult =
            await loadFileRepresentationResult(
                from: provider,
                requestID: requestID,
                index: index,
                diagnosticsSeed:
                    diagnosticsSeed
            )

        if let importRecord =
            fileLoadResult.importRecord {
            let sourceKey =
                importRecord.dedupeKey

            guard
                seenSourceKeys.insert(sourceKey)
                    .inserted
            else {
                intakeStore
                    .cleanupManagedSourceIfNeeded(
                        at: importRecord.managedURL
                    )
                return .skippedDuplicate
            }

            return .imported(
                importRecord
            )
        }

        let fallbackResult =
            await loadFallbackItem(
                from: provider,
                requestID: requestID,
                index: index,
                diagnosticsSeed:
                    diagnosticsSeed
            )

        if case .failed(let failureContext) =
            fallbackResult {
            return .failed(
                failureContext
            )
        }

        if case .imported(let imported) =
            fallbackResult {
            let sourceKey =
                imported.dedupeKey

            guard
                seenSourceKeys.insert(sourceKey)
                    .inserted
            else {
                intakeStore
                    .cleanupManagedSourceIfNeeded(
                        at: imported
                        .managedURL
                    )
                return .skippedDuplicate
            }

            return .imported(
                imported
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

    func loadFileRepresentationResult(
        from provider: NSItemProvider,
        requestID: UUID,
        index: Int,
        diagnosticsSeed:
            PhotoMemoShareIntakeOperationSeed
    ) async -> FileRepresentationLoadResult {

        PhotoMemoShareIntakeLog.notice(
            "Provider[\(diagnosticsSeed.providerIndex ?? -1)] loadFileRepresentation start for \(UTType.image.identifier)"
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
                    UTType.image.identifier
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

                    PhotoMemoShareIntakeLog.error(
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

                    PhotoMemoShareIntakeLog.error(
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

                PhotoMemoShareIntakeLog.notice(
                    "Provider[\(diagnosticsSeed.providerIndex ?? -1)] loadFileRepresentation returnedURL=\(url.standardizedFileURL.path)"
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
                        diagnosticsSeed:
                            diagnosticsSeed
                    )

                PhotoMemoShareIntakeLog.notice(
                    "Provider[\(diagnosticsSeed.providerIndex ?? -1)] temporaryCopyResult=\(copyResult.temporaryCopyResult ?? "none") sharedContainerDestination=\(copyResult.sharedContainerDestination?.path ?? "nil")"
                )

                guard let managedURL =
                    copyResult.managedURL
                else {
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
            preferredFileExtension(
                from:
                    provider
                    .registeredTypeIdentifiers
            )

        PhotoMemoShareIntakeLog.notice(
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

                    PhotoMemoShareIntakeLog.error(
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

                    PhotoMemoShareIntakeLog.notice(
                        "Provider[\(index)] loadItem returnedURL=\(normalizedURL.path)"
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

                    PhotoMemoShareIntakeLog.notice(
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
                    PhotoMemoShareIntakeLog.notice(
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

                    PhotoMemoShareIntakeLog.notice(
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

                PhotoMemoShareIntakeLog.error(
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

    func preferredFileExtension(
        from registeredTypeIdentifiers:
            [String]
    ) -> String? {

        let supportedType =
            registeredTypeIdentifiers
            .compactMap(UTType.init)
            .first { type in
                type.conforms(to: .image)
            }

        return supportedType?
            .preferredFilenameExtension
    }

    func preferredImageTypeIdentifier(
        from registeredTypeIdentifiers:
            [String]
    ) -> String? {

        registeredTypeIdentifiers
            .compactMap(UTType.init)
            .first { type in
                type.conforms(to: .image)
            }?
            .identifier
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

    func logFailureContext(
        _ failureContext:
            PhotoMemoShareIntakeFailureContext,
        prefix: String
    ) {

        PhotoMemoShareIntakeLog.error(
            "\(prefix)\n\(failureContext.debugDescription)"
        )
    }

    func logImportResult(
        _ result:
            PhotoMemoShareExtensionImportResult,
        label: String
    ) {

        var lines = [
            "\(label)",
            "itemProviderCount: \(result.itemProviderCount)",
            "supportedProviderCount: \(result.supportedProviderCount)",
            "requestedCount: \(result.requestedCount)",
            "importedCount: \(result.importedCount)",
            "skippedCount: \(result.skippedCount)",
            "failedCount: \(result.failedCount)",
            "failureStage: \(result.failureStage?.title ?? "none")"
        ]

        if let failureContext =
            result.failureContext {
            lines.append(
                failureContext.debugDescription
            )
        }

        PhotoMemoShareIntakeLog.notice(
            lines.joined(
                separator: "\n"
            )
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
