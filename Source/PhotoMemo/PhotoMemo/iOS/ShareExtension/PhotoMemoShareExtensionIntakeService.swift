#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import Foundation
import CryptoKit
import Photos
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
            return "这次分享里的照片暂时没有成功交给时光记。"

        case .persistFailed:
            return "时光记暂时无法记录这次分享。"
        }
    }

    var failureTitle: String {

        switch kind {

        case .noSupportedImages:
            return "没有识别到可处理照片"

        case .allImportsFailed:
            return "照片没有成功交给时光记"

        case .persistFailed:
            return "这次分享没有保存下来"
        }
    }

    var recoverySuggestion: String {

        switch kind {

        case .noSupportedImages:
            return "请尽量从系统相册直接分享原始照片；如果来自其他 App，请确认分享的是原图而不是预览图。"

        case .allImportsFailed:
            return "请直接点击重试；如果仍失败，请返回系统相册重新分享，或打开时光记检查默认风格。"

        case .persistFailed:
            return "请先重试一次；如果重复出现，请打开时光记检查共享容器、默认风格和系统相册权限。"
        }
    }

    var diagnosticSummaryLine: String? {

        if let failureContext =
            resolvedFailureContext {

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

        guard let rejectionReport =
            importResult?
            .firstUnsupportedRejectionReport
        else {
            return nil
        }

        return [
            "拒绝原因：\(rejectionReport.title)",
            rejectionReport.reasonRawValue
        ]
        .compactMap { $0 }
        .joined(
            separator: " · "
        )
    }

    var diagnosticsDescription: String? {
        if let failureContext =
            resolvedFailureContext {
            return failureContext
                .debugDescription
        }

        return importResult?
            .firstUnsupportedRejectionReport?
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
        PhotoMemoShareDiagnostics.record(
            stage: .extensionRequestCreated,
            message:
                "providers=\(providers.count), itemProviders=\(itemProviders.count)",
            requestID:
                requestID
        )
        recordProviderDiagnostics(
            itemProviders,
            requestID: requestID
        )
        var managedItems:
            [ExternalPhotoIntakeItem] = []
        var seenSourceKeys = Set<String>()
        var skippedCount = 0
        var failedCount = 0
        var unsupportedRejectionReports:
            [PhotoMemoMediaIntakeRejectionReport] = []
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
                PhotoMemoShareDiagnostics.record(
                    stage: .extensionItemImported,
                    message:
                        importRecord.item.originalFileName,
                    requestID:
                        requestID
                )

            case .skippedDuplicate:
                skippedCount += 1
                PhotoMemoShareDiagnostics.record(
                    stage: .extensionItemSkipped,
                    message: "duplicate",
                    requestID:
                        requestID
                )

            case .skippedUnsupported(let report):
                skippedCount += 1
                unsupportedRejectionReports.append(
                    report
                )
                PhotoMemoShareDiagnostics.record(
                    stage: .extensionItemSkipped,
                    message:
                        "unsupported:\(report.reasonRawValue ?? "unknown")",
                    requestID:
                        requestID
                )

            case .failed(let failureContext):
                failedCount += 1
                lastFailureContext =
                    failureContext
                PhotoMemoShareDiagnostics.record(
                    stage: .extensionItemFailed,
                    message:
                        failureContext.stage.title,
                    requestID:
                        requestID
                )
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
                    requestID:
                        requestID,
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
                        lastFailureContext,
                    unsupportedRejectionReports:
                        unsupportedRejectionReports
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
                    requestID:
                        requestID,
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
                        .failureContext,
                    unsupportedRejectionReports:
                        unsupportedRejectionReports
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

        PhotoMemoShareDiagnostics.record(
            stage: .extensionRequestPersisted,
            message:
                "requestID=\(request.id.uuidString), imported=\(managedItems.count)",
            requestID:
                request.id
        )

        let result =
            PhotoMemoShareExtensionImportResult(
                requestID:
                    request.id,
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
                    lastFailureContext,
                unsupportedRejectionReports:
                    unsupportedRejectionReports
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

    func recordProviderDiagnostics(
        _ providers: [NSItemProvider],
        requestID: UUID
    ) {

        for (index, provider) in providers.enumerated() {
            let identifiers =
                provider.registeredTypeIdentifiers
            let preferredImageType =
                preferredImageTypeIdentifier(
                    from: identifiers
                )
            let supportsLivePhoto =
                PhotoMemoShareProviderTypeSelection
                .supportsLivePhoto(
                    identifiers
                )
            let supportsMovie =
                identifiers
                .contains {
                    UTType($0)?
                        .conforms(to: .movie)
                        == true
                }
            let joinedIdentifiers =
                identifiers
                .prefix(12)
                .joined(separator: ",")

            PhotoMemoShareDiagnostics.record(
                stage: .extensionProviderObserved,
                message:
                    "index=\(index), suggestedName=\(provider.suggestedName ?? "nil"), preferredImageType=\(preferredImageType ?? "nil"), supportsLivePhoto=\(supportsLivePhoto), supportsMovie=\(supportsMovie), registeredTypes=\(joinedIdentifiers)",
                requestID: requestID
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

        let registeredTypeIdentifiers =
            provider
            .registeredTypeIdentifiers
        let preferredTypeIdentifier =
            preferredImageTypeIdentifier(
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

        PhotoMemoShareIntakeLog.notice(
            "Provider[\(index)] selectedUTType=\(UTType.image.identifier) preferredUTType=\(preferredTypeIdentifier ?? "unknown")"
        )

        if let livePhotoTypeIdentifier =
            PhotoMemoShareProviderTypeSelection
            .preferredLivePhotoTypeIdentifier(
                from: registeredTypeIdentifiers
            ) {
            await probeLivePhotoRepresentation(
                from: provider,
                typeIdentifier:
                    livePhotoTypeIdentifier,
                requestID: requestID,
                index: index
            )
        }

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

            if let unsupportedOutcome =
                unsupportedManagedImportOutcomeIfNeeded(
                    importRecord,
                    diagnosticsSeed:
                        diagnosticsSeed
                ) {
                return unsupportedOutcome
            }

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

            if let unsupportedOutcome =
                unsupportedManagedImportOutcomeIfNeeded(
                    imported,
                    diagnosticsSeed:
                        diagnosticsSeed
                ) {
                return unsupportedOutcome
            }

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

                let sourceReadiness =
                    PhotoMemoImageFileReadiness
                    .probe(
                        at: url.standardizedFileURL
                    )
                Self.recordSourcePreparationIfNeeded(
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
                        diagnosticsSeed:
                            diagnosticsSeed
                    )

                PhotoMemoShareIntakeLog.notice(
                    "Provider[\(diagnosticsSeed.providerIndex ?? -1)] temporaryCopyResult=\(copyResult.temporaryCopyResult ?? "none") sharedContainerDestination=\(copyResult.sharedContainerDestination?.path ?? "nil")"
                )

                guard let managedURL =
                    copyResult.managedURL
                else {
                    Self.recordSourceUnavailableIfNeeded(
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

                Self.recordSourceReadyIfNeeded(
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

    func probeLivePhotoRepresentation(
        from provider: NSItemProvider,
        typeIdentifier: String,
        requestID: UUID,
        index: Int
    ) async {

        await probeLivePhotoFileRepresentation(
            from: provider,
            typeIdentifier: typeIdentifier,
            requestID: requestID,
            index: index
        )
        await probeLivePhotoItemRepresentation(
            from: provider,
            typeIdentifier: typeIdentifier,
            requestID: requestID,
            index: index
        )
        await probeLivePhotoDataRepresentation(
            from: provider,
            typeIdentifier: typeIdentifier,
            requestID: requestID,
            index: index
        )
        await probeLivePhotoObjectRepresentation(
            from: provider,
            typeIdentifier: typeIdentifier,
            requestID: requestID,
            index: index
        )
    }

    func probeLivePhotoFileRepresentation(
        from provider: NSItemProvider,
        typeIdentifier: String,
        requestID: UUID,
        index: Int
    ) async {

        await withCheckedContinuation {
            (continuation: CheckedContinuation<Void, Never>) in

            provider.loadFileRepresentation(
                forTypeIdentifier:
                    typeIdentifier
            ) { url, error in

                let message =
                    PhotoMemoShareLivePhotoRepresentationProbe
                    .message(
                        operation: "loadFileRepresentation",
                        providerIndex: index,
                        typeIdentifier:
                            typeIdentifier,
                        resultDescription: nil,
                        url: url,
                        error: error
                    )

                PhotoMemoShareDiagnostics.record(
                    stage:
                        .extensionLivePhotoRepresentationProbe,
                    message: message,
                    requestID: requestID
                )

                continuation.resume()
            }
        }
    }

    func probeLivePhotoItemRepresentation(
        from provider: NSItemProvider,
        typeIdentifier: String,
        requestID: UUID,
        index: Int
    ) async {

        await withCheckedContinuation {
            (continuation: CheckedContinuation<Void, Never>) in

            provider.loadItem(
                forTypeIdentifier:
                    typeIdentifier,
                options: nil
            ) { item, error in

                let resultDescription =
                    Self.livePhotoItemProbeResultDescription(
                        item
                    )
                let message =
                    PhotoMemoShareLivePhotoRepresentationProbe
                    .message(
                        operation: "loadItem",
                        providerIndex: index,
                        typeIdentifier:
                            typeIdentifier,
                        resultDescription:
                            resultDescription,
                        url: item as? URL,
                        error: error
                    )

                PhotoMemoShareDiagnostics.record(
                    stage:
                        .extensionLivePhotoRepresentationProbe,
                    message: message,
                    requestID: requestID
                )

                continuation.resume()
            }
        }
    }

    func probeLivePhotoDataRepresentation(
        from provider: NSItemProvider,
        typeIdentifier: String,
        requestID: UUID,
        index: Int
    ) async {

        await withCheckedContinuation {
            (continuation: CheckedContinuation<Void, Never>) in

            provider.loadDataRepresentation(
                forTypeIdentifier:
                    typeIdentifier
            ) { data, error in

                let resultDescription =
                    data.map {
                        "dataBytes=\($0.count)"
                    }
                let message =
                    PhotoMemoShareLivePhotoRepresentationProbe
                    .message(
                        operation: "loadDataRepresentation",
                        providerIndex: index,
                        typeIdentifier:
                            typeIdentifier,
                        resultDescription:
                            resultDescription,
                        url: nil,
                        error: error
                    )

                PhotoMemoShareDiagnostics.record(
                    stage:
                        .extensionLivePhotoRepresentationProbe,
                    message: message,
                    requestID: requestID
                )

                continuation.resume()
            }
        }
    }

    func probeLivePhotoObjectRepresentation(
        from provider: NSItemProvider,
        typeIdentifier: String,
        requestID: UUID,
        index: Int
    ) async {

        let canLoadObject =
            provider.canLoadObject(
                ofClass:
                    PHLivePhoto.self
            )

        await withCheckedContinuation {
            (continuation: CheckedContinuation<Void, Never>) in

            provider.loadObject(
                ofClass:
                    PHLivePhoto.self
            ) { object, error in

                let resultDescription =
                    Self.livePhotoObjectProbeResultDescription(
                        object,
                        canLoadObject:
                            canLoadObject
                    )
                let message =
                    PhotoMemoShareLivePhotoRepresentationProbe
                    .message(
                        operation: "loadObject(PHLivePhoto)",
                        providerIndex: index,
                        typeIdentifier:
                            typeIdentifier,
                        resultDescription:
                            resultDescription,
                        url: nil,
                        error: error
                    )

                PhotoMemoShareDiagnostics.record(
                    stage:
                        .extensionLivePhotoRepresentationProbe,
                    message: message,
                    requestID: requestID
                )

                continuation.resume()
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

                    let sourceReadiness =
                        PhotoMemoImageFileReadiness
                        .probe(
                            at: normalizedURL
                        )
                    Self.recordSourcePreparationIfNeeded(
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

                    PhotoMemoShareIntakeLog.notice(
                        "Provider[\(index)] fallback temporaryCopyResult=\(copyResult.temporaryCopyResult ?? "none") sharedContainerDestination=\(copyResult.sharedContainerDestination?.path ?? "nil")"
                    )

                    guard let managedURL =
                        copyResult.managedURL
                    else {
                        Self.recordSourceUnavailableIfNeeded(
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

                    Self.recordSourceReadyIfNeeded(
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
                                            sourceIdentifier:
                                                Self
                                                .dedupeKey(
                                                    for: data,
                                                    suggestedName:
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

    func unsupportedManagedImportOutcomeIfNeeded(
        _ importRecord: ManagedImportRecord,
        diagnosticsSeed:
            PhotoMemoShareIntakeOperationSeed
    ) -> ManagedImportOutcome? {

        let verdict =
            PhotoProcessingInputPolicy.standard
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

        PhotoMemoShareIntakeLog.notice(
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

    func preferredImageTypeIdentifier(
        from registeredTypeIdentifiers:
            [String]
    ) -> String? {

        PhotoMemoShareProviderTypeSelection
            .preferredImageTypeIdentifier(
                from: registeredTypeIdentifiers
            )
    }

    nonisolated static
    func livePhotoItemProbeResultDescription(
        _ item: NSSecureCoding?
    ) -> String {

        guard let item else {
            return "item=nil"
        }

        if let data = item as? Data {
            return "itemClass=Data, itemBytes=\(data.count)"
        }

        if let url = item as? URL {
            return "itemClass=URL, itemURLLastPathComponent=\(url.lastPathComponent)"
        }

        return "itemClass=\(String(describing: type(of: item)))"
    }

    nonisolated static
    func livePhotoObjectProbeResultDescription(
        _ object: (any NSItemProviderReading)?,
        canLoadObject: Bool
    ) -> String {

        guard let livePhoto =
            object as? PHLivePhoto else {
            return "canLoadObject=\(canLoadObject), object=nil"
        }

        return [
            "canLoadObject=\(canLoadObject)",
            "objectClass=PHLivePhoto",
            "size=\(Int(livePhoto.size.width))x\(Int(livePhoto.size.height))"
        ]
        .joined(separator: ", ")
    }

    nonisolated static
    func recordSourcePreparationIfNeeded(
        _ probe:
            PhotoMemoImageFileReadiness.ProbeResult,
        requestID: UUID,
        index: Int
    ) {

        guard probe.shouldDisplayPreparationState else {
            return
        }

        PhotoMemoShareDiagnostics.record(
            stage: .extensionSourcePrepare,
            message:
                "providerIndex=\(index), \(probe.diagnosticMessage)",
            requestID:
                requestID
        )
    }

    nonisolated static
    func recordSourceReadyIfNeeded(
        _ probe:
            PhotoMemoImageFileReadiness.ProbeResult,
        requestID: UUID,
        index: Int
    ) {

        guard probe.shouldDisplayPreparationState else {
            return
        }

        PhotoMemoShareDiagnostics.record(
            stage: .extensionSourceReady,
            message:
                "providerIndex=\(index)",
            requestID:
                requestID
        )
    }

    nonisolated static
    func recordSourceUnavailableIfNeeded(
        _ probe:
            PhotoMemoImageFileReadiness.ProbeResult,
        copyResult:
            PhotoMemoShareIntakeManagedCopyResult,
        requestID: UUID,
        index: Int
    ) {

        guard probe.shouldDisplayPreparationState else {
            return
        }

        PhotoMemoShareDiagnostics.record(
            stage: .extensionSourceUnavailable,
            message:
                "providerIndex=\(index), result=\(copyResult.temporaryCopyResult ?? "unknown")",
            requestID:
                requestID
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
