#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

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

    init(
        externalIntakeCenter:
            ExternalPhotoIntakeCenter,
        externalIntakeStore:
            ExternalPhotoIntakeStore,
        configurationRepository:
            ConfigurationRepository,
        queueRepository:
            QueueRepository
    ) {
        self.externalIntakeCenter =
            externalIntakeCenter
        self.externalIntakeStore =
            externalIntakeStore
        self.configurationRepository =
            configurationRepository
        self.queueRepository =
            queueRepository
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

        let validPayloads =
            request.intakePayloads.filter {
                isValidRequestSourceURL(
                    $0.sourceURL
                )
            }
        let uniquePayloadsResult =
            uniquePayloadsForCurrentDrain(
                validPayloads,
                consumedPayloadKeys:
                    consumedPayloadKeys
            )
        let uniquePayloads =
            uniquePayloadsResult
            .payloads
        let duplicatePayloads =
            validPayloads.filter {
                !uniquePayloads.contains($0)
            }

        duplicatePayloads.forEach {
            externalIntakeStore
                .cleanupManagedSourceIfNeeded(
                    at: $0.sourceURL
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
                validPayloads.isEmpty
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
                        validPayloads.count,
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

        let job =
            queueRepository.enqueue(
                payloads: uniquePayloads,
                configuration:
                    request.configurationSnapshot,
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
                    validPayloads.count,
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
}

private extension ShareCoordinator {

    struct UniquePayloadResult {

        let payloads:
            [BatchTaskIntakePayload]

        let consumedPayloadKeys:
            Set<String>
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

        return PhotoMemoImageFileReadiness
            .isExistingReadableImageFile(
                at:
                    url.standardizedFileURL
            )
    }

    func uniquePayloadsForCurrentDrain(
        _ payloads: [BatchTaskIntakePayload],
        consumedPayloadKeys:
            Set<String>
    ) -> UniquePayloadResult {

        var resolvedConsumedPayloadKeys =
            consumedPayloadKeys

        let uniquePayloads =
            payloads.filter { payload in
                let key =
                    payloadDedupeKey(
                        for: payload
                    )

                guard !resolvedConsumedPayloadKeys.contains(key) else {
                    return false
                }

                resolvedConsumedPayloadKeys
                    .insert(key)
                return true
            }

        return UniquePayloadResult(
            payloads: uniquePayloads,
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
