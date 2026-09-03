#if !MEMOMARK_SHARE_EXTENSION
import Foundation

nonisolated enum BatchTaskProcessingRoute: String {
    case livePhoto
    case staticImage

    var usesLivePhotoProcessing: Bool {
        self == .livePhoto
    }
}

/// Immutable inputs captured before a task enters the production executor.
/// The context carries no UI state and therefore must remain usable from an
/// actor or detached media worker as the execution pipeline is decomposed.
nonisolated struct BatchTaskExecutionContext {
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
    private let buildRecordCard:
        BuildRecordCardTransaction
    private let exportCoordinator: ExportCoordinator
    private let livePhotoProcessor: any LivePhotoBatchTaskProcessing
    private let diagnosticsRecorder: BatchTaskDiagnosticsRecorder
    private let resourceLifecycle: BatchTaskResourceLifecycle
    private let renderHealthValidator:
        @MainActor (RecordCard, BatchConfigurationSnapshot) async throws -> [CardTextBlock]

    init(
        photoRepository: PhotoRepository,
        buildRecordCard:
            BuildRecordCardTransaction,
        exportCoordinator: ExportCoordinator,
        livePhotoProcessor: any LivePhotoBatchTaskProcessing,
        diagnosticsRecorder: BatchTaskDiagnosticsRecorder,
        resourceLifecycle: BatchTaskResourceLifecycle,
        renderHealthValidator: @escaping
            @MainActor (RecordCard, BatchConfigurationSnapshot) async throws -> [CardTextBlock]
    ) {
        self.photoRepository = photoRepository
        self.buildRecordCard = buildRecordCard
        self.exportCoordinator = exportCoordinator
        self.livePhotoProcessor = livePhotoProcessor
        self.diagnosticsRecorder = diagnosticsRecorder
        self.resourceLifecycle = resourceLifecycle
        self.renderHealthValidator = renderHealthValidator
    }

    func process(
        context: BatchTaskExecutionContext,
        runtime: any BatchTaskExecutionRuntime
    ) async {
        await processTaskInternal(
            context: context,
            runtime: runtime
        )
    }

    private func processTaskInternal(
        context: BatchTaskExecutionContext,
        runtime: any BatchTaskExecutionRuntime
    ) async {
        let reference = context.taskReference
        let initialTask = context.taskSnapshot
        let memoryBudget = context.memoryBudget
        let requiresExtendedPreviewPreparation = memoryBudget.requiresExtendedPreviewPreparation
        let totalProgressUnits = context.totalProgressUnits
        let usesLivePhotoProcessing = context.route.usesLivePhotoProcessing
        let startedAt = context.startedAt
        let route = context.route.rawValue

        await runtime.activate(reference)
        guard await runtime.accept(
            .processingStarted(
                progress: BatchTaskProgress(
                    currentUnit: 1,
                    totalUnits: totalProgressUnits,
                    stage: initialPreparationStage(
                        for: memoryBudget
                    )
                )
            ),
            at: reference
        ) else {
            return
        }

        var temporaryFileURL: URL?
        var jobID: UUID?
        do {
            guard let executionState =
                await runtime.executionState(
                    at: reference
                ) else {
                throw BatchTaskProcessorError.taskUnavailable
            }
            let task = executionState.task
            jobID = executionState.jobID
            diagnosticsRecorder.recordRoute(
                for: task,
                sourceURLIsLivePhotoBundle: LivePhotoSourceBundleLocator.canResolveBundle(at: task.sourceURL),
                route: route,
                jobID: jobID
            )

            if BatchTaskMemoryPolicy
                .shouldRejectUnavailableLivePhotoSource(
                    for: task
                ) {
                throw MemoMarkError(
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
                    jobID: jobID
                ) {
                    try await processLivePhotoTask(
                        task: task,
                        at: reference,
                        runtime: runtime,
                        totalProgressUnits: totalProgressUnits,
                        configuration: context.configuration
                    )
                }
                if let phase = await currentPhase(
                    at: reference,
                    runtime: runtime
                ),
                phase.isTerminal {
                    diagnosticsRecorder.recordTaskDuration(
                        startedAt: startedAt,
                        route: route,
                        phase: phase,
                        task: task,
                        jobID: jobID
                    )
                }
                return
            }

            let importedPhoto = try await diagnosticsRecorder.measureStageDuration(
                "import",
                route: route,
                task: task,
                jobID: jobID
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
                currentPhase: await currentPhase(
                    at: reference,
                    runtime: runtime
                )
            ) else {
                await runtime.cleanupDurablyTerminalSource(
                    at: reference
                )
                return
            }

            _ = await runtime.accept(
                .metadataLoaded(
                    captureDate:
                        importedPhoto.metadata.captureDate,
                    progress: BatchTaskProgress(
                        currentUnit:
                            requiresExtendedPreviewPreparation
                            ? 3
                            : 2,
                        totalUnits: totalProgressUnits,
                        stage: completedPreparationStage(
                            for: memoryBudget
                        )
                    )
                ),
                at: reference
            )

            let configuration = context.configuration
            let card = try await diagnosticsRecorder.measureStageDuration(
                "build",
                route: route,
                task: task,
                jobID: jobID
            ) {
                try requireValue(
                    await buildRecordCard.buildCardOffMainThread(
                        from: importedPhoto,
                        configuration: configuration
                    )
                )
            }

            do {
                _ = try await renderHealthValidator(
                    card,
                    configuration
                )
                diagnosticsRecorder.recordRenderHealthCheckPassed(
                    task: task,
                    launchSource:
                        executionState.launchSource,
                    configuration: configuration,
                    jobID: jobID
                )
            } catch {
                diagnosticsRecorder.recordRenderHealthCheckFailed(
                    task: task,
                    configuration: configuration,
                    error: error,
                    jobID: jobID
                )
                throw error
            }

            guard !BatchTaskFailurePolicy.shouldAbortFurtherProcessing(
                currentPhase: await currentPhase(
                    at: reference,
                    runtime: runtime
                )
            ) else {
                await runtime.cleanupDurablyTerminalSource(
                    at: reference
                )
                return
            }

            _ = await runtime.accept(
                .previewBuilt(
                    progress: BatchTaskProgress(
                        currentUnit:
                            requiresExtendedPreviewPreparation
                            ? 4
                            : 3,
                        totalUnits: totalProgressUnits,
                        stage: .presentationReady
                    )
                ),
                at: reference
            )
            guard await runtime.accept(
                .exportStarted(
                    progress: BatchTaskProgress(
                        currentUnit:
                            requiresExtendedPreviewPreparation
                            ? 5
                            : 4,
                        totalUnits: totalProgressUnits,
                        stage: .renderingImage
                    )
                ),
                at: reference
            ) else {
                return
            }

            let exportedFileURL = try await diagnosticsRecorder.measureStageDuration(
                "export",
                route: route,
                task: task,
                jobID: jobID
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
                currentPhase: await currentPhase(
                    at: reference,
                    runtime: runtime
                )
            ) else {
                resourceLifecycle.cleanupTemporaryFile(at: exportedFileURL)
                await runtime.cleanupDurablyTerminalSource(
                    at: reference
                )
                return
            }

            guard await runtime.accept(
                .photoLibrarySaveStarted(
                    renderedFileURL: exportedFileURL,
                    progress: BatchTaskProgress(
                        currentUnit:
                            requiresExtendedPreviewPreparation
                            ? 6
                            : 5,
                        totalUnits: totalProgressUnits,
                        stage: .savingToPhotoLibrary
                    )
                ),
                at: reference
            ) else {
                resourceLifecycle.cleanupTemporaryFile(at: exportedFileURL)
                return
            }

            guard !BatchTaskFailurePolicy.shouldAbortFurtherProcessing(
                currentPhase: await currentPhase(
                    at: reference,
                    runtime: runtime
                )
            ) else {
                resourceLifecycle.cleanupTemporaryFile(at: exportedFileURL)
                return
            }

            let saveResult = try await diagnosticsRecorder.measureStageDuration(
                "save",
                route: route,
                task: task,
                jobID: jobID
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
            let notificationAttachmentURL = await diagnosticsRecorder.measureNotificationAttachmentStage(
                route: route,
                task: task,
                jobID: jobID
            ) {
                await resourceLifecycle.makeNotificationAttachmentOffMainThreadIfNeeded(
                    from: exportedFileURL,
                    taskID: task.id
                )
            }
            let hasHistoryCover =
                await runtime.executionState(
                    at: reference
                )?
                .hasHistoryCover
                ?? true
            let historyCoverCandidate = !hasHistoryCover
                ? await resourceLifecycle.makeHistoryCoverIfNeeded(
                    from: exportedFileURL,
                    jobID: reference.jobID,
                    sourceTaskID: task.id
                )
                : nil
            resourceLifecycle.cleanupTemporaryFile(at: exportedFileURL)
            guard await runtime.accept(
                .completed(
                    albumTitle: saveResult.albumTitle,
                    assetIdentifier:
                        saveResult.assetLocalIdentifier,
                    notificationAttachmentURL:
                        notificationAttachmentURL,
                    progress: BatchTaskProgress(
                        currentUnit: totalProgressUnits,
                        totalUnits: totalProgressUnits,
                        stage: .completed
                    )
                ),
                at: reference,
                historyCoverCandidate:
                    historyCoverCandidate
            ) else {
                return
            }
            diagnosticsRecorder.recordTaskDuration(
                startedAt: startedAt,
                route: route,
                phase: .completed,
                task: task,
                jobID: jobID
            )
            await runtime.cleanupDurablyTerminalSource(
                at: reference
            )
            await runtime.deliverFinalNotification(
                for: reference.jobID
            )
        } catch {
            // A cancellation may race with an explicit terminal transition
            // (user cancellation or a system background-expiration guard).
            // Resolve that durable state first so cleanup/notification logic
            // is not bypassed by the generic CancellationError branch.
            if BatchTaskFailurePolicy.shouldIgnoreErrorBecauseTaskEnded(
                currentPhase: await currentPhase(
                    at: reference,
                    runtime: runtime
                )
            ) {
                resourceLifecycle.cleanupTemporaryFile(at: temporaryFileURL)
                await runtime.cleanupDurablyTerminalSource(
                    at: reference
                )
                if let jobID {
                    await runtime.deliverFinalNotification(
                        for: jobID
                    )
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
                    await runtime.stopForCancellation()
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
                guard await runtime.accept(
                    .photoLibraryReadbackPending,
                    at: reference
                ) else {
                    return
                }
                return
            }

            let failurePhase = await currentPhase(
                at: reference,
                runtime: runtime
            ) ?? .queued
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
            let failure =
                BatchTaskFailure(
                    phase: failurePhase,
                    message: diagnosticFailure.userMessage,
                    classification: failureClassification,
                    canRetry:
                        BatchTaskFailurePolicy
                        .canRetryTaskAfterFailure(
                            sourceURL:
                                initialTask.sourceURL
                        ),
                    diagnosticCode:
                        diagnosticFailure.code.rawValue,
                    supportID:
                        diagnosticFailure.supportID
                )
            guard await runtime.accept(
                .failed(failure),
                at: reference
            ) else {
                return
            }
            if !resourceLifecycle
                .canPreserveManagedSourceForRetry(
                    at: initialTask.sourceURL
                ) {
                guard await runtime.accept(
                    .retryDisabled,
                    at: reference
                ) else {
                    return
                }
            }
            await runtime.publishLastError(
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
                await runtime.deliverFinalNotification(
                    for: jobID
                )
            }
        }
    }

    private func processLivePhotoTask(
        task: BatchTask,
        at reference: BatchQueueExecution.TaskReference,
        runtime: any BatchTaskExecutionRuntime,
        totalProgressUnits: Int,
        configuration: BatchConfigurationSnapshot
    ) async throws {
        guard await runtime.accept(
            .exportStarted(
                progress: BatchTaskProgress(
                    currentUnit:
                        max(
                            totalProgressUnits - 1,
                            1
                        ),
                    totalUnits: totalProgressUnits,
                    stage:
                        configuration.mediaOutputMode
                        == .originalFormat
                        ? .renderingLivePhoto
                        : .renderingStillImage
                )
            ),
            at: reference
        ) else {
            return
        }
        let result = try await livePhotoProcessor.process(
            task: task,
            configuration: configuration
        )
        guard !BatchTaskFailurePolicy.shouldAbortFurtherProcessing(
            currentPhase: await currentPhase(
                at: reference,
                runtime: runtime
            )
        ) else {
            resourceLifecycle.cleanupTemporaryFiles(result.temporaryFileURLs)
            await runtime.cleanupDurablyTerminalSource(
                at: reference
            )
            return
        }
        let notificationAttachmentURL: URL?
        if let notificationSourceURL = result.notificationSourceURL {
            notificationAttachmentURL =
                await resourceLifecycle
                .makeNotificationAttachmentOffMainThreadIfNeeded(
                    from: notificationSourceURL,
                    taskID: task.id
                )
        } else {
            notificationAttachmentURL = nil
        }
        let historyCoverCandidate: BatchJobHistoryCover?
        let hasHistoryCover =
            await runtime.executionState(
                at: reference
            )?
            .hasHistoryCover
            ?? true
        if let sourceURL = result.notificationSourceURL,
           !hasHistoryCover {
            historyCoverCandidate = await resourceLifecycle.makeHistoryCoverIfNeeded(
                from: sourceURL,
                jobID: reference.jobID,
                sourceTaskID: task.id
            )
        } else {
            historyCoverCandidate = nil
        }
        resourceLifecycle.cleanupTemporaryFiles(result.temporaryFileURLs)
        guard await runtime.accept(
            .completed(
                albumTitle:
                    result.saveResult.albumTitle,
                assetIdentifier:
                    result.saveResult
                    .assetLocalIdentifier,
                notificationAttachmentURL:
                    notificationAttachmentURL,
                progress: BatchTaskProgress(
                    currentUnit: totalProgressUnits,
                    totalUnits: totalProgressUnits,
                    stage: .completed
                )
            ),
            at: reference,
            historyCoverCandidate:
                historyCoverCandidate
        ) else {
            return
        }
        await runtime.cleanupDurablyTerminalSource(
            at: reference
        )
        await runtime.deliverFinalNotification(
            for: reference.jobID
        )
    }

    private func currentPhase(
        at reference: BatchTaskReference,
        runtime: any BatchTaskExecutionRuntime
    ) async -> BatchTaskPhase? {
        await runtime.executionState(
            at: reference
        )?
        .task
        .phase
    }

    private func requireValue<Value>(_ result: MemoMarkResult<Value>) throws -> Value {
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    private func initialPreparationStage(
        for budget: MediaMemoryBudget
    ) -> BatchTaskProgressStage {
        if budget.cost.isRAW {
            return .preparingRAWPhoto
        }
        if budget.requiresExtendedPreviewPreparation {
            return .preparingHighResolutionPhoto
        }
        return .readingOriginal
    }

    private func completedPreparationStage(
        for budget: MediaMemoryBudget
    ) -> BatchTaskProgressStage {
        if budget.cost.isRAW {
            return .preparedRAWRepresentation
        }
        if budget.requiresExtendedPreviewPreparation {
            return .preparedHighResolutionPreview
        }
        return .metadataReady
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
