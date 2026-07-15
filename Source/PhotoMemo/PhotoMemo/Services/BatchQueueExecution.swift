#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

@MainActor
final class BatchQueueExecution {
    struct TaskReference {
        let jobIndex: Int
        let taskIndex: Int
    }

    private let photoRepository: PhotoRepository
    private let previewCoordinator: PreviewCoordinator
    private let exportCoordinator: ExportCoordinator
    private let livePhotoProcessor: any LivePhotoBatchTaskProcessing
    private let diagnosticsDefaults: UserDefaults
    private let diagnosticsRecorder: BatchTaskDiagnosticsRecorder
    private let resourceLifecycle: BatchTaskResourceLifecycle
    private let renderHealthValidator:
        @MainActor (RecordCard, BatchConfigurationSnapshot) throws -> [CardTextBlock]
    private lazy var taskProcessor = BatchTaskProcessor(
        photoRepository: photoRepository,
        previewCoordinator: previewCoordinator,
        exportCoordinator: exportCoordinator,
        livePhotoProcessor: livePhotoProcessor,
        diagnosticsRecorder: diagnosticsRecorder,
        resourceLifecycle: resourceLifecycle,
        renderHealthValidator: renderHealthValidator
    )

    init(
        coordinator: BatchProcessingCoordinator? = nil,
        externalIntakeStore: ExternalPhotoIntakeStore? = nil,
        photoRepository: PhotoRepository? = nil,
        previewCoordinator: PreviewCoordinator? = nil,
        exportCoordinator: ExportCoordinator? = nil,
        livePhotoProcessor: (any LivePhotoBatchTaskProcessing)? = nil,
        diagnosticsDefaults: UserDefaults = PhotoMemoSharedContainer.sharedUserDefaults,
        renderHealthValidator: @escaping
            @MainActor (RecordCard, BatchConfigurationSnapshot) throws -> [CardTextBlock] =
                ProductionRenderHealthCheck.validate
    ) {
        let resolvedCoordinator = coordinator ?? BatchProcessingCoordinator()
        let resolvedPhotoImportService = PhotoImportService()
        let resolvedPhotoLibraryExportService = PhotoLibraryExportService()
        let resolvedPhotoLibraryRepository = PhotoLibraryRepository(
            photoLibraryExportService: resolvedPhotoLibraryExportService
        )
        self.photoRepository = photoRepository ?? PhotoRepository(
            importService: resolvedPhotoImportService,
            photoLibraryExportService: resolvedPhotoLibraryExportService
        )
        self.previewCoordinator = previewCoordinator ?? PreviewCoordinator(
            buildService: RecordCardBuildService()
        )
        self.exportCoordinator = exportCoordinator ?? ExportCoordinator(
            exportService: RecordCardExportService(),
            photoLibraryRepository: resolvedPhotoLibraryRepository
        )
        let resolvedExternalIntakeStore = externalIntakeStore ?? .shared
        self.diagnosticsDefaults = diagnosticsDefaults
        self.diagnosticsRecorder = BatchTaskDiagnosticsRecorder(defaults: diagnosticsDefaults)
        self.resourceLifecycle = BatchTaskResourceLifecycle(
            coordinator: resolvedCoordinator,
            externalIntakeStore: resolvedExternalIntakeStore
        )
        self.livePhotoProcessor = livePhotoProcessor ?? LivePhotoBatchTaskProcessor(
            diagnosticsDefaults: diagnosticsDefaults
        )
        self.renderHealthValidator = renderHealthValidator
    }

    func enqueue(
        payloads: [BatchTaskIntakePayload],
        configuration: BatchConfigurationSnapshot,
        launchSource: BatchJobLaunchSource,
        intakeSummary: ExternalPhotoImportSummary? = nil,
        title: String? = nil
    ) -> BatchJob? {
        guard !payloads.isEmpty else { return nil }
        if configuration.productionContractVersion != nil {
            do {
                try ProductionConfigurationSnapshotContract.validate(configuration)
            } catch {
                _ = PhotoMemoShareDiagnostics.recordResult(
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
            intakeSummary: intakeSummary
        )
        diagnosticsRecorder.recordAdmissionDiagnostics(for: job)
        return job
    }

    func retryFailedTasks(in jobs: inout [BatchJob], jobID: UUID) -> Bool {
        guard let jobIndex = jobs.firstIndex(where: { $0.id == jobID }) else { return false }
        var job = jobs[jobIndex]
        var didQueueRetry = false
        for index in job.tasks.indices {
            guard job.tasks[index].phase == .failed,
                  job.tasks[index].failure?.canRetry ?? true else {
                continue
            }
            job.tasks[index].phase = .queued
            job.tasks[index].failure = nil
            job.tasks[index].renderedFileURL = nil
            job.tasks[index].notificationAttachmentURL = nil
            job.tasks[index].savedAlbumName = nil
            job.tasks[index].savedAssetIdentifier = nil
            job.tasks[index].progress = BatchTaskProgress()
            job.tasks[index].retryCount += 1
            didQueueRetry = true
        }
        guard didQueueRetry else { return false }
        job.updatedAt = Date()
        job.finalNotificationSentAt = nil
        job.state = derivedJobState(from: job.tasks)
        jobs[jobIndex] = job
        return true
    }

    func cancelJob(in jobs: inout [BatchJob], jobID: UUID) -> Bool {
        guard let jobIndex = jobs.firstIndex(where: { $0.id == jobID }) else { return false }
        var job = jobs[jobIndex]
        for index in job.tasks.indices {
            guard !job.tasks[index].phase.isTerminal else { continue }
            let sourceURL = job.tasks[index].sourceURL
            job.tasks[index].phase = .cancelled
            job.tasks[index].progress = BatchTaskProgress(
                currentUnit: 1,
                totalUnits: 1,
                statusMessage: "已取消"
            )
            resourceLifecycle.cleanupManagedSourceIfNeeded(at: sourceURL)
        }
        job.updatedAt = Date()
        job.state = .cancelled
        jobs[jobIndex] = job
        return true
    }

    func processingLoop(in store: BatchQueueStore) async {
        store.markProcessingStarted()
        defer { store.processingLoopDidFinish() }
        while let reference = nextPendingTaskReference(in: store.jobs) {
            await processTask(at: reference, in: store)
        }
    }

    func processTask(at reference: TaskReference, in store: BatchQueueStore) async {
        guard let initialTask = store.currentTask(at: reference) else { return }
        let memoryBudget = mediaMemoryBudget(for: initialTask)
        let totalProgressUnits = memoryBudget.requiresExtendedPreviewPreparation ? 6 : 5
        await taskProcessor.process(
            context: BatchTaskExecutionContext(
                taskReference: reference,
                taskSnapshot: initialTask,
                configuration: store.currentJob(at: reference)?.configuration,
                memoryBudget: memoryBudget,
                route: "unknown",
                totalProgressUnits: totalProgressUnits,
                startedAt: Date()
            ),
            in: store
        )
    }

    func nextPendingTaskReference(in jobs: [BatchJob]) -> TaskReference? {
        for jobIndex in jobs.indices {
            for taskIndex in jobs[jobIndex].tasks.indices
            where jobs[jobIndex].tasks[taskIndex].phase == .queued {
                return TaskReference(jobIndex: jobIndex, taskIndex: taskIndex)
            }
        }
        return nil
    }

    func derivedJobState(from tasks: [BatchTask]) -> BatchJobState {
        guard !tasks.isEmpty else { return .draft }
        if tasks.allSatisfy({ $0.phase == .completed }) { return .completed }
        if tasks.allSatisfy({ $0.phase == .cancelled }) { return .cancelled }
        if tasks.contains(where: { $0.phase == .savingToPhotoLibrary || $0.phase == .exporting }) {
            return .running
        }
        if tasks.contains(where: {
            $0.phase == .previewReady || $0.phase == .waitingForExport || $0.phase == .metadataReady
        }) {
            return .ready
        }
        if tasks.contains(where: { $0.phase == .importing }) { return .preparing }
        if tasks.contains(where: { $0.phase == .queued }) { return .queued }
        if tasks.contains(where: { $0.phase == .failed }) { return .failed }
        return .draft
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
        return PhotoMemoQueueDisplayFormatter.title(
            startedAt: startedAt,
            photoCount: taskCount
        )
    }
}
#endif
