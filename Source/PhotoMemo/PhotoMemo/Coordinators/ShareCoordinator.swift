#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import UniformTypeIdentifiers

struct ShareSubmissionReceipt:
    Hashable {

    let requestedURLCount: Int

    let source:
        BatchJobLaunchSource
}

@MainActor
final class ShareCoordinator {

    private let externalIntakeCenter:
        ExternalPhotoIntakeCenter

    private let externalIntakeStore:
        ExternalPhotoIntakeStore

    private let configurationRepository:
        ConfigurationRepository

    private let queueRepository:
        QueueRepository

    private let livePhotoAssetIdentityResolver:
        any LivePhotoAssetIdentityResolving

    private let diagnosticsDefaults:
        UserDefaults

    init(
        externalIntakeCenter:
            ExternalPhotoIntakeCenter,
        externalIntakeStore:
            ExternalPhotoIntakeStore,
        configurationRepository:
            ConfigurationRepository,
        queueRepository:
            QueueRepository,
        diagnosticsDefaults:
            UserDefaults = PhotoMemoSharedContainer
            .sharedUserDefaults,
        livePhotoAssetIdentityResolver:
            (any LivePhotoAssetIdentityResolving)? = nil
    ) {
        self.externalIntakeCenter =
            externalIntakeCenter
        self.externalIntakeStore =
            externalIntakeStore
        self.configurationRepository =
            configurationRepository
        self.queueRepository =
            queueRepository
        self.diagnosticsDefaults =
            diagnosticsDefaults
        self.livePhotoAssetIdentityResolver =
            livePhotoAssetIdentityResolver
            ?? PhotoKitLivePhotoAssetIdentityResolver()
    }

    func submit(
        urls: [URL],
        importSummary:
            ExternalPhotoImportSummary? = nil,
        source: BatchJobLaunchSource
    ) -> PhotoMemoResult<
        ShareSubmissionReceipt
    > {

        guard !urls.isEmpty else {
            return .failure(
                PhotoMemoError(
                    code: .invalidInput,
                    message:
                        "Share submission requires at least one URL."
                )
            )
        }

        externalIntakeCenter
            .updateDefaultConfiguration(
                configurationRepository
                .loadDefaultBatchConfigurationSnapshot()
            )
        externalIntakeCenter
            .submit(
                urls: urls,
                importSummary:
                    importSummary,
                source: source
            )

        return .success(
            ShareSubmissionReceipt(
                requestedURLCount:
                    urls.count,
                source: source
            )
        )
    }

    func drainPendingRequests()
    -> PhotoMemoResult<
        [ExternalPhotoIntakeRequest]
    > {

        .success(
            externalIntakeCenter
            .drainPendingRequests()
        )
    }

    func process(
        request: ExternalPhotoIntakeRequest,
        consumedPayloadKeys:
            Set<String>
    ) -> PhotoMemoResult<
        ProcessedShareRequest
    > {

        let validPayloadContexts =
            payloadContexts(
                for: request
            )
            .filter {
                isValidRequestSourceURL(
                    $0.payload.sourceURL
                )
            }
        let recoveredPayloadContexts =
            validPayloadContexts.map {
                recoveredPayloadContext(
                    $0,
                    requestID:
                        request.id
                )
            }
        let uniquePayloadsResult =
            uniquePayloadContextsForCurrentDrain(
                recoveredPayloadContexts,
                consumedPayloadKeys:
                    consumedPayloadKeys
            )
        let uniquePayloadContexts =
            uniquePayloadsResult
            .contexts
        let duplicatePayloadContexts =
            recoveredPayloadContexts.filter {
                context in
                !uniquePayloadContexts.contains {
                    $0.payload == context.payload
                }
            }
        let uniquePayloads =
            uniquePayloadContexts.map(
                \.payload
            )

        duplicatePayloadContexts.forEach {
            externalIntakeStore
                .cleanupManagedSourceIfNeeded(
                    at: $0.payload.sourceURL
                )
        }

        let intakeSummary =
            resolvedIntakeSummary(
                for: request,
                validURLCount:
                    uniquePayloads.count
            )

        guard !uniquePayloads.isEmpty else {
            request.urls.forEach {
                externalIntakeStore
                    .cleanupManagedSourceIfNeeded(
                        at: $0
                    )
            }

            let droppedReason =
                validPayloadContexts.isEmpty
                ? "No valid source files remained."
                : "Duplicate source files were already queued."

            return .success(
                ProcessedShareRequest(
                    requestID:
                        request.id,
                    requestedPayloadCount:
                        request.intakePayloads
                        .count,
                    validPayloadCount:
                        validPayloadContexts.count,
                    uniquePayloadCount: 0,
                    consumedPayloadKeys:
                        uniquePayloadsResult
                        .consumedPayloadKeys,
                    intakeSummary:
                        intakeSummary,
                    job: nil,
                    droppedReason:
                        droppedReason
                )
            )
        }

        let resolvedJobConfiguration: BatchConfigurationSnapshot
        do {
            resolvedJobConfiguration = try resolvedConfiguration(
                for: request
            )
        } catch {
            _ = PhotoMemoShareDiagnostics.recordResult(
                stage: .configurationContractViolation,
                message:
                    "request=\(request.id.uuidString) reason=\(String(describing: error))",
                requestID: request.id,
                defaults: diagnosticsDefaults
            )
            return .failure(
                PhotoMemoError(
                    code: .configurationUnavailable,
                    message:
                        "The requested saved configuration revision is unavailable or invalid."
                )
            )
        }

        let job =
            queueRepository.enqueue(
                payloads: uniquePayloads,
                configuration: resolvedJobConfiguration,
                launchSource:
                    request.launchSource,
                intakeSummary:
                    intakeSummary,
                title:
                    resolvedRequestTitle(
                        receivedAt:
                            request.receivedAt,
                        taskCount:
                            uniquePayloads.count
                    )
            )

        if job == nil {
            return .failure(
                PhotoMemoError(
                    code: .queueOperationFailed,
                    message:
                        "Unable to enqueue the drained share request."
                )
            )
        }

        return .success(
            ProcessedShareRequest(
                requestID:
                    request.id,
                requestedPayloadCount:
                    request.intakePayloads
                    .count,
                validPayloadCount:
                    validPayloadContexts.count,
                uniquePayloadCount:
                    uniquePayloads.count,
                consumedPayloadKeys:
                    uniquePayloadsResult
                    .consumedPayloadKeys,
                intakeSummary:
                    intakeSummary,
                job: job,
                droppedReason: nil
            )
        )
    }

    private func resolvedConfiguration(
        for request: ExternalPhotoIntakeRequest
    ) throws -> BatchConfigurationSnapshot {
        let transportConfiguration =
            request.configurationSnapshot

        if let reference = transportConfiguration
            .productionConfigurationReference {
            let resolved = try configurationRepository
                .resolveDurableProductionConfiguration(
                    reference
                )
            _ = PhotoMemoShareDiagnostics.recordResult(
                stage: .configurationReferenceAccepted,
                message:
                    "configurationID=\(reference.configurationID.uuidString) revision=\(reference.revision) source=\(request.launchSource.rawValue)",
                requestID: request.id,
                defaults: diagnosticsDefaults
            )
            return resolved
        }

        if transportConfiguration.productionContractVersion != nil {
            throw ProductionConfigurationContractError
                .missingReference
        }

        _ = PhotoMemoShareDiagnostics.recordResult(
            stage: .configurationCompatibilityRecovery,
            message:
                "historicalRequest=true source=\(request.launchSource.rawValue)",
            requestID: request.id,
            defaults: diagnosticsDefaults
        )

        guard
            transportConfiguration
            .canonicalProductionSnapshot == nil
        else {
            return transportConfiguration
        }

        let currentConfiguration =
            configurationRepository
            .loadDefaultBatchConfigurationSnapshot()

        guard let canonicalSnapshot =
            currentConfiguration
            .canonicalProductionSnapshot
        else {
            return transportConfiguration
        }

        var restoredConfiguration =
            transportConfiguration
            .withCanonicalProductionSnapshot(
                canonicalSnapshot
            )

        if
            let configurationID =
                currentConfiguration
                .configurationID,
            let configurationRevision =
                currentConfiguration
                .configurationRevision
        {
            restoredConfiguration =
                restoredConfiguration
                .withConfigurationIdentity(
                    id: configurationID,
                    revision:
                        configurationRevision
                )
        }

        return restoredConfiguration
    }
}

private extension ShareCoordinator {

    struct PayloadContext {

        var payload:
            BatchTaskIntakePayload

        let livePhotoRecoveryHint:
            LivePhotoStaticFallbackRecoveryHint?
    }

    struct UniquePayloadResult {

        let contexts:
            [PayloadContext]

        let consumedPayloadKeys:
            Set<String>
    }

    func payloadContexts(
        for request: ExternalPhotoIntakeRequest
    ) -> [PayloadContext] {

        if let items = request.items,
           !items.isEmpty {
            return items.map {
                PayloadContext(
                    payload: $0.payload,
                    livePhotoRecoveryHint:
                        $0.livePhotoRecoveryHint
                )
            }
        }

        return request.urls.map {
            PayloadContext(
                payload:
                    BatchTaskIntakePayload(
                        sourceURL: $0,
                        fileName:
                            $0.lastPathComponent
                    ),
                livePhotoRecoveryHint: nil
            )
        }
    }

    func recoveredPayloadContext(
        _ context: PayloadContext,
        requestID: UUID
    ) -> PayloadContext {

        guard let hint =
            context.livePhotoRecoveryHint else {
            return context
        }

        let resolution =
            livePhotoAssetIdentityResolver
            .resolveAssetLocalIdentifier(
                for: hint
            )

        switch resolution {
        case .matched(let assetLocalIdentifier):
            _ = PhotoMemoShareDiagnostics.recordResult(
                stage:
                    .appLivePhotoIdentityRecovery,
                message:
                    "result=matched, fileName=\(context.payload.fileName ?? context.payload.sourceURL.lastPathComponent), contentType=\(context.payload.contentTypeIdentifier ?? "nil"), assetIdentifierRecovered=true",
                requestID: requestID,
                defaults: diagnosticsDefaults
            )

            var recoveredPayload =
                context.payload
            recoveredPayload.sourceIdentifier =
                assetLocalIdentifier
            recoveredPayload.contentTypeIdentifier =
                UTType("com.apple.live-photo")?
                .identifier
                ?? hint.advertisedLivePhotoTypeIdentifier
            return PayloadContext(
                payload: recoveredPayload,
                livePhotoRecoveryHint:
                    context.livePhotoRecoveryHint
            )

        case .notFound:
            _ = PhotoMemoShareDiagnostics.recordResult(
                stage:
                    .appLivePhotoIdentityRecovery,
                message:
                    "result=notFound, fileName=\(context.payload.fileName ?? context.payload.sourceURL.lastPathComponent), fallback=static",
                requestID: requestID,
                defaults: diagnosticsDefaults
            )
            return context

        case .ambiguous(let candidateCount):
            _ = PhotoMemoShareDiagnostics.recordResult(
                stage:
                    .appLivePhotoIdentityRecovery,
                message:
                    "result=ambiguous, candidateCount=\(candidateCount), fileName=\(context.payload.fileName ?? context.payload.sourceURL.lastPathComponent), fallback=static",
                requestID: requestID,
                defaults: diagnosticsDefaults
            )
            return context

        case .unavailable(let reason):
            _ = PhotoMemoShareDiagnostics.recordResult(
                stage:
                    .appLivePhotoIdentityRecovery,
                message:
                    "result=unavailable, reason=\(reason), fileName=\(context.payload.fileName ?? context.payload.sourceURL.lastPathComponent), fallback=static",
                requestID: requestID,
                defaults: diagnosticsDefaults
            )
            return context
        }
    }

    func resolvedRequestTitle(
        receivedAt: Date,
        taskCount: Int
    ) -> String {

        PhotoMemoQueueDisplayFormatter.title(
            startedAt: receivedAt,
            photoCount: taskCount
        )
    }

    func isValidRequestSourceURL(
        _ url: URL
    ) -> Bool {

        guard url.isFileURL else {
            return false
        }

        if LivePhotoSourceBundleLocator
            .canResolveBundle(
                at:
                    url.standardizedFileURL
            ) {
            return true
        }

        return PhotoMemoImageFileReadiness
            .isExistingReadableImageFile(
                at:
                    url.standardizedFileURL
            )
    }

    func uniquePayloadContextsForCurrentDrain(
        _ contexts: [PayloadContext],
        consumedPayloadKeys:
            Set<String>
    ) -> UniquePayloadResult {

        var resolvedConsumedPayloadKeys =
            consumedPayloadKeys

        let uniqueContexts =
            contexts.filter { context in
                let key =
                    payloadDedupeKey(
                        for: context.payload
                    )

                guard !resolvedConsumedPayloadKeys.contains(key) else {
                    return false
                }

                resolvedConsumedPayloadKeys
                    .insert(key)
                return true
            }

        return UniquePayloadResult(
            contexts: uniqueContexts,
            consumedPayloadKeys:
                resolvedConsumedPayloadKeys
        )
    }

    func payloadDedupeKey(
        for payload: BatchTaskIntakePayload
    ) -> String {

        let sourceIdentifier =
            payload.sourceIdentifier?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        if !sourceIdentifier.isEmpty {
            return "source:\(sourceIdentifier)"
        }

        let fileName =
            (
                payload.fileName?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .lowercased()
            )
            ?? payload
                .sourceURL
                .lastPathComponent
                .lowercased()

        let fileSize =
            (
                try? FileManager.default
                    .attributesOfItem(
                        atPath:
                            payload
                            .sourceURL
                            .standardizedFileURL
                            .path
                    )[.size] as? NSNumber
            )?
            .int64Value ?? -1

        return "file:\(fileName):\(fileSize)"
    }

    func resolvedIntakeSummary(
        for request:
            ExternalPhotoIntakeRequest,
        validURLCount: Int
    ) -> ExternalPhotoImportSummary? {

        let droppedCount =
            max(
                request.urls.count
                - validURLCount,
                0
            )

        guard
            let existingSummary =
                request.importSummary
        else {
            guard droppedCount > 0 else {
                return nil
            }

            return ExternalPhotoImportSummary(
                importedCount:
                    validURLCount,
                skippedCount: 0,
                failedCount:
                    droppedCount
            )
        }

        let adjustedImportedCount =
            min(
                existingSummary.importedCount,
                validURLCount
            )

        let additionalFailedCount =
            max(
                existingSummary.importedCount
                - adjustedImportedCount,
                0
            )

        return ExternalPhotoImportSummary(
            importedCount:
                adjustedImportedCount,
            skippedCount:
                existingSummary.skippedCount,
            failedCount:
                existingSummary.failedCount
                + additionalFailedCount
        )
    }
}
#endif
