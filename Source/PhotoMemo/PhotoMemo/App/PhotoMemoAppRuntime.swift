import Foundation
import Combine

@MainActor
final class PhotoMemoAppRuntime:
    ObservableObject {

    let batchQueueStore: BatchQueueStore

    let backgroundStatusService:
        PhotoMemoBackgroundStatusService

#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
    let backgroundExecutionService:
        PhotoMemoiOSBackgroundExecutionService

#if canImport(ActivityKit)
    let liveActivityBridgeService:
        PhotoMemoiOSLiveActivityBridgeService

    let liveActivityDriverService:
        PhotoMemoiOSLiveActivityDriverService
#endif
#endif

    let externalIntakeCenter:
        ExternalPhotoIntakeCenter

    private let externalIntakeStore:
        ExternalPhotoIntakeStore

    init(
        batchQueueStore: BatchQueueStore? = nil,
        externalIntakeCenter:
            ExternalPhotoIntakeCenter? = nil
    ) {
        self.batchQueueStore =
            batchQueueStore
            ?? BatchQueueStore()
        self.backgroundStatusService =
            PhotoMemoBackgroundStatusService(
                batchQueueStore:
                    self.batchQueueStore
            )
#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
        self.backgroundExecutionService =
            PhotoMemoiOSBackgroundExecutionService(
                batchQueueStore:
                    self.batchQueueStore
            )
#if canImport(ActivityKit)
        self.liveActivityBridgeService =
            PhotoMemoiOSLiveActivityBridgeService(
                backgroundStatusService:
                    self
                    .backgroundStatusService
            )
        self.liveActivityDriverService =
            PhotoMemoiOSLiveActivityDriverService(
                bridgeService:
                    self
                    .liveActivityBridgeService
            )
#endif
#endif
        self.externalIntakeCenter =
            externalIntakeCenter
            ?? .shared
        self.externalIntakeStore =
            .shared
    }

    func handleExternalURLs(
        _ urls: [URL],
        source: BatchJobLaunchSource
    ) {

        externalIntakeCenter.submit(
            urls: urls,
            importSummary: nil,
            source: source
        )
    }

    func flushExternalRequests() {

        let requests =
            externalIntakeCenter
            .drainPendingRequests()

        PhotoMemoShareDiagnostics.record(
            stage: "app.drain",
            message: "drainedRequests=\(requests.count)"
        )

        guard !requests.isEmpty else {
            return
        }

        var consumedPayloadKeys = Set<String>()

        for request in requests {
            let validPayloads =
                request.intakePayloads.filter {
                    isValidRequestSourceURL(
                        $0.sourceURL
                    )
                }
            let uniquePayloads =
                uniquePayloadsForCurrentDrain(
                    validPayloads,
                    consumedPayloadKeys:
                        &consumedPayloadKeys
                )
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

            PhotoMemoShareDiagnostics.record(
                stage: "app.request.validated",
                message:
                    "payloads=\(request.intakePayloads.count), valid=\(validPayloads.count), unique=\(uniquePayloads.count)",
                requestID:
                    request.id
            )

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
                PhotoMemoShareDiagnostics.record(
                    stage: "app.request.dropped",
                    message:
                        validPayloads.isEmpty
                        ? "No valid source files remained."
                        : "Duplicate source files were already queued.",
                    requestID:
                        request.id
                )
                continue
            }

            let job =
                batchQueueStore.enqueue(
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

            PhotoMemoShareDiagnostics.record(
                stage:
                    job == nil
                    ? "app.enqueue.failed"
                    : "app.enqueue.created",
                message:
                    job == nil
                    ? "BatchQueueStore returned nil."
                    : "tasks=\(uniquePayloads.count)",
                requestID:
                    request.id,
                jobID:
                    job?.id
            )
        }

        externalIntakeCenter.updateDefaultConfiguration(
            batchQueueStore
                .defaultConfigurationSnapshot
        )
    }

    func refreshExternalIntakeState() {

        externalIntakeCenter.updateDefaultConfiguration(
            batchQueueStore
                .defaultConfigurationSnapshot
        )
        flushExternalRequests()

        externalIntakeStore
            .cleanupOrphanedManagedContent(
                keepingReferencedURLs:
                    batchQueueStore
                    .referencedManagedSourceURLs
            )
    }
}

private extension PhotoMemoAppRuntime {

    func resolvedRequestTitle(
        receivedAt: Date,
        taskCount: Int
    ) -> String {

        PhotoMemoQueueDisplayFormatter.title(
            startedAt:
                receivedAt,
            photoCount:
                taskCount
        )
    }

    func isValidRequestSourceURL(
        _ url: URL
    ) -> Bool {

        guard url.isFileURL else {
            return false
        }

        return FileManager.default
            .fileExists(
                atPath:
                    url.standardizedFileURL
                    .path
            )
    }

    func uniquePayloadsForCurrentDrain(
        _ payloads: [BatchTaskIntakePayload],
        consumedPayloadKeys: inout Set<String>
    ) -> [BatchTaskIntakePayload] {

        payloads.filter { payload in
            let key =
                payloadDedupeKey(
                    for: payload
                )

            guard !consumedPayloadKeys.contains(key) else {
                return false
            }

            consumedPayloadKeys.insert(key)
            return true
        }
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
