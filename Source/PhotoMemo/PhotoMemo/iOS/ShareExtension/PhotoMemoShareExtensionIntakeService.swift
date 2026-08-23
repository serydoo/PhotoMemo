#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import Foundation
import UniformTypeIdentifiers
import UIKit

struct PhotoMemoShareExtensionError:
    Error {

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

    func localizedDescription(
        for language: MemoMarkLanguage
    ) -> String {

        switch kind {

        case .noSupportedImages:
            return language.localized(
                key: "share.error.no_supported.message",
                fallback: "This share did not include a photo that MemoMark can process."
            )

        case .tooManySharedItems:
            return language.localized(
                key: "share.error.too_many.message",
                fallback: "This share exceeds the number of photos that the Share Extension can safely receive."
            )

        case .allImportsFailed:
            return language.localized(
                key: "share.error.all_imports.message",
                fallback: "The photos in this share could not be handed off to MemoMark."
            )

        case .persistFailed:
            return language.localized(
                key: "share.error.persist.message",
                fallback: "MemoMark could not record this share yet."
            )
        }
    }

    func localizedFailureTitle(
        for language: MemoMarkLanguage
    ) -> String {

        switch kind {

        case .noSupportedImages:
            return language.localized(
                key: "share.error.no_supported.title",
                fallback: "No Processable Photos"
            )

        case .tooManySharedItems:
            return language.localized(
                key: "share.error.too_many.title",
                fallback: "This Batch Is Too Large"
            )

        case .allImportsFailed:
            return language.localized(
                key: "share.error.all_imports.title",
                fallback: "Photos Were Not Received"
            )

        case .persistFailed:
            return language.localized(
                key: "share.error.persist.title",
                fallback: "This Share Was Not Saved"
            )
        }
    }

    func localizedRecoverySuggestion(
        for language: MemoMarkLanguage
    ) -> String {

        if let code =
            resolvedFailureContext?
            .errorSummary?.code,
           code == 3010 || code == 3011 {
            return language.localized(
                key: "share.error.icloud.recovery",
                fallback: "The photo source did not respond in time. Return to Apple Photos, wait for the original to finish downloading from iCloud, and share again."
            )
        }

        switch kind {

        case .noSupportedImages:
            return language.localized(
                key: "share.error.no_supported.recovery",
                fallback: "Share the original photo from Apple Photos. If it came from another app, make sure it is the original rather than a preview."
            )

        case .tooManySharedItems:
            return language.localized(
                key: "share.error.too_many.recovery",
                fallback: "Share fewer photos at a time. Smaller batches help the process stay reliable."
            )

        case .allImportsFailed:
            return language.localized(
                key: "share.error.all_imports.recovery",
                fallback: "Tap Try Again. If it still fails, return to Apple Photos and share again, or open MemoMark to check the current configuration."
            )

        case .persistFailed:
            return language.localized(
                key: "share.error.persist.recovery",
                fallback: "Try again. If the problem continues, open MemoMark to check the shared container, current configuration, and Photos permission."
            )
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

            if let supportID =
                failureContext.supportID {
                parts.append(
                    "故障编号：\(supportID)"
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

    private let commercePersistence:
        MemoMarkCommercePersistence

    var maxSupportedPhotoCount: Int {
        let snapshot =
            commercePersistence
            .loadSharedSnapshot(
                compatibleWith:
                    .currentRuntime
            )
        return min(
            snapshot.batchLimit,
            snapshot.remainingRecords
                ?? snapshot.batchLimit
        )
    }

    init(
        intakeStore: ExternalPhotoIntakeStore,
        snapshotService:
            SharedBatchConfigurationSnapshotService,
        commercePersistence:
            MemoMarkCommercePersistence =
                MemoMarkCommercePersistence()
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
        self.commercePersistence =
            commercePersistence
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

        let requestID = UUID()

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
                providers.count,
            requestID: requestID
        )
        diagnostics.recordProviderDiagnostics(
            itemProviders,
            requestID: requestID
        )

        guard !providers.isEmpty else {
            throw PhotoMemoShareExtensionError
                .noSupportedImages
        }

        guard providers.count <= maxSupportedPhotoCount,
              maxSupportedPhotoCount > 0 else {
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
                                "Share Extension received \(providers.count) supported image providers; maxSupportedPhotoCount is \(maxSupportedPhotoCount).",
                            code: 1010
                        )
                )

            diagnostics.recordTooManySharedItems(
                supportedProviderCount:
                    providers.count,
                maxSupportedPhotoCount:
                    maxSupportedPhotoCount,
                requestID: requestID
            )

            throw PhotoMemoShareExtensionError(
                kind: .tooManySharedItems,
                failureContext:
                    failureContext
            )
        }

        let configurationSnapshot =
            snapshotService.loadSnapshot()
        diagnostics.recordRequestCreated(
            itemProviderCount:
                itemProviders.count,
            supportedProviderCount:
                providers.count,
            requestID: requestID
        )
        var managedItems:
            [ExternalPhotoIntakeItem] = []
        var seenSourceKeys = Set<String>()
        var skippedCount = 0
        var skippedRequiringAttentionCount = 0
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
                    mediaOutputModeRawValue:
                        configurationSnapshot
                        .mediaOutputModeRawValue,
                    livePhotoPolicyRawValue:
                        configurationSnapshot
                        .livePhotoPolicyRawValue,
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
                skippedRequiringAttentionCount += 1
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
                    failedCount,
                skippedRequiringAttentionCount:
                    skippedRequiringAttentionCount
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
                    configurationSnapshot,
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
