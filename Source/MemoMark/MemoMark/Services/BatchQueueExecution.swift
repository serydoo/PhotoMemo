#if !MEMOMARK_SHARE_EXTENSION
import Foundation

@MainActor
final class BatchQueueExecution {
    typealias TaskReference = BatchTaskReference

    private let queueCoordinator: BatchQueueCoordinator

    init(
        externalIntakeStore: ExternalPhotoIntakeStore? = nil,
        photoRepository: PhotoRepository? = nil,
        photoLibraryExportService:
            PhotoLibraryExportService? = nil,
        buildRecordCard:
            BuildRecordCardTransaction? = nil,
        exportCoordinator: ExportCoordinator? = nil,
        livePhotoProcessor: (any LivePhotoBatchTaskProcessing)? = nil,
        outputFilenameSequenceStore:
            LivePhotoOutputFilenameSequenceStore? = nil,
        diagnosticsDefaults: UserDefaults = MemoMarkSharedContainer.sharedUserDefaults,
        productionDiagnostics:
            ProductionDiagnosticsRepository? = nil,
        renderHealthValidator: @escaping
            @MainActor (RecordCard, BatchConfigurationSnapshot) async throws -> [CardTextBlock] = {
                card,
                configuration in
                try ProductionRenderHealthCheck.validate(
                    card: card,
                    configuration: configuration
                )
            }
    ) {
        let resolvedPhotoImportService = PhotoImportService()
        let resolvedPhotoLibraryExportService =
            photoLibraryExportService
            ?? PhotoLibraryExportService()
        let resolvedPhotoLibraryRepository = PhotoLibraryRepository(
            photoLibraryExportService: resolvedPhotoLibraryExportService
        )
        let resolvedPhotoRepository = photoRepository ?? PhotoRepository(
            importService: resolvedPhotoImportService,
            photoLibraryExportService: resolvedPhotoLibraryExportService
        )
        let resolvedBuildRecordCard =
            buildRecordCard
            ?? BuildRecordCardTransaction(
                buildService: RecordCardBuildService()
            )
        let resolvedOutputFilenameSequenceStore =
            outputFilenameSequenceStore
            ?? .shared
        let resolvedExportCoordinator = exportCoordinator ?? ExportCoordinator(
            exportService:
                RecordCardExportService(
                    outputFilenameSequenceStore:
                        resolvedOutputFilenameSequenceStore
                ),
            photoLibraryRepository: resolvedPhotoLibraryRepository
        )
        let resolvedExternalIntakeStore = externalIntakeStore ?? .shared
        let resolvedDiagnosticsRecorder = BatchTaskDiagnosticsRecorder(
            defaults: diagnosticsDefaults,
            productionDiagnostics:
                productionDiagnostics
        )
        let resolvedResourceLifecycle = BatchTaskResourceLifecycle(
            externalIntakeStore: resolvedExternalIntakeStore
        )
        let resolvedLivePhotoProcessor = livePhotoProcessor ?? LivePhotoBatchTaskProcessor(
            buildRecordCard:
                resolvedBuildRecordCard,
            photoLibraryExportService:
                resolvedPhotoLibraryExportService,
            diagnosticsDefaults: diagnosticsDefaults,
            outputFilenameSequenceStore:
                resolvedOutputFilenameSequenceStore
        )
        let taskProcessor = BatchTaskProcessor(
            photoRepository: resolvedPhotoRepository,
            buildRecordCard: resolvedBuildRecordCard,
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
        intakeRequestID: UUID? = nil,
        title: String? = nil
    ) -> BatchJob? {
        queueCoordinator.enqueue(
            payloads: payloads,
            configuration: configuration,
            launchSource: launchSource,
            intakeSummary: intakeSummary,
            intakeRequestID: intakeRequestID,
            title: title
        )
    }

    func retryFailedTasks(in jobs: inout [BatchJob], jobID: UUID) -> Bool {
        queueCoordinator.retryFailedTasks(in: &jobs, jobID: jobID)
    }

    func cancelJob(in jobs: inout [BatchJob], jobID: UUID) -> Bool {
        queueCoordinator.cancelJob(in: &jobs, jobID: jobID)
    }

    func cleanupManagedSourceIfNeeded(
        at url: URL?
    ) {
        queueCoordinator
            .cleanupManagedSourceIfNeeded(
                at: url
            )
    }

    func cleanupTemporaryFileIfNeeded(
        at url: URL?
    ) {
        queueCoordinator
            .cleanupTemporaryFileIfNeeded(
                at: url
            )
    }

    func processingLoop(
        in runtime: any BatchQueueProcessingRuntime
    ) async {
        await queueCoordinator.processingLoop(in: runtime)
    }

    func processTask(
        at reference: TaskReference,
        in runtime: any BatchQueueProcessingRuntime
    ) async {
        await queueCoordinator.processTask(
            at: reference,
            in: runtime
        )
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
