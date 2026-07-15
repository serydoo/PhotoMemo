#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import Foundation
import UniformTypeIdentifiers

struct ShareIntakeDiagnostics {

    func recordReceived(
        itemProviderCount: Int,
        supportedProviderCount: Int
    ) {

        Self.notice(
            "Extension received \(itemProviderCount) item providers."
        )
        Self.notice(
            "Supported providers count: \(supportedProviderCount)."
        )
    }

    func recordTooManySharedItems(
        supportedProviderCount: Int,
        maxSupportedPhotoCount: Int,
        requestID: UUID
    ) {

        PhotoMemoShareDiagnostics.record(
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

        PhotoMemoShareDiagnostics.record(
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
                PhotoMemoShareProviderTypeSelection
                .preferredImportTypeIdentifier(
                    from: identifiers
                )
            let preferredImageType =
                PhotoMemoShareProviderTypeSelection
                .preferredImageTypeIdentifier(
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
                    "index=\(index), suggestedName=\(provider.suggestedName ?? "nil"), preferredImportType=\(preferredImportType ?? "nil"), preferredImageType=\(preferredImageType ?? "nil"), supportsLivePhoto=\(supportsLivePhoto), supportsMovie=\(supportsMovie), registeredTypes=\(joinedIdentifiers)",
                requestID: requestID
            )
        }
    }

    func recordImported(
        fileName: String,
        requestID: UUID
    ) {

        PhotoMemoShareDiagnostics.record(
            stage: .extensionItemImported,
            message: fileName,
            requestID: requestID
        )
    }

    func recordSkippedDuplicate(
        requestID: UUID
    ) {

        PhotoMemoShareDiagnostics.record(
            stage: .extensionItemSkipped,
            message: "duplicate",
            requestID: requestID
        )
    }

    func recordSkippedUnsupported(
        _ report:
            PhotoMemoMediaIntakeRejectionReport,
        requestID: UUID
    ) {

        PhotoMemoShareDiagnostics.record(
            stage: .extensionItemSkipped,
            message:
                "unsupported:\(report.reasonRawValue ?? "unknown")",
            requestID: requestID
        )
    }

    func recordFailed(
        _ failureContext:
            PhotoMemoShareIntakeFailureContext,
        requestID: UUID
    ) {

        PhotoMemoShareDiagnostics.record(
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

        PhotoMemoShareDiagnostics.record(
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

        PhotoMemoShareDiagnostics.record(
            stage:
                .extensionLivePhotoRepresentationStaticPayload,
            message:
                "index=\(index), requestedType=\(requestedTypeIdentifier), fileName=\(item.originalFileName), contentType=\(item.contentTypeIdentifier ?? "nil"), \(readinessDiagnosticMessage), routeWillFallbackToStaticWithoutAssetIdentity=true",
            requestID: requestID
        )
    }

    func logFailureContext(
        _ failureContext:
            PhotoMemoShareIntakeFailureContext,
        prefix: String
    ) {

        Self.error(
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

        PhotoMemoShareIntakeLog.notice(
            message
        )
    }

    nonisolated static func error(
        _ message: String
    ) {

        PhotoMemoShareIntakeLog.error(
            message
        )
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
            requestID: requestID
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
            requestID: requestID
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
            requestID: requestID
        )
    }
}
#endif
