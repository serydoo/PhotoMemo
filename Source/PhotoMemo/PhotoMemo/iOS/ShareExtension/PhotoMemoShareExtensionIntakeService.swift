#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import Foundation
import UniformTypeIdentifiers
import UIKit

struct PhotoMemoShareExtensionError:
    LocalizedError {

    enum Kind {

        case noSupportedImages

        case tooManySharedItems

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

        case .tooManySharedItems:
            return "这次分享的照片数量超过当前 Share Extension 可安全处理的上限。"

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

        case .tooManySharedItems:
            return "这次的照片有点多"

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

        case .tooManySharedItems:
            return "美好的记忆适合慢慢整理。每次最多分享 20 张，可以分几次完成，也能让处理过程更稳定。"

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

    private let providerLoader:
        ShareItemProviderLoader

    private let managedFileImporter:
        ShareManagedFileImporter

    private let diagnostics:
        ShareIntakeDiagnostics

    static let maxSupportedPhotoCount = 20

    init(
        intakeStore: ExternalPhotoIntakeStore,
        snapshotService:
            SharedBatchConfigurationSnapshotService
    ) {
        let diagnostics =
            ShareIntakeDiagnostics()
        let providerLoader =
            ShareItemProviderLoader()
        let livePhotoRecovery =
            ShareLivePhotoRecovery(
                diagnostics: diagnostics
            )

        self.intakeStore = intakeStore
        self.snapshotService =
            snapshotService
        self.providerLoader =
            providerLoader
        self.managedFileImporter =
            ShareManagedFileImporter(
                intakeStore: intakeStore,
                providerLoader: providerLoader,
                livePhotoRecovery:
                    livePhotoRecovery
            )
        self.diagnostics = diagnostics
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
            providerLoader
            .allItemProviders(
                in: items
            )
        let providers =
            providerLoader
            .supportedImageProviders(
                in: items
            )

        diagnostics.recordReceived(
            itemProviderCount:
                itemProviders.count,
            supportedProviderCount:
                providers.count
        )

        guard !providers.isEmpty else {
            throw PhotoMemoShareExtensionError
                .noSupportedImages
        }

        guard providers.count <= Self.maxSupportedPhotoCount else {
            let requestID = UUID()
            let failureContext =
                PhotoMemoShareIntakeOperationSeed(
                    itemProviderCount:
                        itemProviders.count,
                    supportedProviderCount:
                        providers.count,
                    requestedTypeIdentifier:
                        UTType.image.identifier
                )
                .failureContext(
                    stage: .completion,
                    operation:
                        "persistSharedItems.tooManySharedItems",
                    error:
                        PhotoMemoShareIntakeDiagnosticError
                        .make(
                            description:
                                "Share Extension received \(providers.count) supported image providers; maxSupportedPhotoCount is \(Self.maxSupportedPhotoCount).",
                            code: 1010
                        )
                )

            diagnostics.recordTooManySharedItems(
                supportedProviderCount:
                    providers.count,
                maxSupportedPhotoCount:
                    Self.maxSupportedPhotoCount,
                requestID: requestID
            )

            throw PhotoMemoShareExtensionError(
                kind: .tooManySharedItems,
                failureContext:
                    failureContext
            )
        }

        let requestID = UUID()
        diagnostics.recordRequestCreated(
            itemProviderCount:
                itemProviders.count,
            supportedProviderCount:
                providers.count,
            requestID: requestID
        )
        diagnostics.recordProviderDiagnostics(
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
        var livePhotoStaticFallbackCount = 0
        var lastFailureContext:
            PhotoMemoShareIntakeFailureContext?

        for (
            index,
            provider
        ) in providers.enumerated() {

            let outcome =
                await managedFileImporter
                .loadManagedURL(
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
                if importRecord.livePhotoStaticFallback {
                    livePhotoStaticFallbackCount += 1
                }
                diagnostics.recordImported(
                    fileName:
                        importRecord.item.originalFileName,
                    requestID: requestID
                )

            case .skippedDuplicate:
                skippedCount += 1
                diagnostics.recordSkippedDuplicate(
                    requestID: requestID
                )

            case .skippedUnsupported(let report):
                skippedCount += 1
                unsupportedRejectionReports.append(
                    report
                )
                diagnostics.recordSkippedUnsupported(
                    report,
                    requestID: requestID
                )

            case .failed(let failureContext):
                failedCount += 1
                lastFailureContext =
                    failureContext
                diagnostics.recordFailed(
                    failureContext,
                    requestID: requestID
                )
                diagnostics.logFailureContext(
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
                        unsupportedRejectionReports,
                    livePhotoStaticFallbackCount:
                        livePhotoStaticFallbackCount
                )

            diagnostics.logImportResult(
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
                        unsupportedRejectionReports,
                    livePhotoStaticFallbackCount:
                        livePhotoStaticFallbackCount
                )

            if let failureContext =
                persistResult
                .failureContext {
                diagnostics.logFailureContext(
                    failureContext,
                    prefix:
                        "Share intake persist failed"
                )
            }

            diagnostics.logImportResult(
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

        ShareIntakeDiagnostics.notice(
            "persistSharedItems result: persistedRequestID=\(request.id.uuidString)"
        )

        diagnostics.recordRequestPersisted(
            requestID: request.id,
            importedCount:
                managedItems.count
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
                    unsupportedRejectionReports,
                livePhotoStaticFallbackCount:
                    livePhotoStaticFallbackCount
            )

        diagnostics.logImportResult(
            result,
            label:
                "persistSharedItems.success"
        )

        return result
    }

    func supportedPhotoCount(
        in items: [NSExtensionItem]
    ) -> Int {

        providerLoader
            .supportedImageProviders(
                in: items
            )
            .count
    }
}
#endif
