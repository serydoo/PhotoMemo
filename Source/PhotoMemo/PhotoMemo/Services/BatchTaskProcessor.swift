#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum BatchTaskProcessingRoute: String {
    case livePhoto
    case staticImage

    var usesLivePhotoProcessing: Bool {
        self == .livePhoto
    }
}

@MainActor
struct BatchTaskExecutionContext {
    let taskReference: BatchQueueExecution.TaskReference
    let taskSnapshot: BatchTask
    let configuration: BatchConfigurationSnapshot
    let memoryBudget: MediaMemoryBudget
    let route: BatchTaskProcessingRoute
    let totalProgressUnits: Int
    let startedAt: Date
}

@MainActor
final class BatchTaskProcessor {
    private let photoRepository: PhotoRepository
    private let previewCoordinator: PreviewCoordinator
    private let exportCoordinator: ExportCoordinator
    private let livePhotoProcessor: any LivePhotoBatchTaskProcessing
    private let diagnosticsRecorder: BatchTaskDiagnosticsRecorder
    private let resourceLifecycle: BatchTaskResourceLifecycle
    private let renderHealthValidator:
        @MainActor (RecordCard, BatchConfigurationSnapshot) throws -> [CardTextBlock]

    init(
        photoRepository: PhotoRepository,
        previewCoordinator: PreviewCoordinator,
        exportCoordinator: ExportCoordinator,
        livePhotoProcessor: any LivePhotoBatchTaskProcessing,
        diagnosticsRecorder: BatchTaskDiagnosticsRecorder,
        resourceLifecycle: BatchTaskResourceLifecycle,
        renderHealthValidator: @escaping
            @MainActor (RecordCard, BatchConfigurationSnapshot) throws -> [CardTextBlock]
    ) {
        self.photoRepository = photoRepository
        self.previewCoordinator = previewCoordinator
        self.exportCoordinator = exportCoordinator
        self.livePhotoProcessor = livePhotoProcessor
        self.diagnosticsRecorder = diagnosticsRecorder
        self.resourceLifecycle = resourceLifecycle
        self.renderHealthValidator = renderHealthValidator
    }

    func process(context: BatchTaskExecutionContext, in store: BatchQueueStore) async {
        await processTaskInternal(context: context, in: store)
    }

    private func processTaskInternal(
        context: BatchTaskExecutionContext,
        in store: BatchQueueStore
    ) async {
        let reference = context.taskReference
        let initialTask = context.taskSnapshot
        let memoryBudget = context.memoryBudget
        let requiresExtendedPreviewPreparation = memoryBudget.requiresExtendedPreviewPreparation
        let totalProgressUnits = context.totalProgressUnits
        let usesLivePhotoProcessing = context.route.usesLivePhotoProcessing
        let startedAt = context.startedAt
        let route = context.route.rawValue

        store.setActiveProcessingReference(reference)
        store.updateTask(at: reference) { task in
            task.phase = .importing
            task.progress = BatchTaskProgress(
                currentUnit: 1,
                totalUnits: totalProgressUnits,
                statusMessage: initialPreparationStatusMessage(for: memoryBudget)
            )
            task.failure = nil
        }

        var temporaryFileURL: URL?
        do {
            guard let task = store.currentTask(at: reference) else {
                throw BatchTaskProcessorError.taskUnavailable
            }
            diagnosticsRecorder.recordRoute(
                for: task,
                sourceURLIsLivePhotoBundle: LivePhotoSourceBundleLocator.canResolveBundle(at: task.sourceURL),
                route: route,
                jobID: store.currentJob(at: reference)?.id
            )

            if BatchTaskMemoryPolicy
                .shouldRejectUnavailableLivePhotoSource(
                    for: task
                ) {
                throw PhotoMemoError(
                    code: .importFailed,
                    message:
                        "The source did not provide the paired Live Photo resources.",
                    diagnosticCode:
                        PhotoProcessingInputPolicy
                        .RejectionReason
                        .livePhoto
                        .rawValue
                )
            }

            if usesLivePhotoProcessing {
                try await diagnosticsRecorder.measureStageDuration(
                    "livePhotoProcessing",
                    route: route,
                    task: task,
                    jobID: store.currentJobID(at: reference)
                ) {
                    try await processLivePhotoTask(
                        task: task,
                        at: reference,
                        in: store,
                        totalProgressUnits: totalProgressUnits,
                        configuration: context.configuration
                    )
                }
                if let phase = store.currentTaskPhase(at: reference), phase.isTerminal {
                    diagnosticsRecorder.recordTaskDuration(
                        startedAt: startedAt,
                        route: route,
                        phase: phase,
                        task: task,
                        jobID: store.currentJobID(at: reference)
                    )
                }
                return
            }

            let importedPhoto = try await diagnosticsRecorder.measureStageDuration(
                "import",
                route: route,
                task: task,
                jobID: store.currentJobID(at: reference)
            ) {
                try await requireValue(
                    ImportBatchPhotoIntent(
                        task: task,
                        contentTypeIdentifierOverride: BatchTaskMemoryPolicy.staticImportContentTypeIdentifier(
                            for: task,
                            usesLivePhotoProcessing: usesLivePhotoProcessing
                        ),
                        repository: photoRepository
                    ).execute()
                )
            }

            guard !BatchTaskFailurePolicy.shouldAbortFurtherProcessing(
                currentPhase: store.currentTaskPhase(at: reference)
            ) else {
                store.cleanupManagedSourceForDurablyTerminalTask(
                    at: reference
                )
                return
            }

            store.updateTask(at: reference, persist: false) { task in
                task.captureDate = importedPhoto.metadata.captureDate
                task.phase = .metadataReady
                task.progress = BatchTaskProgress(
                    currentUnit: requiresExtendedPreviewPreparation ? 3 : 2,
                    totalUnits: totalProgressUnits,
                    statusMessage: completedPreparationStatusMessage(for: memoryBudget)
                )
            }

            let configuration = context.configuration
            let card = try await diagnosticsRecorder.measureStageDuration(
                "build",
                route: route,
                task: task,
                jobID: store.currentJobID(at: reference)
            ) {
                try requireValue(
                    await BuildPreviewIntent(
                        photo: importedPhoto,
                        configuration: configuration,
                        coordinator: previewCoordinator
                    ).execute()
                )
            }

            do {
                _ = try renderHealthValidator(card, configuration)
                diagnosticsRecorder.recordRenderHealthCheckPassed(
                    task: task,
                    launchSource: store.currentJob(at: reference)?.launchSource,
                    configuration: configuration,
                    jobID: store.currentJobID(at: reference)
                )
            } catch {
                diagnosticsRecorder.recordRenderHealthCheckFailed(
                    task: task,
                    configuration: configuration,
                    error: error,
                    jobID: store.currentJobID(at: reference)
                )
                throw error
            }

            guard !BatchTaskFailurePolicy.shouldAbortFurtherProcessing(
                currentPhase:
                    store.currentTaskPhase(
                        at: reference
                    )
            ) else {
                store.cleanupManagedSourceForDurablyTerminalTask(
                    at: reference
                )
                return
            }

            store.updateTask(at: reference, persist: false) { task in
                task.phase = .previewReady
                task.progress = BatchTaskProgress(
                    currentUnit: requiresExtendedPreviewPreparation ? 4 : 3,
                    totalUnits: totalProgressUnits,
                    statusMessage: "已生成模板内容"
                )
            }
            store.updateTask(at: reference) { task in
                task.phase = .exporting
                task.progress = BatchTaskProgress(
                    currentUnit: requiresExtendedPreviewPreparation ? 5 : 4,
                    totalUnits: totalProgressUnits,
                    statusMessage: "正在生成图片"
                )
            }

            let exportedFileURL = try await diagnosticsRecorder.measureStageDuration(
                "export",
                route: route,
                task: task,
                jobID: store.currentJobID(at: reference)
            ) {
                try requireValue(
                    await ExportRecordCardIntent(
                        photo: importedPhoto,
                        card: card,
                        coordinator: exportCoordinator
                    ).execute()
                )
            }
            temporaryFileURL = exportedFileURL

            guard !BatchTaskFailurePolicy.shouldAbortFurtherProcessing(
                currentPhase: store.currentTaskPhase(at: reference)
            ) else {
                resourceLifecycle.cleanupTemporaryFile(at: exportedFileURL)
                store.cleanupManagedSourceForDurablyTerminalTask(
                    at: reference
                )
                return
            }

            store.updateTask(at: reference) { task in
                task.renderedFileURL = exportedFileURL
                task.phase = .savingToPhotoLibrary
                task.progress = BatchTaskProgress(
                    currentUnit: requiresExtendedPreviewPreparation ? 6 : 5,
                    totalUnits: totalProgressUnits,
                    statusMessage: "正在写入系统图库"
                )
            }

            guard !BatchTaskFailurePolicy.shouldAbortFurtherProcessing(
                currentPhase: store.currentTaskPhase(at: reference)
            ) else {
                resourceLifecycle.cleanupTemporaryFile(at: exportedFileURL)
                return
            }

            let saveResult = try await diagnosticsRecorder.measureStageDuration(
                "save",
                route: route,
                task: task,
                jobID: store.currentJobID(at: reference)
            ) {
                try await requireValue(
                    SaveRenderedPhotoIntent(
                        fileURL: exportedFileURL,
                        metadata: importedPhoto.metadata,
                        preferredAlbumIdentifier: configuration.selectedAlbumIdentifier,
                        coordinator: exportCoordinator,
                        idempotencyKey: task.id.uuidString
                    ).execute()
                )
            }
            let notificationAttachmentURL = diagnosticsRecorder.measureNotificationAttachmentStage(
                route: route,
                task: task,
                jobID: store.currentJobID(at: reference)
            ) {
                resourceLifecycle.makeNotificationAttachmentIfNeeded(
                    from: exportedFileURL,
                    taskID: task.id
                )
            }
            let historyCoverCandidate = store.currentJob(at: reference)?.historyCover == nil
                ? await resourceLifecycle.makeHistoryCoverIfNeeded(
                    from: exportedFileURL,
                    jobID: reference.jobID,
                    sourceTaskID: task.id
                )
                : nil
            resourceLifecycle.cleanupTemporaryFile(at: exportedFileURL)
            store.updateTask(
                at: reference,
                historyCoverCandidate: historyCoverCandidate
            ) { task in
                task.renderedFileURL = nil
                task.savedAlbumName = saveResult.albumTitle
                task.savedAssetIdentifier = saveResult.assetLocalIdentifier
                task.notificationAttachmentURL = notificationAttachmentURL
                task.phase = .completed
                task.progress = BatchTaskProgress(
                    currentUnit: totalProgressUnits,
                    totalUnits: totalProgressUnits,
                    statusMessage: "处理完成"
                )
            }
            diagnosticsRecorder.recordTaskDuration(
                startedAt: startedAt,
                route: route,
                phase: .completed,
                task: task,
                jobID: store.currentJobID(at: reference)
            )
            store.cleanupManagedSourceForDurablyTerminalTask(
                at: reference
            )
            if let jobID = store.currentJobID(at: reference) {
                await store.deliverFinalNotificationIfNeeded(for: jobID)
            }
        } catch {
            // A cancellation may race with an explicit terminal transition
            // (user cancellation or a system background-expiration guard).
            // Resolve that durable state first so cleanup/notification logic
            // is not bypassed by the generic CancellationError branch.
            if BatchTaskFailurePolicy.shouldIgnoreErrorBecauseTaskEnded(
                currentPhase: store.currentTaskPhase(at: reference)
            ) {
                resourceLifecycle.cleanupTemporaryFile(at: temporaryFileURL)
                store.cleanupManagedSourceForDurablyTerminalTask(
                    at: reference
                )
                if let jobID = store.currentJobID(at: reference) {
                    await store.deliverFinalNotificationIfNeeded(for: jobID)
                }
                return
            }

            if BatchTaskFailurePolicy.shouldResumeAfterCancellation(
                error: error,
                taskIsCancelled: Task.isCancelled
            ) {
                resourceLifecycle.cleanupTemporaryFile(
                    at: temporaryFileURL
                )
                // A processor can throw CancellationError without the owner
                // Task itself being cancelled. Stop that owner explicitly;
                // otherwise the queue loop immediately selects the same
                // queued task and spins forever.
                if !Task.isCancelled {
                    store.stopProcessingForCancellation()
                }
                return
            }

            if BatchTaskFailurePolicy
                .shouldAwaitPhotoLibraryReadback(
                    error: error
                ) {
                resourceLifecycle.cleanupTemporaryFile(
                    at: temporaryFileURL
                )
                store.updateTask(at: reference) { task in
                    task.renderedFileURL = nil
                    task.notificationAttachmentURL = nil
                    task.failure = nil
                    task.phase = .savingToPhotoLibrary
                    task.progress = BatchTaskProgress(
                        currentUnit:
                            max(task.progress.totalUnits - 1, 0),
                        totalUnits:
                            max(task.progress.totalUnits, 1),
                        statusMessage:
                            "正在确认系统图库写入"
                    )
                }
                return
            }

            let failurePhase = store.currentTaskPhase(at: reference) ?? .queued
            let jobID = store.currentJobID(at: reference)
            let failureClassification =
                BatchTaskFailurePolicy
                .failureClassification(for: error)
            let diagnosticFailure =
                ProductionDiagnosticFailureClassifier
                .processing(
                    phase: failurePhase.rawValue,
                    classification:
                        failureClassification.rawValue,
                    operationID: initialTask.id,
                    error: error,
                    language: .interfaceStored
                )
            resourceLifecycle.cleanupTemporaryFile(at: temporaryFileURL)
            store.updateTask(at: reference) { task in
                let canRetry = BatchTaskFailurePolicy.canRetryTaskAfterFailure(
                    sourceURL: task.sourceURL
                )
                task.renderedFileURL = nil
                task.notificationAttachmentURL = nil
                task.phase = .failed
                task.failure = BatchTaskFailure(
                    phase: failurePhase,
                    message: diagnosticFailure.userMessage,
                    classification: failureClassification,
                    canRetry: canRetry,
                    diagnosticCode:
                        diagnosticFailure.code.rawValue,
                    supportID:
                        diagnosticFailure.supportID
                )
                task.progress = BatchTaskProgress(
                    currentUnit: 0,
                    totalUnits: 1,
                    statusMessage: "处理失败"
                )
            }
            if let sourceURL = store.currentTask(at: reference)?.sourceURL,
               !resourceLifecycle.canPreserveManagedSourceForRetry(at: sourceURL) {
                store.updateTask(at: reference) { task in
                    task.failure?.canRetry = false
                }
            }
            store.setLastErrorMessage(
                diagnosticFailure.userMessage
            )
            diagnosticsRecorder.recordTaskDuration(
                startedAt: startedAt,
                route: route,
                phase: .failed,
                task: initialTask,
                jobID: jobID
            )
            await diagnosticsRecorder.recordTerminalFailure(
                failure: diagnosticFailure,
                phase: failurePhase,
                task: initialTask,
                jobID: jobID,
                startedAt: startedAt
            )
            if let jobID {
                await store.deliverFinalNotificationIfNeeded(for: jobID)
            }
        }
    }

    private func processLivePhotoTask(
        task: BatchTask,
        at reference: BatchQueueExecution.TaskReference,
        in store: BatchQueueStore,
        totalProgressUnits: Int,
        configuration: BatchConfigurationSnapshot
    ) async throws {
        store.updateTask(at: reference) { task in
            task.phase = .exporting
            task.progress = BatchTaskProgress(
                currentUnit: max(totalProgressUnits - 1, 1),
                totalUnits: totalProgressUnits,
                statusMessage: configuration.v1MediaOutputMode == .originalFormat
                    ? "正在生成 Live Photo"
                    : "正在生成静态图片"
            )
        }
        let result = try await livePhotoProcessor.process(
            task: task,
            configuration: configuration
        )
        guard !BatchTaskFailurePolicy.shouldAbortFurtherProcessing(
            currentPhase: store.currentTaskPhase(at: reference)
        ) else {
            resourceLifecycle.cleanupTemporaryFiles(result.temporaryFileURLs)
            store.cleanupManagedSourceForDurablyTerminalTask(
                at: reference
            )
            return
        }
        let notificationAttachmentURL = result.notificationSourceURL.flatMap {
            resourceLifecycle.makeNotificationAttachmentIfNeeded(from: $0, taskID: task.id)
        }
        let historyCoverCandidate: BatchJobHistoryCover?
        if let sourceURL = result.notificationSourceURL,
           store.currentJob(at: reference)?.historyCover == nil {
            historyCoverCandidate = await resourceLifecycle.makeHistoryCoverIfNeeded(
                from: sourceURL,
                jobID: reference.jobID,
                sourceTaskID: task.id
            )
        } else {
            historyCoverCandidate = nil
        }
        resourceLifecycle.cleanupTemporaryFiles(result.temporaryFileURLs)
        store.updateTask(
            at: reference,
            historyCoverCandidate: historyCoverCandidate
        ) { task in
            task.renderedFileURL = nil
            task.savedAlbumName = result.saveResult.albumTitle
            task.savedAssetIdentifier = result.saveResult.assetLocalIdentifier
            task.notificationAttachmentURL = notificationAttachmentURL
            task.phase = .completed
            task.progress = BatchTaskProgress(
                currentUnit: totalProgressUnits,
                totalUnits: totalProgressUnits,
                statusMessage: "处理完成"
            )
        }
        store.cleanupManagedSourceForDurablyTerminalTask(
            at: reference
        )
        if let jobID = store.currentJobID(at: reference) {
            await store.deliverFinalNotificationIfNeeded(for: jobID)
        }
    }

    private func requireValue<Value>(_ result: PhotoMemoResult<Value>) throws -> Value {
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    private func initialPreparationStatusMessage(for budget: MediaMemoryBudget) -> String {
        if budget.cost.isRAW { return "正在准备 RAW 照片" }
        if budget.requiresExtendedPreviewPreparation { return "正在准备高分辨率照片" }
        return "正在读取原图"
    }

    private func completedPreparationStatusMessage(for budget: MediaMemoryBudget) -> String {
        if budget.cost.isRAW { return "已生成 RAW 显示版本" }
        if budget.requiresExtendedPreviewPreparation { return "已生成高分辨率预览版本" }
        return "已读取 EXIF 和拍摄时间"
    }
}

private enum BatchTaskProcessorError: LocalizedError {
    case taskUnavailable

    var errorDescription: String? {
        switch self {
        case .taskUnavailable:
            return "批处理任务已不存在"
        }
    }
}
#endif
