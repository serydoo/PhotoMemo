import Foundation

final class DiagnosticsRepository {

    private let defaults:
        UserDefaults

    private let sharedQueueSnapshotService:
        SharedBatchQueueSnapshotService

    init(
        defaults: UserDefaults,
        sharedQueueSnapshotService:
            SharedBatchQueueSnapshotService
    ) {
        self.defaults = defaults
        self.sharedQueueSnapshotService =
            sharedQueueSnapshotService
    }

    func recordShareDiagnostic(
        stage: PhotoMemoShareDiagnosticStage,
        message: String,
        requestID: UUID? = nil,
        jobID: UUID? = nil
    ) -> PhotoMemoResult<Void> {

        switch PhotoMemoShareDiagnostics
            .recordResult(
                stage: stage,
                message: message,
                requestID: requestID,
                jobID: jobID,
                defaults: defaults
            ) {
        case .success:
            return .success(())
        case .encodingFailed(let failure):
            return .failure(
                .writeFailure(
                    failure,
                    message:
                        "Unable to persist share diagnostics."
                )
            )
        }
    }

    func loadShareDiagnostics()
    -> PhotoMemoResult<
        [PhotoMemoShareDiagnosticEvent]
    > {

        switch PhotoMemoShareDiagnostics
            .loadEventsResult(
                defaults: defaults
            ) {
        case .success(let events):
            return .success(events)
        case .noValue:
            return .success([])
        case .decodingFailed(let failure):
            return .failure(
                .readFailure(
                    failure,
                    message:
                        "Unable to read share diagnostics."
                )
            )
        }
    }

    func loadSharedQueueJobs()
    -> PhotoMemoResult<[BatchJob]> {

        switch sharedQueueSnapshotService
            .loadJobsResult() {
        case .success(let jobs):
            return .success(jobs)
        case .noValue:
            return .success([])
        case .decodingFailed(let failure):
            return .failure(
                .readFailure(
                    failure,
                    message:
                        "Unable to read the shared batch queue snapshot."
                )
            )
        }
    }

    func loadProcessingDiagnosticsSnapshot()
    -> PhotoMemoResult<
        PhotoMemoiOSProcessingDiagnosticsSnapshot
    > {

        .success(
            PhotoMemoiOSProcessingDiagnosticsSnapshot
            .load(
                defaults: defaults
            )
        )
    }
}
