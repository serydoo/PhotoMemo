#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

@MainActor
final class BatchQueueExecution {
    typealias TaskReference = BatchQueueCoordinator.TaskReference

    private let queueCoordinator: BatchQueueCoordinator

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
        let resolvedPhotoRepository = photoRepository ?? PhotoRepository(
            importService: resolvedPhotoImportService,
            photoLibraryExportService: resolvedPhotoLibraryExportService
        )
        let resolvedPreviewCoordinator = previewCoordinator ?? PreviewCoordinator(
            buildService: RecordCardBuildService()
        )
        let resolvedExportCoordinator = exportCoordinator ?? ExportCoordinator(
            exportService: RecordCardExportService(),
            photoLibraryRepository: resolvedPhotoLibraryRepository
        )
        let resolvedExternalIntakeStore = externalIntakeStore ?? .shared
        let resolvedDiagnosticsRecorder = BatchTaskDiagnosticsRecorder(defaults: diagnosticsDefaults)
        let resolvedResourceLifecycle = BatchTaskResourceLifecycle(
            coordinator: resolvedCoordinator,
            externalIntakeStore: resolvedExternalIntakeStore
        )
        let resolvedLivePhotoProcessor = livePhotoProcessor ?? LivePhotoBatchTaskProcessor(
            diagnosticsDefaults: diagnosticsDefaults
        )
        let taskProcessor = BatchTaskProcessor(
            photoRepository: resolvedPhotoRepository,
            previewCoordinator: resolvedPreviewCoordinator,
            exportCoordinator: resolvedExportCoordinator,
            livePhotoProcessor: resolvedLivePhotoProcessor,
            diagnosticsRecorder: resolvedDiagnosticsRecorder,
            resourceLifecycle: resolvedResourceLifecycle,
            renderHealthValidator: renderHealthValidator
        )
        self.queueCoordinator = BatchQueueCoordinator(
            diagnosticsDefaults: diagnosticsDefaults,
            diagnosticsRecorder: resolvedDiagnosticsRecorder,
            resourceLifecycle: resolvedResourceLifecycle,
            taskProcessor: taskProcessor
        )
    }

    func enqueue(
        payloads: [BatchTaskIntakePayload],
        configuration: BatchConfigurationSnapshot,
        launchSource: BatchJobLaunchSource,
        intakeSummary: ExternalPhotoImportSummary? = nil,
        title: String? = nil
    ) -> BatchJob? {
        queueCoordinator.enqueue(
            payloads: payloads,
            configuration: configuration,
            launchSource: launchSource,
            intakeSummary: intakeSummary,
            title: title
        )
    }

    func retryFailedTasks(in jobs: inout [BatchJob], jobID: UUID) -> Bool {
        queueCoordinator.retryFailedTasks(in: &jobs, jobID: jobID)
    }

    func cancelJob(in jobs: inout [BatchJob], jobID: UUID) -> Bool {
        queueCoordinator.cancelJob(in: &jobs, jobID: jobID)
    }

    func processingLoop(in store: BatchQueueStore) async {
        await queueCoordinator.processingLoop(in: store)
    }

    func processTask(at reference: TaskReference, in store: BatchQueueStore) async {
        await queueCoordinator.processTask(at: reference, in: store)
    }

    func nextPendingTaskReference(in jobs: [BatchJob]) -> TaskReference? {
        queueCoordinator.nextPendingTaskReference(in: jobs)
    }

    func derivedJobState(from tasks: [BatchTask]) -> BatchJobState {
        queueCoordinator.derivedJobState(from: tasks)
    }

    func mediaMemoryBudget(for task: BatchTask) -> MediaMemoryBudget {
        queueCoordinator.mediaMemoryBudget(for: task)
    }
}
#endif
