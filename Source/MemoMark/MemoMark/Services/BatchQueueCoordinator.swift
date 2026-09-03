#if !MEMOMARK_SHARE_EXTENSION
import Foundation

@MainActor
final class BatchQueueCoordinator {
    typealias TaskReference =
        BatchTaskReference

    private let diagnosticsDefaults: UserDefaults
    private let diagnosticsRecorder: BatchTaskDiagnosticsRecorder
    private let resourceLifecycle: BatchTaskResourceLifecycle
    private let taskProcessor: BatchTaskProcessor

    private let transitionPolicy =
        BatchQueueTransitionPolicy()

    init(
        diagnosticsDefaults: UserDefaults,
        diagnosticsRecorder: BatchTaskDiagnosticsRecorder,
        resourceLifecycle: BatchTaskResourceLifecycle,
        taskProcessor: BatchTaskProcessor
    ) {
        self.diagnosticsDefaults = diagnosticsDefaults
        self.diagnosticsRecorder = diagnosticsRecorder
        self.resourceLifecycle = resourceLifecycle
        self.taskProcessor = taskProcessor
    }

    func enqueue(
        payloads: [BatchTaskIntakePayload],
        configuration: BatchConfigurationSnapshot,
        launchSource: BatchJobLaunchSource,
        intakeSummary: ExternalPhotoImportSummary? = nil,
        intakeRequestID: UUID? = nil,
        title: String? = nil
    ) -> BatchJob? {
        guard !payloads.isEmpty else { return nil }
        if configuration.productionContractVersion != nil {
            do {
                try ProductionConfigurationSnapshotContract.validate(configuration)
            } catch {
                _ = MemoMarkShareDiagnostics.recordResult(
                    stage: .configurationContractViolation,
                    message:
                        "source=\(launchSource.rawValue) configurationID=\(configuration.configurationID?.uuidString ?? "nil") revision=\(configuration.configurationRevision.map(String.init) ?? "nil") admission=rejected reason=\(String(describing: error))",
                    defaults: diagnosticsDefaults
                )
                return nil
            }
        }

        let tasks = payloads.map {
            BatchTask(
                sourceURL: $0.sourceURL,
                fileName: $0.fileName,
                sourceIdentifier: $0.sourceIdentifier,
                contentTypeIdentifier: $0.contentTypeIdentifier,
                createdAt: $0.requestedAt
            )
        }
        let createdAt = tasks.map(\.createdAt).min() ?? Date()
        let job = BatchJob(
            title: resolvedJobTitle(
                customTitle: title,
                taskCount: tasks.count,
                startedAt: createdAt
            ),
            createdAt: createdAt,
            state: .queued,
            launchSource: launchSource,
            configuration: configuration,
            tasks: tasks,
            intakeSummary: intakeSummary,
            intakeRequestID: intakeRequestID
        )
        diagnosticsRecorder.recordAdmissionDiagnostics(for: job)
        return job
    }

    func retryFailedTasks(in jobs: inout [BatchJob], jobID: UUID) -> Bool {
        transitionPolicy.retryFailedTasks(
            in: &jobs,
            jobID: jobID,
            now: Date()
        )
    }

    func cancelJob(in jobs: inout [BatchJob], jobID: UUID) -> Bool {
        transitionPolicy.cancelJob(
            in: &jobs,
            jobID: jobID,
            now: Date()
        )
    }

    func cleanupManagedSourceIfNeeded(
        at url: URL?
    ) {
        resourceLifecycle
            .cleanupManagedSourceIfNeeded(
                at: url
            )
    }

    func cleanupTemporaryFileIfNeeded(
        at url: URL?
    ) {
        resourceLifecycle
            .cleanupTemporaryFile(
                at: url
            )
    }

    func processingLoop(
        in runtime: any BatchQueueProcessingRuntime
    ) async {
        runtime.markProcessingStarted()
        while !Task.isCancelled,
              runtime.canContinueProcessing,
              let reference = runtime.nextPendingTaskReference() {
            await processTask(at: reference, in: runtime)
        }
        await runtime.processingLoopDidFinish(
            shouldRestart: !Task.isCancelled
        )
    }

    func processTask(
        at reference: TaskReference,
        in runtime: any BatchQueueProcessingRuntime
    ) async {
        guard let initialTask = runtime.processingTask(at: reference) else { return }
        let memoryBudget = mediaMemoryBudget(for: initialTask)
        let totalProgressUnits = memoryBudget.requiresExtendedPreviewPreparation ? 6 : 5
        guard let configuration = runtime.processingConfiguration(
            at: reference
        ) else {
            return
        }
        let route = BatchTaskMemoryPolicy.processingRoute(
            for: initialTask
        )
        await taskProcessor.process(
            context: BatchTaskExecutionContext(
                taskReference: reference,
                taskSnapshot: initialTask,
                configuration: configuration,
                memoryBudget: memoryBudget,
                route: route,
                totalProgressUnits: totalProgressUnits,
                startedAt: Date()
            ),
            runtime: runtime
        )
    }

    func nextPendingTaskReference(in jobs: [BatchJob]) -> TaskReference? {
        for jobIndex in jobs.indices {
            for taskIndex in jobs[jobIndex].tasks.indices
            where jobs[jobIndex].tasks[taskIndex].phase == .queued {
                return TaskReference(
                    jobID: jobs[jobIndex].id,
                    taskID: jobs[jobIndex].tasks[taskIndex].id
                )
            }
        }
        return nil
    }

    func derivedJobState(from tasks: [BatchTask]) -> BatchJobState {
        transitionPolicy.derivedJobState(
            from: tasks.map(\.phase)
        )
    }

    func mediaMemoryBudget(for task: BatchTask) -> MediaMemoryBudget {
        BatchTaskMemoryPolicy.mediaMemoryBudget(for: task)
    }

    private func resolvedJobTitle(
        customTitle: String?,
        taskCount: Int,
        startedAt: Date
    ) -> String {
        let trimmedTitle = customTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedTitle.isEmpty { return trimmedTitle }
        return MemoMarkQueueDisplayFormatter.title(
            startedAt: startedAt,
            photoCount: taskCount
        )
    }
}
#endif
