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

    @Test("session cancellation stops every pending job in that session and protects saves")
    @MainActor
    func executionSessionCancellationIsScopedAndPreservesPhotoKitCommit() {
        let policy = BatchQueueTransitionPolicy()
        let sessionID = UUID()
        var queued = makeJob(phase: .queued)
        queued.executionSessionID = sessionID
        var running = makeJob(phase: .exporting)
        running.executionSessionID = sessionID
        var saving = makeJob(phase: .savingToPhotoLibrary)
        saving.executionSessionID = sessionID
        var unrelated = makeJob(phase: .queued)
        unrelated.executionSessionID = UUID()
        var jobs = [queued, running, saving, unrelated]

        let didCancel = policy.cancelExecutionSession(
            in: &jobs,
            sessionID: sessionID,
            now: fixedDate
        )

        #expect(didCancel)
        #expect(jobs[0].tasks[0].phase == .cancelled)
        #expect(jobs[1].tasks[0].phase == .cancelled)
        #expect(jobs[2].tasks[0].phase == .savingToPhotoLibrary)
        #expect(jobs[3].tasks[0].phase == .queued)
        #expect(jobs[0].state == .cancelled)
        #expect(jobs[1].state == .cancelled)
        #expect(jobs[2].state == .draft)
        #expect(jobs[3].state == .draft)
        #expect(jobs[0].updatedAt == fixedDate)
        #expect(jobs[3].updatedAt != fixedDate)
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

    @Test("consecutive shares join one durable session and terminal sessions close")
    @MainActor func continuousSessionAdmission() {
        let policy = BatchQueueTransitionPolicy()
        var jobs: [BatchJob] = []
        let first = policy.admit(makeJob(phase: .queued), into: &jobs).job
        let second = policy.admit(makeJob(phase: .queued), into: &jobs).job
        #expect(first.executionSessionID != nil)
        #expect(first.executionSessionID == second.executionSessionID)
        for index in jobs.indices { jobs[index].tasks[0].phase = .completed }
        let next = policy.admit(makeJob(phase: .queued), into: &jobs).job
        #expect(next.executionSessionID != first.executionSessionID)
    }

    @Test("a share received while a predecessor ran joins its session despite delayed admission")
    @MainActor func delayedShareSessionAdmission() {
        let policy = BatchQueueTransitionPolicy()
        var previous = makeJob(phase: .completed)
        previous.executionSessionID = UUID()
        previous.createdAt = Date(timeIntervalSince1970: 100)
        previous.updatedAt = Date(timeIntervalSince1970: 120)
        var incoming = makeJob(phase: .queued)
        incoming.createdAt = Date(timeIntervalSince1970: 110)
        var jobs = [previous]
        #expect(policy.admit(incoming, into: &jobs).job.executionSessionID == previous.executionSessionID)
    }

    @Test("continued processing progress includes every admitted member of the session")
    @MainActor func sessionProgressIncludesEarlierBatch() {
        let id = UUID()
        var first = makeJob(phase: .completed)
        first.executionSessionID = id
        var second = makeJob(phase: .queued)
        second.executionSessionID = id
        second.tasks[0].progress = BatchTaskProgress(currentUnit: 1, totalUnits: 2, stage: .renderingImage)
        let unrelated = makeJob(phase: .completed)
        let session = ExecutionSession(id: id, jobs: [first, second, unrelated])
        #expect(session.totalProgressUnits == 200)
        #expect(session.completedProgressUnits == 150)
        second.tasks[0].progress = BatchTaskProgress(currentUnit: 999, totalUnits: 1, stage: .renderingImage)
        #expect(ExecutionSession(id: id, jobs: [first, second]).completedProgressUnits == 195)
    }

    @Test("late shares never reopen completed, failed, cancelled or deleted histories")
    @MainActor func closedSessionAdmissionBoundaries() {
        let policy = BatchQueueTransitionPolicy()
        for phase in [BatchTaskPhase.completed, .failed, .cancelled] {
            for deleted in [false, true] {
                var previous = makeJob(phase: phase)
                previous.executionSessionID = UUID()
                previous.createdAt = Date(timeIntervalSince1970: 100)
                previous.updatedAt = Date(timeIntervalSince1970: 120)
                if deleted { previous.historyDeletedAt = Date(timeIntervalSince1970: 125) }
                var incoming = makeJob(phase: .queued)
                incoming.createdAt = Date(timeIntervalSince1970: phase == .completed && !deleted ? 130 : 110)
                var jobs = [previous]
                #expect(policy.admit(incoming, into: &jobs).job.executionSessionID != previous.executionSessionID)
            }
        }
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
