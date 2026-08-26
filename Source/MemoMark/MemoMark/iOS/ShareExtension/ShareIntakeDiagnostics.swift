#if os(iOS) && MEMOMARK_SHARE_EXTENSION
import Foundation
import UniformTypeIdentifiers

struct ShareIntakeDiagnostics {

    func recordReceived(
        itemProviderCount: Int,
        supportedProviderCount: Int,
        requestID: UUID
    ) {

        Self.notice(
            "Extension received \(itemProviderCount) item providers."
        )
        Self.notice(
            "Supported providers count: \(supportedProviderCount)."
        )
        MemoMarkShareDiagnostics.record(
            stage: .extensionInput,
            message:
                "itemProviders=\(itemProviderCount), supportedProviders=\(supportedProviderCount)",
            requestID: requestID
        )
    }

    func recordTooManySharedItems(
        supportedProviderCount: Int,
        maxSupportedPhotoCount: Int,
        requestID: UUID
    ) {

        MemoMarkShareDiagnostics.record(
            stage: .extensionError,
            message:
                "tooManySharedItems supported=\(supportedProviderCount), max=\(maxSupportedPhotoCount)",
            requestID: requestID
        )
    }

    func recordRequestCreated(
        itemProviderCount: Int,
        supportedProviderCount: Int,
        requestID: UUID
    ) {

        MemoMarkShareDiagnostics.record(
            stage: .extensionRequestCreated,
            message:
                "providers=\(supportedProviderCount), itemProviders=\(itemProviderCount)",
            requestID: requestID
        )
    }

    func recordProviderDiagnostics(
        _ providers: [NSItemProvider],
        requestID: UUID
    ) {

        for (index, provider) in providers.enumerated() {
            let identifiers =
                provider.registeredTypeIdentifiers
            let preferredImportType =
                MemoMarkShareProviderTypeSelection
                .preferredImportTypeIdentifier(
                    from: identifiers
                )
            let preferredImageType =
                MemoMarkShareProviderTypeSelection
                .preferredImageTypeIdentifier(
                    from: identifiers
                )
            let supportsLivePhoto =
                MemoMarkShareProviderTypeSelection
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

            MemoMarkShareDiagnostics.record(
                stage: .extensionProviderObserved,
                message:
                    "index=\(index), preferredImportType=\(preferredImportType ?? "nil"), preferredImageType=\(preferredImageType ?? "nil"), supportsLivePhoto=\(supportsLivePhoto), supportsMovie=\(supportsMovie), registeredTypes=\(joinedIdentifiers)",
                requestID: requestID
            )
        }
    }

    func recordImported(
        fileName: String,
        requestID: UUID
    ) {

        MemoMarkShareDiagnostics.record(
            stage: .extensionItemImported,
            message: "imported",
            requestID: requestID
        )
    }

    func recordSkippedDuplicate(
        requestID: UUID
    ) {

        MemoMarkShareDiagnostics.record(
            stage: .extensionItemSkipped,
            message: "duplicate",
            requestID: requestID
        )
    }

    func recordSkippedUnsupported(
        _ report:
            MemoMarkMediaIntakeRejectionReport,
        requestID: UUID
    ) {

        MemoMarkShareDiagnostics.record(
            stage: .extensionItemSkipped,
            message:
                "unsupported:\(report.reasonRawValue ?? "unknown")",
            requestID: requestID
        )
    }

    func recordFailed(
        _ failureContext:
            MemoMarkShareIntakeFailureContext,
        requestID: UUID
    ) {

        MemoMarkShareDiagnostics.record(
            stage: .extensionItemFailed,
            message:
                failureContext.stage.title,
            requestID: requestID
        )
    }

    func recordRequestPersisted(
        requestID: UUID,
        importedCount: Int
    ) {

        MemoMarkShareDiagnostics.record(
            stage: .extensionRequestPersisted,
            message:
                "requestID=\(requestID.uuidString), imported=\(importedCount)",
            requestID: requestID
        )
    }

    func recordStaticLivePhotoPayload(
        index: Int,
        requestedTypeIdentifier: String,
        item: ExternalPhotoIntakeItem,
        readinessDiagnosticMessage: String,
        requestID: UUID
    ) {

        MemoMarkShareDiagnostics.record(
            stage:
                .extensionLivePhotoRepresentationStaticPayload,
            message:
                "index=\(index), requestedType=\(requestedTypeIdentifier), contentType=\(item.contentTypeIdentifier ?? "nil"), \(readinessDiagnosticMessage), routeWillFallbackToStaticWithoutAssetIdentity=true",
            requestID: requestID
        )
    }

    func logFailureContext(
        _ failureContext:
            MemoMarkShareIntakeFailureContext,
        prefix: String
    ) {

        Self.error(
            "\(prefix)\n\(failureContext.debugDescription)"
        )
    }

    func logImportResult(
        _ result:
            MemoMarkShareExtensionImportResult,
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
            "livePhotoStaticFallbackCount: \(result.livePhotoStaticFallbackCount)",
            "failureStage: \(result.failureStage?.title ?? "none")"
        ]

        if let failureContext =
            result.failureContext {
            lines.append(
                failureContext.debugDescription
            )
        }

        Self.notice(
            lines.joined(
                separator: "\n"
            )
        )
    }

    nonisolated static func notice(
        _ message: String
    ) {

        MemoMarkShareIntakeLog.notice(
            message
        )
    }

    nonisolated static func error(
        _ message: String
    ) {

        MemoMarkShareIntakeLog.error(
            message
        )
    }

    nonisolated static
    func recordSourcePreparationIfNeeded(
        _ probe:
            MemoMarkImageFileReadiness.ProbeResult,
        requestID: UUID,
        index: Int
    ) {

        guard probe.shouldDisplayPreparationState else {
            return
        }

        MemoMarkShareDiagnostics.record(
            stage: .extensionSourcePrepare,
            message:
                "providerIndex=\(index), \(probe.diagnosticMessage)",
            requestID: requestID
        )
    }

    nonisolated static
    func recordSourceReadyIfNeeded(
        _ probe:
            MemoMarkImageFileReadiness.ProbeResult,
        requestID: UUID,
        index: Int
    ) {

        guard probe.shouldDisplayPreparationState else {
            return
        }

        MemoMarkShareDiagnostics.record(
            stage: .extensionSourceReady,
            message:
                "providerIndex=\(index)",
            requestID: requestID
        )
    }

    nonisolated static
    func recordSourceUnavailableIfNeeded(
        _ probe:
            MemoMarkImageFileReadiness.ProbeResult,
        copyResult:
            MemoMarkShareIntakeManagedCopyResult,
        requestID: UUID,
        index: Int
    ) {

        guard probe.shouldDisplayPreparationState else {
            return
        }

        MemoMarkShareDiagnostics.record(
            stage: .extensionSourceUnavailable,
            message:
                "providerIndex=\(index), result=\(copyResult.temporaryCopyResult ?? "unknown")",
            requestID: requestID
        )
    }
}
#endif
