#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Owns one serialized drain of persisted external intake requests.
///
/// The coordinator does not enqueue directly: each request still crosses the
/// established `ShareCoordinator` admission boundary, which freezes the
/// configuration snapshot and delegates the durable queue write to its sole
/// owner. Requests are acknowledged only after that boundary returns success.
@MainActor
final class ExternalIntakeDrainCoordinator {

    private let externalIntakeCenter: ExternalPhotoIntakeCenter
    private let shareCoordinator: ShareCoordinator
    private let queueProjection: any ExternalIntakeQueueProjection

    private(set) var isDraining = false

    init(
        externalIntakeCenter: ExternalPhotoIntakeCenter,
        shareCoordinator: ShareCoordinator,
        queueProjection: any ExternalIntakeQueueProjection
    ) {
        self.externalIntakeCenter = externalIntakeCenter
        self.shareCoordinator = shareCoordinator
        self.queueProjection = queueProjection
    }

    @discardableResult
    func drain() async -> BackgroundQueuePreparationResult {
        guard !isDraining else {
            return .retryableFailure
        }
        isDraining = true
        defer {
            isDraining = false
        }

        let requests = externalIntakeCenter.drainPendingRequests()

        MemoMarkShareDiagnostics.record(
            stage: .appDrain,
            message: "drainedRequests=\(requests.count)"
        )

        if let failure = externalIntakeCenter.intakePersistenceError {
            MemoMarkShareDiagnostics.record(
                stage: .appDrain,
                message:
                    "requestPersistenceReadFailed storageKey=\(failure.storageKey) bytes=\(failure.payloadByteCount)"
            )
        }

        guard externalIntakeCenter.intakePersistenceError == nil else {
            return BackgroundQueuePreparationResult.resolve(
                enqueuedRequestCount: 0,
                failedRequestCount: 1,
                pendingTaskCount: queueProjection.pendingTaskCount
            )
        }

        guard !requests.isEmpty else {
            return BackgroundQueuePreparationResult.resolve(
                enqueuedRequestCount: 0,
                failedRequestCount: 0,
                pendingTaskCount: queueProjection.pendingTaskCount
            )
        }

        var consumedPayloadKeys = Set<String>()
        var enqueuedRequestCount = 0
        var failedRequestCount = 0

        for request in requests {
            let processedRequest =
                await ProcessShareIntent(
                    request: request,
                    consumedPayloadKeys: consumedPayloadKeys,
                    coordinator: shareCoordinator
                )
                .execute()

            switch processedRequest {
            case .success(let receipt):
                consumedPayloadKeys = receipt.consumedPayloadKeys

                MemoMarkShareDiagnostics.record(
                    stage: .appRequestValidated,
                    message:
                        "payloads=\(receipt.requestedPayloadCount), valid=\(receipt.validPayloadCount), unique=\(receipt.uniquePayloadCount)",
                    requestID: receipt.requestID
                )
                if receipt.job != nil {
                    enqueuedRequestCount += 1
                }

                if let droppedReason = receipt.droppedReason {
                    MemoMarkShareDiagnostics.record(
                        stage: .appRequestDropped,
                        message: droppedReason,
                        requestID: receipt.requestID
                    )
                    recordAcknowledgementResult(
                        externalIntakeCenter
                            .acknowledgeProcessedRequests([request]),
                        requestID: request.id
                    )
                    continue
                }

                MemoMarkShareDiagnostics.record(
                    stage: .appEnqueueCreated,
                    message: "tasks=\(receipt.uniquePayloadCount)",
                    requestID: receipt.requestID,
                    jobID: receipt.job?.id
                )

                recordEnqueuedTaskRoutes(
                    in: receipt.job,
                    requestID: receipt.requestID
                )
                recordAcknowledgementResult(
                    externalIntakeCenter
                        .acknowledgeProcessedRequests([request]),
                    requestID: request.id
                )

            case .failure(let error):
                failedRequestCount += 1
                MemoMarkShareDiagnostics.record(
                    stage: .appEnqueueFailed,
                    message: error.message,
                    requestID: request.id
                )
            }
        }

        externalIntakeCenter.updateDefaultConfiguration(
            queueProjection.defaultConfigurationSnapshot
        )

        return BackgroundQueuePreparationResult.resolve(
            enqueuedRequestCount: enqueuedRequestCount,
            failedRequestCount: failedRequestCount,
            pendingTaskCount: queueProjection.pendingTaskCount
        )
    }

    private func recordAcknowledgementResult(
        _ result: MemoMarkSharedDefaultsWriteResult,
        requestID: UUID
    ) {
        guard case .encodingFailed(let failure) = result else {
            return
        }

        MemoMarkShareDiagnostics.record(
            stage: .appRequestAcknowledgementFailed,
            message: "storageKey=\(failure.storageKey)",
            requestID: requestID
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
            let contentType = task.contentTypeIdentifier ?? "nil"
            let hasSourceIdentifier = task.sourceIdentifier?.isEmpty == false

            MemoMarkShareDiagnostics.record(
                stage: .appEnqueueTaskRoute,
                message:
                    "taskID=\(task.id.uuidString), contentType=\(contentType), hasSourceIdentifier=\(hasSourceIdentifier)",
                requestID: requestID,
                jobID: job.id
            )
        }
    }
}
#endif
