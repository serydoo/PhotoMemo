#if !MEMOMARK_SHARE_EXTENSION
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

    private let payloadResolver: ShareIntakePayloadResolver

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
            UserDefaults = MemoMarkSharedContainer
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
        self.payloadResolver = ShareIntakePayloadResolver(
            livePhotoAssetIdentityResolver: livePhotoAssetIdentityResolver
                ?? PhotoKitLivePhotoAssetIdentityResolver(),
            diagnosticsDefaults: diagnosticsDefaults
        )
    }

    func submit(
        urls: [URL],
        importSummary:
            ExternalPhotoImportSummary? = nil,
        source: BatchJobLaunchSource
    ) -> MemoMarkResult<
        ShareSubmissionReceipt
    > {

        guard !urls.isEmpty else {
            return .failure(
                MemoMarkError(
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
    -> MemoMarkResult<
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
    ) async -> MemoMarkResult<
        ProcessedShareRequest
    > {

        let validPayloadContexts =
            payloadResolver.payloadContexts(
                for: request
            )
            .filter {
                payloadResolver.isValidRequestSourceURL(
                    $0.payload.sourceURL
                )
            }
        let recoveredPayloadContexts =
            validPayloadContexts.map {
                payloadResolver.recoveredPayloadContext(
                    $0,
                    requestID:
                        request.id,
                    permitsStaticFallback:
                        LivePhotoStaticFallbackPolicy
                        .allowsStaticFallback(
                            mediaOutputModeRawValue:
                                request
                                .configurationSnapshot
                                .mediaOutputModeRawValue,
                            livePhotoPolicyRawValue:
                                request
                                .configurationSnapshot
                                .livePhotoPolicyRawValue
                        )
                )
            }
        let uniquePayloadsResult =
            payloadResolver.uniquePayloadContextsForCurrentDrain(
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
            payloadResolver.resolvedIntakeSummary(
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
            _ = MemoMarkShareDiagnostics.recordResult(
                stage: .configurationContractViolation,
                message:
                    "request=\(request.id.uuidString) reason=\(String(describing: error))",
                requestID: request.id,
                defaults: diagnosticsDefaults
            )
            return .failure(
                MemoMarkError(
                    code: .configurationUnavailable,
                    message:
                        "The requested saved configuration revision is unavailable or invalid."
                )
            )
        }

        let job =
            await queueRepository.enqueue(
                payloads: uniquePayloads,
                configuration: resolvedJobConfiguration,
                launchSource:
                    request.launchSource,
                intakeSummary:
                    intakeSummary,
                intakeRequestID:
                    request.id,
                title:
                    payloadResolver.resolvedRequestTitle(
                        receivedAt:
                            request.receivedAt,
                        taskCount:
                            uniquePayloads.count
                    )
            )

        if job == nil {
            return .failure(
                MemoMarkError(
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
            do {
                let resolved = try configurationRepository
                    .resolveDurableProductionConfiguration(
                        reference
                    )
                _ = MemoMarkShareDiagnostics.recordResult(
                    stage: .configurationReferenceAccepted,
                    message:
                        "configurationID=\(reference.configurationID.uuidString) revision=\(reference.revision) source=\(request.launchSource.rawValue)",
                    requestID: request.id,
                    defaults: diagnosticsDefaults
                )
                return resolved
            } catch let error as ProductionConfigurationContractError {
                guard case let .revisionMismatch(
                    configurationID,
                    requested,
                    durable
                ) = error else {
                    throw error
                }

                // A share request owns the configuration truth captured at
                // handoff. If durable settings have advanced since then,
                // reuse that frozen snapshot only after validating its full
                // production contract and identity.
                if let canonical = transportConfiguration
                    .canonicalProductionSnapshot {
                    try ProductionConfigurationSnapshotContract
                        .validate(transportConfiguration)
                    guard
                        transportConfiguration.configurationID
                        == configurationID,
                        transportConfiguration.configurationRevision
                        == requested,
                        canonical.configurationID == configurationID,
                        canonical.configurationRevision == requested
                    else {
                        throw ProductionConfigurationContractError
                            .snapshotIdentityMismatch
                    }

                    _ = MemoMarkShareDiagnostics.recordResult(
                        stage: .configurationCompatibilityRecovery,
                        message:
                            "revisionMismatch configurationID=\(configurationID.uuidString) requested=\(requested) durable=\(durable) source=\(request.launchSource.rawValue) usingFrozenRequestSnapshot=true",
                        requestID: request.id,
                        defaults: diagnosticsDefaults
                    )
                    return transportConfiguration
                }

                // A request for the current or a future revision is not a
                // FM never existed in the historical transport contract. An
                // incomplete FM snapshot cannot borrow legacy recovery.
                if transportConfiguration.presentationRouteRawValue == "filmMark" {
                    throw ProductionConfigurationContractError.missingCanonicalSnapshot
                }

                // A request for the current or a future revision is not a
                // historical transport artifact. Keep the versioned contract
                // strict so an invalid reference cannot enter production via
                // the compatibility adapter.
                guard requested < durable else {
                    throw error
                }

                // Older Share Extensions can carry a versioned request that
                // predates the app-only canonical payload. Its transport is
                // the only frozen truth available after the durable revision
                // advances: substituting the user's current configuration
                // would silently change an already accepted task.
                _ = MemoMarkShareDiagnostics.recordResult(
                    stage: .configurationCompatibilityRecovery,
                    message:
                        "revisionMismatch configurationID=\(configurationID.uuidString) requested=\(requested) durable=\(durable) source=\(request.launchSource.rawValue) usingFrozenLegacyTransport=true",
                    requestID: request.id,
                    defaults: diagnosticsDefaults
                )
                return transportConfiguration
                    .asLegacyTransportCompatibility()
            }
        }

        if transportConfiguration.productionContractVersion != nil {
            throw ProductionConfigurationContractError
                .missingReference
        }

        _ = MemoMarkShareDiagnostics.recordResult(
            stage: .configurationCompatibilityRecovery,
            message:
                "historicalRequest=true source=\(request.launchSource.rawValue)",
            requestID: request.id,
            defaults: diagnosticsDefaults
        )

        // Requests created before production references existed have no
        // durable configuration identity to resolve. Keep their original
        // transport intact so legacy processing remains deterministic rather
        // than borrowing whichever configuration the user selected later.
        return transportConfiguration
    }

}
#endif
