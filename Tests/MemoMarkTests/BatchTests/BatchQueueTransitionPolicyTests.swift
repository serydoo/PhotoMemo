#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Batch queue transition policy")
struct BatchQueueTransitionPolicyTests {

    private let fixedDate =
        Date(timeIntervalSince1970: 1_000)

    @Test("retry admission requires a failed retryable task")
    func retryAdmissionRequiresFailedRetryableTask() {
        let policy = BatchQueueTransitionPolicy()

        #expect(
            policy.canRetry(
                phase: .failed,
                failureCanRetry: true
            )
        )
        #expect(
            policy.canRetry(
                phase: .failed,
                failureCanRetry: nil
            )
        )
        #expect(
            !policy.canRetry(
                phase: .failed,
                failureCanRetry: false
            )
        )
        #expect(
            !policy.canRetry(
                phase: .queued,
                failureCanRetry: true
            )
        )
    }

    @Test("cancellation protects terminal and Photo Library commit phases")
    func cancellationProtectsTerminalAndCommitPhases() {
        let policy = BatchQueueTransitionPolicy()

        #expect(policy.canCancel(phase: .queued))
        #expect(policy.canCancel(phase: .exporting))
        #expect(!policy.canCancel(phase: .savingToPhotoLibrary))
        #expect(!policy.canCancel(phase: .completed))
        #expect(!policy.canCancel(phase: .failed))
        #expect(!policy.canCancel(phase: .cancelled))
    }

    @Test(
        "job state derives from task phases using the existing production precedence",
        arguments: [
            ([BatchTaskPhase](), BatchJobState.draft),
            ([.completed, .completed], .completed),
            ([.cancelled, .cancelled], .cancelled),
            ([.queued, .savingToPhotoLibrary], .running),
            ([.queued, .exporting], .running),
            ([.queued, .previewReady], .ready),
            ([.queued, .waitingForExport], .ready),
            ([.queued, .metadataReady], .ready),
            ([.queued, .importing], .preparing),
            ([.queued, .failed], .queued),
            ([.failed], .failed)
        ]
    )
    func derivesJobState(
        phases: [BatchTaskPhase],
        expected: BatchJobState
    ) {
        #expect(
            BatchQueueTransitionPolicy()
                .derivedJobState(from: phases)
            == expected
        )
    }

    @Test("job admission is idempotent for one intake request")
    @MainActor
    func admissionIsIdempotent() {
        let policy = BatchQueueTransitionPolicy()
        let requestID = UUID()
        let existing = makeJob(
            phase: .queued,
            intakeRequestID: requestID
        )
        let duplicate = makeJob(
            phase: .queued,
            intakeRequestID: requestID
        )
        var jobs = [existing]

        let admitted = policy.admit(
            duplicate,
            into: &jobs
        )

        #expect(admitted.job == existing)
        #expect(!admitted.didInsert)
        #expect(jobs == [existing])
    }

    @Test("retry mutation resets only retryable failures")
    @MainActor
    func retryMutationPreservesProductionSemantics() {
        let policy = BatchQueueTransitionPolicy()
        var job = makeJob(phase: .failed)
        job.tasks[0].failure = BatchTaskFailure(
            phase: .exporting,
            message: "failed",
            canRetry: true
        )
        job.tasks[0].renderedFileURL =
            URL(fileURLWithPath: "/tmp/rendered.jpg")
        var jobs = [job]

        #expect(
            policy.retryFailedTasks(
                in: &jobs,
                jobID: job.id,
                now: fixedDate
            )
        )
        #expect(jobs[0].tasks[0].phase == .queued)
        #expect(jobs[0].tasks[0].failure == nil)
        #expect(jobs[0].tasks[0].renderedFileURL == nil)
        #expect(jobs[0].tasks[0].retryCount == 1)
        #expect(jobs[0].updatedAt == fixedDate)
        #expect(jobs[0].state == .queued)
    }

    @Test("task events update one task and reject stale transitions")
    @MainActor
    func taskEventsAreAtomic() {
        let policy = BatchQueueTransitionPolicy()
        let job = makeJob(phase: .queued)
        let reference = BatchTaskReference(
            jobID: job.id,
            taskID: job.tasks[0].id
        )
        var jobs = [job]

        let result = policy.apply(
            .processingStarted(
                progress: BatchTaskProgress(
                    currentUnit: 1,
                    totalUnits: 5,
                    stage: .readingOriginal
                )
            ),
            at: reference,
            in: &jobs,
            now: fixedDate
        )

        #expect(result?.previous.phase == .queued)
        #expect(result?.updated.phase == .importing)
        #expect(jobs[0].updatedAt == fixedDate)
        #expect(jobs[0].state == .preparing)

        let stale = policy.apply(
            .processingStarted(
                progress: BatchTaskProgress()
            ),
            at: reference,
            in: &jobs,
            now: fixedDate
        )
        #expect(stale == nil)
        #expect(jobs[0].tasks[0].phase == .importing)
    }

    @Test("external terminal history removal preserves in-app and active work")
    @MainActor
    func terminalHistoryRemovalIsScoped() {
        let policy = BatchQueueTransitionPolicy()
        var externalTerminal = makeJob(phase: .completed)
        externalTerminal.launchSource = .shareExtension
        var externalActive = makeJob(phase: .queued)
        externalActive.launchSource = .shareExtension
        let inAppTerminal = makeJob(phase: .completed)
        var jobs = [
            externalTerminal,
            externalActive,
            inAppTerminal
        ]

        let removal = policy.clearTerminalExternalHistory(
            in: &jobs,
            preserving: nil
        )

        #expect(removal.didChange)
        #expect(
            removal.removedTaskIDs
            == Set(externalTerminal.tasks.map {
                $0.id.uuidString
            })
        )
        #expect(jobs.map(\.id) == [
            externalActive.id,
            inAppTerminal.id
        ])
    }

    @MainActor
    private func makeJob(
        phase: BatchTaskPhase,
        intakeRequestID: UUID? = nil
    ) -> BatchJob {
        BatchJob(
            title: "Queue",
            configuration:
                SettingsService()
                .buildBatchConfigurationSnapshot(),
            tasks: [
                BatchTask(
                    sourceURL:
                        URL(fileURLWithPath: "/tmp/source.jpg"),
                    phase: phase
                )
            ],
            intakeRequestID: intakeRequestID
        )
    }
}
#endif
