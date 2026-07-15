#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

@MainActor
final class BatchQueueExecution {

    struct TaskReference {

        let jobIndex: Int

        let taskIndex: Int
    }

    private let photoRepository:
        PhotoRepository

    private let previewCoordinator:
        PreviewCoordinator

    private let exportCoordinator:
        ExportCoordinator

    private let livePhotoProcessor:
        any LivePhotoBatchTaskProcessing

    private let diagnosticsDefaults:
        UserDefaults

    private let diagnosticsRecorder:
        BatchTaskDiagnosticsRecorder

    private let resourceLifecycle:
        BatchTaskResourceLifecycle

    private lazy var taskProcessor = BatchTaskProcessor { [weak self] context, store in
        await self?.processTaskInternal(
            context: context,
            in: store
        )
    }

    init(
        coordinator:
            BatchProcessingCoordinator? = nil,
        externalIntakeStore:
            ExternalPhotoIntakeStore? = nil,
        photoRepository:
            PhotoRepository? = nil,
        previewCoordinator:
            PreviewCoordinator? = nil,
        exportCoordinator:
            ExportCoordinator? = nil,
        livePhotoProcessor:
            (any LivePhotoBatchTaskProcessing)? = nil,
        diagnosticsDefaults:
            UserDefaults =
                PhotoMemoSharedContainer
                .sharedUserDefaults
    ) {
        let resolvedCoordinator =
            coordinator
            ?? BatchProcessingCoordinator()
        let resolvedPhotoImportService =
            PhotoImportService()
        let resolvedPhotoLibraryExportService =
            PhotoLibraryExportService()
        let resolvedPhotoLibraryRepository =
            PhotoLibraryRepository(
                photoLibraryExportService:
                    resolvedPhotoLibraryExportService
            )
        self.photoRepository =
            photoRepository
            ?? PhotoRepository(
                importService:
                    resolvedPhotoImportService,
                photoLibraryExportService:
                    resolvedPhotoLibraryExportService
            )
        self.previewCoordinator =
            previewCoordinator
            ?? PreviewCoordinator(
                buildService:
                    RecordCardBuildService()
            )
        self.exportCoordinator =
            exportCoordinator
            ?? ExportCoordinator(
                exportService:
                    RecordCardExportService(),
                photoLibraryRepository:
                    resolvedPhotoLibraryRepository
            )
        let resolvedExternalIntakeStore =
            externalIntakeStore
            ?? .shared
        self.diagnosticsDefaults =
            diagnosticsDefaults
        self.diagnosticsRecorder =
            BatchTaskDiagnosticsRecorder(
                defaults: diagnosticsDefaults
            )
        self.resourceLifecycle =
            BatchTaskResourceLifecycle(
                coordinator: resolvedCoordinator,
                externalIntakeStore:
                    resolvedExternalIntakeStore
            )
        self.livePhotoProcessor =
            livePhotoProcessor
            ?? LivePhotoBatchTaskProcessor(
                diagnosticsDefaults:
                    diagnosticsDefaults
            )
    }

    func enqueue(
        payloads: [BatchTaskIntakePayload],
        configuration: BatchConfigurationSnapshot,
        launchSource: BatchJobLaunchSource,
        intakeSummary:
            ExternalPhotoImportSummary? = nil,
        title: String? = nil
    ) -> BatchJob? {

        guard !payloads.isEmpty else {
            return nil
        }

        if configuration.productionContractVersion != nil {
            do {
                try ProductionConfigurationSnapshotContract
                    .validate(configuration)
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
                sourceIdentifier:
                    $0.sourceIdentifier,
                contentTypeIdentifier:
                    $0.contentTypeIdentifier,
                createdAt: $0.requestedAt
            )
        }

        let createdAt =
            tasks.map(
                \.createdAt
            )
            .min()
            ?? Date()

        let job =
            BatchJob(
            title:
                resolvedJobTitle(
                    customTitle: title,
                    taskCount: tasks.count,
                    startedAt:
                        createdAt
                ),
            createdAt:
                createdAt,
            state: .queued,
            launchSource: launchSource,
            configuration: configuration,
            tasks: tasks,
            intakeSummary:
                intakeSummary
        )

        diagnosticsRecorder.recordAdmissionDiagnostics(
            for: job
        )

        return job
    }

    func retryFailedTasks(
        in jobs: inout [BatchJob],
        jobID: UUID
    ) -> Bool {

        guard let jobIndex =
            jobs.firstIndex(
                where: { $0.id == jobID }
            ) else {
            return false
        }

        var job = jobs[jobIndex]
        var didQueueRetry = false

        for index in job.tasks.indices {
            guard job.tasks[index].phase == .failed,
                  job.tasks[index]
                  .failure?.canRetry ?? true else {
                continue
            }

            job.tasks[index].phase = .queued
            job.tasks[index].failure = nil
            job.tasks[index].renderedFileURL = nil
            job.tasks[index].notificationAttachmentURL = nil
            job.tasks[index].savedAlbumName = nil
            job.tasks[index].savedAssetIdentifier = nil
            job.tasks[index].progress =
                BatchTaskProgress()
            job.tasks[index].retryCount += 1
            didQueueRetry = true
        }

        guard didQueueRetry else {
            return false
        }

        job.updatedAt = Date()
        job.finalNotificationSentAt = nil
        job.state = derivedJobState(
            from: job.tasks
        )
        jobs[jobIndex] = job
        return true
    }

    func cancelJob(
        in jobs: inout [BatchJob],
        jobID: UUID
    ) -> Bool {

        guard let jobIndex =
            jobs.firstIndex(
                where: { $0.id == jobID }
            ) else {
            return false
        }

        var job = jobs[jobIndex]

        for index in job.tasks.indices {
            guard !job.tasks[index].phase
                .isTerminal else {
                continue
            }

            let sourceURL =
                job.tasks[index].sourceURL

            job.tasks[index].phase = .cancelled
            job.tasks[index].progress =
                BatchTaskProgress(
                    currentUnit: 1,
                    totalUnits: 1,
                    statusMessage: "已取消"
                )
            resourceLifecycle.cleanupManagedSourceIfNeeded(
                at: sourceURL
            )
        }

        job.updatedAt = Date()
        job.state = .cancelled
        jobs[jobIndex] = job
        return true
    }

    func processingLoop(
        in store: BatchQueueStore
    ) async {

        store.markProcessingStarted()

        defer {
            store.processingLoopDidFinish()
        }

        while let reference =
            nextPendingTaskReference(
                in: store.jobs
            ) {

            await processTask(
                at: reference,
                in: store
            )
        }
    }

    func processTask(
        at reference: TaskReference,
        in store: BatchQueueStore
    ) async {

        guard let initialTask =
            store.currentTask(
            at: reference
        ) else {
            return
        }

        let memoryBudget = mediaMemoryBudget(for: initialTask)
        let totalProgressUnits =
            memoryBudget.requiresExtendedPreviewPreparation ? 6 : 5
        await taskProcessor.process(
            context: BatchTaskExecutionContext(
                taskReference: reference,
                taskSnapshot: initialTask,
                configuration: store.currentJob(at: reference)?.configuration,
                memoryBudget: memoryBudget,
                route: "unknown",
                totalProgressUnits: totalProgressUnits,
                startedAt: Date(),
                renderHealthValidator: ProductionRenderHealthCheck.validate
            ),
            in: store
        )
    }

    private func processTaskInternal(
        context: BatchTaskExecutionContext,
        in store: BatchQueueStore
    ) async {

        let reference = context.taskReference
        let initialTask = context.taskSnapshot

        let memoryBudget =
            context.memoryBudget
        let requiresExtendedPreviewPreparation =
            memoryBudget
            .requiresExtendedPreviewPreparation
        let totalProgressUnits =
            requiresExtendedPreviewPreparation ? 6 : 5
        let startedAt = context.startedAt
        var route = "unknown"

        store.setActiveProcessingReference(
            reference
        )

        store.updateTask(
            at: reference
        ) { task in
            task.phase = .importing
            task.progress = BatchTaskProgress(
                currentUnit: 1,
                totalUnits: totalProgressUnits,
                statusMessage:
                    initialPreparationStatusMessage(
                        for: memoryBudget
                    )
            )
            task.failure = nil
        }

        var temporaryFileURL: URL?

        do {

            guard let task =
                store.currentTask(
                    at: reference
                ) else {
                return
            }

            let usesLivePhotoProcessing =
                BatchTaskMemoryPolicy.shouldUseLivePhotoProcessing(
                    for: task
                )
            route =
                usesLivePhotoProcessing
                ? "livePhoto"
                : "staticImage"
            let sourceURLIsLivePhotoBundle =
                LivePhotoSourceBundleLocator
                .canResolveBundle(
                    at: task.sourceURL
                )
            diagnosticsRecorder.recordRoute(
                for: task,
                sourceURLIsLivePhotoBundle:
                    sourceURLIsLivePhotoBundle,
                route: route,
                jobID:
                    store.currentJob(
                        at: reference
                    )?.id
            )

            if usesLivePhotoProcessing {
                try await diagnosticsRecorder.measureStageDuration(
                    "livePhotoProcessing",
                    route: route,
                    task: task,
                    jobID:
                        store.currentJobID(
                            at: reference
                        )
                ) {
                    try await processLivePhotoTask(
                        task: task,
                        at: reference,
                        in: store,
                        totalProgressUnits:
                            totalProgressUnits
                    )
                }
                diagnosticsRecorder.recordTaskDuration(
                    startedAt: startedAt,
                    route: route,
                    phase: .completed,
                    task: task,
                    jobID: store.currentJobID(
                        at: reference
                    )
                )
                return
            }

            let importedPhoto =
                try await diagnosticsRecorder.measureStageDuration(
                    "import",
                    route: route,
                    task: task,
                    jobID:
                        store.currentJobID(
                            at: reference
                        )
                ) {
                    try await requireValue(
                        ImportBatchPhotoIntent(
                            task: task,
                            contentTypeIdentifierOverride:
                                BatchTaskMemoryPolicy.staticImportContentTypeIdentifier(
                                    for: task,
                                    usesLivePhotoProcessing:
                                        usesLivePhotoProcessing
                                ),
                            repository:
                                photoRepository
                        )
                        .execute()
                    )
                }

            guard !BatchTaskFailurePolicy.shouldAbortFurtherProcessing(
                currentPhase:
                    store.currentTaskPhase(
                        at: reference
                    )
            ) else {
                return
            }

            store.updateTask(
                at: reference,
                persist: false
            ) { task in
                task.captureDate =
                    importedPhoto.metadata.captureDate
                task.phase = .metadataReady
                task.progress = BatchTaskProgress(
                    currentUnit:
                        requiresExtendedPreviewPreparation ? 3 : 2,
                    totalUnits:
                        totalProgressUnits,
                    statusMessage:
                        completedPreparationStatusMessage(
                            for: memoryBudget
                        )
                )
            }

            guard let configuration =
                store.currentJob(
                    at: reference
                )?.configuration else {
                return
            }

            let card =
                try await diagnosticsRecorder.measureStageDuration(
                    "build",
                    route: route,
                    task: task,
                    jobID:
                        store.currentJobID(
                            at: reference
                        )
                ) {
                    try requireValue(
                        await BuildPreviewIntent(
                            photo: importedPhoto,
                            configuration:
                                configuration,
                            coordinator:
                                previewCoordinator
                        )
                        .execute()
                    )
                }

            do {
                _ = try context.renderHealthValidator(card, configuration)
                diagnosticsRecorder.recordRenderHealthCheckPassed(
                    task: task,
                    launchSource:
                        store.currentJob(
                            at: reference
                        )?.launchSource,
                    configuration: configuration,
                    jobID:
                        store.currentJobID(
                            at: reference
                        )
                )
            } catch {
                diagnosticsRecorder.recordRenderHealthCheckFailed(
                    task: task,
                    configuration: configuration,
                    error: error,
                    jobID:
                        store.currentJobID(
                            at: reference
                        )
                )
                throw error
            }

            store.updateTask(
                at: reference,
                persist: false
            ) { task in
                task.phase = .previewReady
                task.progress = BatchTaskProgress(
                    currentUnit:
                        requiresExtendedPreviewPreparation ? 4 : 3,
                    totalUnits:
                        totalProgressUnits,
                    statusMessage:
                        "已生成模板内容"
                )
            }

            store.updateTask(
                at: reference
            ) { task in
                task.phase = .exporting
                task.progress = BatchTaskProgress(
                    currentUnit:
                        requiresExtendedPreviewPreparation ? 5 : 4,
                    totalUnits:
                        totalProgressUnits,
                    statusMessage:
                        "正在生成图片"
                )
            }

            let exportedFileURL =
                try await diagnosticsRecorder.measureStageDuration(
                    "export",
                    route: route,
                    task: task,
                    jobID:
                        store.currentJobID(
                            at: reference
                        )
                ) {
                    try requireValue(
                        await ExportRecordCardIntent(
                            photo: importedPhoto,
                            card: card,
                            coordinator:
                                exportCoordinator
                        )
                        .execute()
                    )
                }

            temporaryFileURL =
                exportedFileURL

            guard !BatchTaskFailurePolicy.shouldAbortFurtherProcessing(
                currentPhase:
                    store.currentTaskPhase(
                        at: reference
                    )
            ) else {
                resourceLifecycle.cleanupTemporaryFile(
                    at: exportedFileURL
                )
                return
            }

            store.updateTask(
                at: reference
            ) { task in
                task.renderedFileURL =
                    exportedFileURL
                task.phase = .savingToPhotoLibrary
                task.progress = BatchTaskProgress(
                    currentUnit:
                        requiresExtendedPreviewPreparation ? 6 : 5,
                    totalUnits:
                        totalProgressUnits,
                    statusMessage:
                        "正在写入系统图库"
                )
            }

            guard !BatchTaskFailurePolicy.shouldAbortFurtherProcessing(
                currentPhase:
                    store.currentTaskPhase(
                        at: reference
                    )
            ) else {
                resourceLifecycle.cleanupTemporaryFile(
                    at: exportedFileURL
                )
                return
            }

            let saveResult =
                try await diagnosticsRecorder.measureStageDuration(
                    "save",
                    route: route,
                    task: task,
                    jobID:
                        store.currentJobID(
                            at: reference
                        )
                ) {
                    try await requireValue(
                        SaveRenderedPhotoIntent(
                            fileURL:
                                exportedFileURL,
                            metadata:
                                importedPhoto.metadata,
                            preferredAlbumIdentifier:
                                configuration
                                .selectedAlbumIdentifier,
                            coordinator:
                                exportCoordinator
                        )
                        .execute()
                    )
                }

            let notificationAttachmentURL =
                diagnosticsRecorder.measureNotificationAttachmentStage(
                    route: route,
                    task: task,
                    jobID:
                        store.currentJobID(
                            at: reference
                        )
                ) {
                    resourceLifecycle.makeNotificationAttachmentIfNeeded(
                        from: exportedFileURL,
                        taskID: task.id
                    )
                }

            resourceLifecycle.cleanupTemporaryFile(
                at: exportedFileURL
            )

            store.updateTask(
                at: reference
            ) { task in
                task.renderedFileURL = nil
                task.savedAlbumName =
                    saveResult.albumTitle
                task.savedAssetIdentifier =
                    saveResult.assetLocalIdentifier
                task.notificationAttachmentURL =
                    notificationAttachmentURL
                task.phase = .completed
                task.progress = BatchTaskProgress(
                    currentUnit:
                        totalProgressUnits,
                    totalUnits:
                        totalProgressUnits,
                    statusMessage: "处理完成"
                )
            }
            diagnosticsRecorder.recordTaskDuration(
                startedAt: startedAt,
                route: route,
                phase: .completed,
                task: task,
                jobID: store.currentJobID(
                    at: reference
                )
            )

            resourceLifecycle.cleanupManagedSourceIfNeeded(
                at:
                    store.currentTask(
                        at: reference
                    )?.sourceURL
            )

            if let jobID =
                store.currentJobID(
                    at: reference
                ) {
                await store
                    .deliverFinalNotificationIfNeeded(
                        for: jobID
                    )
            }

        } catch {

            if BatchTaskFailurePolicy.shouldIgnoreErrorBecauseTaskEnded(
                currentPhase:
                    store.currentTaskPhase(
                        at: reference
                    )
            ) {
                resourceLifecycle.cleanupTemporaryFile(
                    at: temporaryFileURL
                )

                if let jobID =
                    store.currentJobID(
                        at: reference
                    ) {
                    await store
                        .deliverFinalNotificationIfNeeded(
                            for: jobID
                        )
                }
                return
            }

            let failurePhase =
                store.currentTaskPhase(
                    at: reference
                ) ?? .queued

            resourceLifecycle.cleanupTemporaryFile(
                at: temporaryFileURL
            )

            store.updateTask(
                at: reference
            ) { task in
                let canRetry =
                    BatchTaskFailurePolicy.canRetryTaskAfterFailure(
                        sourceURL: task.sourceURL
                    )

                task.renderedFileURL = nil
                task.notificationAttachmentURL = nil
                task.phase = .failed
                task.failure = BatchTaskFailure(
                    phase: failurePhase,
                    message:
                        (error as? LocalizedError)?
                        .errorDescription
                        ?? error.localizedDescription,
                    classification:
                        BatchTaskFailurePolicy.failureClassification(
                            for: error
                        ),
                    canRetry: canRetry
                )
                task.progress = BatchTaskProgress(
                    currentUnit: 0,
                    totalUnits: 1,
                    statusMessage: "处理失败"
                )
            }

            if let sourceURL =
                store.currentTask(
                    at: reference
                )?.sourceURL,
               !resourceLifecycle.canPreserveManagedSourceForRetry(
                    at: sourceURL
               ) {
                store.updateTask(
                    at: reference
                ) { task in
                    task.failure?.canRetry = false
                }
            }

            store.setLastErrorMessage(
                (error as? LocalizedError)?
                .errorDescription
                ?? error.localizedDescription
            )
            diagnosticsRecorder.recordTaskDuration(
                startedAt: startedAt,
                route: route,
                phase: .failed,
                task: initialTask,
                jobID: store.currentJobID(
                    at: reference
                )
            )

            if let jobID =
                store.currentJobID(
                    at: reference
                ) {
                await store
                    .deliverFinalNotificationIfNeeded(
                        for: jobID
                    )
            }
        }
    }

    func nextPendingTaskReference(
        in jobs: [BatchJob]
    ) -> TaskReference? {

        for jobIndex in jobs.indices {
            let job = jobs[jobIndex]

            for taskIndex in job.tasks.indices {
                if job.tasks[taskIndex].phase
                    == .queued {
                    return TaskReference(
                        jobIndex: jobIndex,
                        taskIndex: taskIndex
                    )
                }
            }
        }

        return nil
    }

    func derivedJobState(
        from tasks: [BatchTask]
    ) -> BatchJobState {

        guard !tasks.isEmpty else {
            return .draft
        }

        if tasks.allSatisfy({
            $0.phase == .completed
        }) {
            return .completed
        }

        if tasks.allSatisfy({
            $0.phase == .cancelled
        }) {
            return .cancelled
        }

        if tasks.contains(where: {
            $0.phase == .savingToPhotoLibrary
            || $0.phase == .exporting
        }) {
            return .running
        }

        if tasks.contains(where: {
            $0.phase == .previewReady
            || $0.phase == .waitingForExport
            || $0.phase == .metadataReady
        }) {
            return .ready
        }

        if tasks.contains(where: {
            $0.phase == .importing
        }) {
            return .preparing
        }

        if tasks.contains(where: {
            $0.phase == .queued
        }) {
            return .queued
        }

        if tasks.contains(where: {
            $0.phase == .failed
        }) {
            return .failed
        }

        return .draft
    }
}

extension BatchQueueExecution {

    func mediaMemoryBudget(
        for task: BatchTask
    ) -> MediaMemoryBudget {

        BatchTaskMemoryPolicy.mediaMemoryBudget(
            for: task
        )
    }
}

private extension BatchQueueExecution {

    struct IntentExecutionError:
        LocalizedError {

        let error:
            PhotoMemoError

        var errorDescription: String? {
            error.message
        }
    }

    func requireValue<Value>(
        _ result: PhotoMemoResult<Value>
    ) throws -> Value {

        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw IntentExecutionError(
                error: error
            )
        }
    }

    func processLivePhotoTask(
        task: BatchTask,
        at reference: TaskReference,
        in store: BatchQueueStore,
        totalProgressUnits: Int
    ) async throws {

        guard let configuration =
            store.currentJob(
                at: reference
            )?.configuration else {
            return
        }

        store.updateTask(
            at: reference
        ) { task in
            task.phase = .exporting
            task.progress = BatchTaskProgress(
                currentUnit:
                    max(totalProgressUnits - 1, 1),
                totalUnits:
                    totalProgressUnits,
                statusMessage:
                    configuration
                    .v1MediaOutputMode
                    == .originalFormat
                    ? "正在生成 Live Photo"
                    : "正在生成静态图片"
            )
        }

        let result =
            try await livePhotoProcessor
            .process(
                task: task,
                configuration:
                    configuration
            )

        guard !BatchTaskFailurePolicy.shouldAbortFurtherProcessing(
            currentPhase:
                store.currentTaskPhase(
                    at: reference
                )
        ) else {
            resourceLifecycle.cleanupTemporaryFiles(
                result.temporaryFileURLs
            )
            return
        }

        let notificationAttachmentURL =
            result.notificationSourceURL
            .flatMap {
                resourceLifecycle.makeNotificationAttachmentIfNeeded(
                    from: $0,
                    taskID: task.id
                )
            }

        resourceLifecycle.cleanupTemporaryFiles(
            result.temporaryFileURLs
        )

        store.updateTask(
            at: reference
        ) { task in
            task.renderedFileURL = nil
            task.savedAlbumName =
                result.saveResult.albumTitle
            task.savedAssetIdentifier =
                result.saveResult
                .assetLocalIdentifier
            task.notificationAttachmentURL =
                notificationAttachmentURL
            task.phase = .completed
            task.progress = BatchTaskProgress(
                currentUnit:
                    totalProgressUnits,
                totalUnits:
                    totalProgressUnits,
                statusMessage: "处理完成"
            )
        }

        resourceLifecycle.cleanupManagedSourceIfNeeded(
            at:
                store.currentTask(
                    at: reference
                )?.sourceURL
        )

        if let jobID =
            store.currentJobID(
                at: reference
            ) {
            await store
                .deliverFinalNotificationIfNeeded(
                    for: jobID
                )
        }
    }

    func initialPreparationStatusMessage(
        for budget: MediaMemoryBudget
    ) -> String {

        if budget.cost.isRAW {
            return "正在准备 RAW 照片"
        }

        if budget.requiresExtendedPreviewPreparation {
            return "正在准备高分辨率照片"
        }

        return "正在读取原图"
    }

    func completedPreparationStatusMessage(
        for budget: MediaMemoryBudget
    ) -> String {

        if budget.cost.isRAW {
            return "已生成 RAW 显示版本"
        }

        if budget.requiresExtendedPreviewPreparation {
            return "已生成高分辨率预览版本"
        }

        return "已读取 EXIF 和拍摄时间"
    }

    func resolvedJobTitle(
        customTitle: String?,
        taskCount: Int,
        startedAt: Date
    ) -> String {

        let trimmedTitle =
            customTitle?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        if !trimmedTitle.isEmpty {
            return trimmedTitle
        }

        return PhotoMemoQueueDisplayFormatter.title(
            startedAt:
                startedAt,
            photoCount:
                taskCount
        )
    }
}
#endif
