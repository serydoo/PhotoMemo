import Foundation
import UniformTypeIdentifiers

/// The same source validation, dedupe and Live Photo identity recovery is used
/// before either host or extension admission. It has no UI/store dependency.
@MainActor
struct ShareIntakePayloadResolver {
    let livePhotoAssetIdentityResolver: any LivePhotoAssetIdentityResolving
    let diagnosticsDefaults: UserDefaults


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
        requestID: UUID,
        permitsStaticFallback: Bool
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
            _ = MemoMarkShareDiagnostics.recordResult(
                stage:
                    .appLivePhotoIdentityRecovery,
                message:
                    "result=matched, contentType=\(context.payload.contentTypeIdentifier ?? "nil"), assetIdentifierRecovered=true",
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
            _ = MemoMarkShareDiagnostics.recordResult(
                stage:
                    .appLivePhotoIdentityRecovery,
                message:
                    "result=notFound, motionUnavailable=true, permitsStaticFallback=\(permitsStaticFallback)",
                requestID: requestID,
                defaults: diagnosticsDefaults
            )
            guard !permitsStaticFallback else {
                return context
            }
            return contextPreservingLivePhotoMediaTruth(
                context,
                hint: hint
            )

        case .ambiguous(let candidateCount):
            _ = MemoMarkShareDiagnostics.recordResult(
                stage:
                    .appLivePhotoIdentityRecovery,
                message:
                    "result=ambiguous, candidateCount=\(candidateCount), motionUnavailable=true, permitsStaticFallback=\(permitsStaticFallback)",
                requestID: requestID,
                defaults: diagnosticsDefaults
            )
            guard !permitsStaticFallback else {
                return context
            }
            return contextPreservingLivePhotoMediaTruth(
                context,
                hint: hint
            )

        case .unavailable(let reason):
            _ = MemoMarkShareDiagnostics.recordResult(
                stage:
                    .appLivePhotoIdentityRecovery,
                message:
                    "result=unavailable, reason=\(reason), motionUnavailable=true, permitsStaticFallback=\(permitsStaticFallback)",
                requestID: requestID,
                defaults: diagnosticsDefaults
            )
            guard !permitsStaticFallback else {
                return context
            }
            return contextPreservingLivePhotoMediaTruth(
                context,
                hint: hint
            )
        }
    }

    func contextPreservingLivePhotoMediaTruth(
        _ context: PayloadContext,
        hint: LivePhotoStaticFallbackRecoveryHint
    ) -> PayloadContext {

        var payload = context.payload
        payload.sourceIdentifier = nil
        payload.contentTypeIdentifier =
            UTType("com.apple.live-photo")?
            .identifier
            ?? hint.advertisedLivePhotoTypeIdentifier
        return PayloadContext(
            payload: payload,
            livePhotoRecoveryHint:
                context.livePhotoRecoveryHint
        )
    }

    func resolvedRequestTitle(
        receivedAt: Date,
        taskCount: Int
    ) -> String {

        MemoMarkQueueDisplayFormatter.title(
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

        return MemoMarkImageFileReadiness
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
                + additionalFailedCount,
            skippedRequiringAttentionCount:
                existingSummary.skippedRequiringAttentionCount
        )
    }
}
