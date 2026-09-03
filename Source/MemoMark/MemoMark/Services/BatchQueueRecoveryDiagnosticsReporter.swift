#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// The normalized failure discovered while recovering persisted queue work.
/// It carries no ownership of queue state; callers remain responsible for
/// deciding when a recovery result is durable enough to be reported.
struct BatchQueueRecoveredFailure {

    let jobID: UUID
    let task: BatchTask
    let failure: BatchTaskFailure
}

/// Projects recovery failures into the durable diagnostics stream. Both
/// synchronous bootstrap and actor-backed resume use this exact event shape,
/// so support tooling does not have two meanings for `processing.recovery`.
enum BatchQueueRecoveryDiagnosticsReporter {

    static func record(
        _ recoveredFailures: [BatchQueueRecoveredFailure],
        to productionDiagnostics: ProductionDiagnosticsRepository
    ) async {

        for recoveredFailure in recoveredFailures {
            let task = recoveredFailure.task
            let failure = recoveredFailure.failure
            let pixelSize = MediaPixelSize(
                fileURL: task.sourceURL
            )
            await productionDiagnostics.record(
                ProductionDiagnosticEvent(
                    operationID: task.id,
                    category: .processing,
                    stage:
                        "processing.recovery.\(failure.phase.rawValue)",
                    outcome: .failed,
                    errorCode:
                        failure.diagnosticCode.flatMap {
                            ProductionDiagnosticErrorCode(
                                rawValue: $0
                            )
                        },
                    context:
                        ProductionDiagnosticContext(
                            jobID: recoveredFailure.jobID,
                            taskID: task.id,
                            mediaContentTypeIdentifier:
                                task.contentTypeIdentifier,
                            mediaPixelWidth:
                                pixelSize?.width,
                            mediaPixelHeight:
                                pixelSize?.height,
                            processingPhase:
                                failure.phase.rawValue
                        )
                )
            )
        }
    }
}
#endif
