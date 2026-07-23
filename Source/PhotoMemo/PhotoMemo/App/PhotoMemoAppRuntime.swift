import Foundation
import Combine

@MainActor
final class PhotoMemoAppRuntime:
    ObservableObject {

    let environment:
        AppEnvironment

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
        environment: AppEnvironment
    ) {
        self.environment =
            environment
        self.batchQueueStore =
            environment.batchQueueStore
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
            environment.externalIntakeCenter
        self.externalIntakeStore =
            environment.services
            .externalIntakeStore
    }

    convenience init(
        batchQueueStore: BatchQueueStore? = nil,
        externalIntakeCenter:
            ExternalPhotoIntakeCenter? = nil
    ) {
        self.init(
            environment:
                AppEnvironment.live(
                    batchQueueStore:
                        batchQueueStore,
                    externalIntakeCenter:
                        externalIntakeCenter
                )
        )
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
            stage: .appDrain,
            message: "drainedRequests=\(requests.count)"
        )

        if let failure = externalIntakeCenter.intakePersistenceError {
            PhotoMemoShareDiagnostics.record(
                stage: .appDrain,
                message:
                    "requestPersistenceReadFailed storageKey=\(failure.storageKey) bytes=\(failure.payloadByteCount) reason=\(failure.underlyingDescription)"
            )
        }

        guard !requests.isEmpty else {
            return
        }

        var consumedPayloadKeys = Set<String>()

        for request in requests {
            let processedRequest =
                ProcessShareIntent(
                    request: request,
                    consumedPayloadKeys:
                        consumedPayloadKeys,
                    coordinator:
                        environment
                        .coordinators
                        .share
                )
                .executeSynchronously()

            switch processedRequest {
            case .success(let receipt):
                consumedPayloadKeys =
                    receipt.consumedPayloadKeys

                PhotoMemoShareDiagnostics.record(
                    stage: .appRequestValidated,
                    message:
                        "payloads=\(receipt.requestedPayloadCount), valid=\(receipt.validPayloadCount), unique=\(receipt.uniquePayloadCount)",
                    requestID:
                        receipt.requestID
                )

                if let droppedReason =
                    receipt.droppedReason {
                    PhotoMemoShareDiagnostics.record(
                        stage: .appRequestDropped,
                        message:
                            droppedReason,
                        requestID:
                            receipt.requestID
                    )
                    recordAcknowledgementResult(
                        externalIntakeCenter
                            .acknowledgeProcessedRequests(
                                [request]
                            ),
                        requestID:
                            request.id
                    )
                    continue
                }

                PhotoMemoShareDiagnostics.record(
                    stage: .appEnqueueCreated,
                    message:
                        "tasks=\(receipt.uniquePayloadCount)",
                    requestID:
                        receipt.requestID,
                    jobID:
                        receipt.job?.id
                )

                recordEnqueuedTaskRoutes(
                    in: receipt.job,
                    requestID:
                        receipt.requestID
                )
                recordAcknowledgementResult(
                    externalIntakeCenter
                        .acknowledgeProcessedRequests(
                            [request]
                        ),
                    requestID:
                        request.id
                )
            case .failure(let error):
                PhotoMemoShareDiagnostics.record(
                    stage: .appEnqueueFailed,
                    message:
                        error.message,
                    requestID:
                        request.id
                )
            }
        }

        externalIntakeCenter.updateDefaultConfiguration(
            batchQueueStore
                .defaultConfigurationSnapshot
        )
    }

    private func recordAcknowledgementResult(
        _ result:
            PhotoMemoSharedDefaultsWriteResult,
        requestID: UUID
    ) {

        guard case .encodingFailed(let failure) = result else {
            return
        }

        PhotoMemoShareDiagnostics.record(
            stage:
                .appRequestAcknowledgementFailed,
            message:
                "storageKey=\(failure.storageKey) reason=\(failure.underlyingDescription)",
            requestID:
                requestID
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

    private func recordEnqueuedTaskRoutes(
        in job: BatchJob?,
        requestID: UUID
    ) {

        guard let job else {
            return
        }

        for task in job.tasks.prefix(20) {
            let contentType =
                task.contentTypeIdentifier
                ?? "nil"
            let hasSourceIdentifier =
                task.sourceIdentifier?
                .isEmpty == false

            PhotoMemoShareDiagnostics.record(
                stage: .appEnqueueTaskRoute,
                message:
                    "fileName=\(task.fileName), contentType=\(contentType), hasSourceIdentifier=\(hasSourceIdentifier)",
                requestID: requestID,
                jobID: job.id
            )
        }
    }
}
