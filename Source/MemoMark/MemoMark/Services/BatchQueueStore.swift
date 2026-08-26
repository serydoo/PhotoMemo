#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Combine

@MainActor
final class BatchQueueStore: ObservableObject {

    @Published private(set) var jobs: [BatchJob] = []

    @Published private(set) var isProcessing = false

    @Published private(set) var activeJobID: UUID?

    @Published private(set) var activeTaskID: UUID?

    @Published private(set) var lastErrorMessage = ""

    @Published private(set) var startupPersistenceError:
        MemoMarkError?

    @Published private(set) var isPersistenceBlocked = false

    @Published private(set) var defaultConfigurationSnapshot:
        BatchConfigurationSnapshot

    @Published private(set) var commerceSnapshot:
        MemoMarkCommerceSnapshot

    private let settingsService:
        SettingsService

    private let automaticallyStartsProcessing:
        Bool

    private let execution:
        BatchQueueExecution

    private let persistence:
        BatchQueuePersistence

    private let history:
        BatchQueueHistory

    private let notifications:
        BatchQueueNotifications

    private let commercePersistence:
        MemoMarkCommercePersistence

    private let saveReceiptStore:
        PhotoLibrarySaveReceiptStore

    private let photoLibraryReceiptAssetLocator:
        any PhotoLibraryReceiptAssetLocating

    private let productionDiagnostics:
        ProductionDiagnosticsRepository?

    private var processingTask:
        Task<Void, Never>?

    private var persistenceBlocked = false

    private var persistenceRecoveryRequiresReload = false

    private var pendingCommerceSnapshot:
        MemoMarkCommerceSnapshot?

    private var pendingSaveReceiptRemovalKeys = Set<String>()

    private var lastDurableJobs: [BatchJob] = []

    private var lastDurableSaveReceiptRemovalKeys = Set<String>()

    init(
        defaults: UserDefaults? = nil,
        settingsService: SettingsService? = nil,
        executionCoordinator:
            BatchProcessingCoordinator? = nil,
        notificationService:
            BatchNotificationService? = nil,
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
        outputFilenameSequenceStore:
            LivePhotoOutputFilenameSequenceStore? = nil,
        persistence: BatchQueuePersistence? = nil,
        saveReceiptStore:
            PhotoLibrarySaveReceiptStore? = nil,
        photoLibraryReceiptAssetLocator:
            (any PhotoLibraryReceiptAssetLocating)? = nil,
        productionDiagnostics:
            ProductionDiagnosticsRepository? = nil,
        automaticallyStartsProcessing: Bool = true,
        renderHealthValidator: @escaping
            @MainActor (RecordCard, BatchConfigurationSnapshot) throws -> [CardTextBlock] =
                ProductionRenderHealthCheck.validate
    ) {
        let resolvedDefaults =
            defaults
            ?? MemoMarkSharedContainer
            .sharedUserDefaults
        let resolvedSettingsService =
            settingsService
            ?? SettingsService()
        let resolvedExternalIntakeStore =
            externalIntakeStore
            ?? .shared

        self.settingsService =
            resolvedSettingsService
        self.automaticallyStartsProcessing =
            automaticallyStartsProcessing
        self.execution =
            BatchQueueExecution(
                coordinator:
                    executionCoordinator
                    ?? BatchProcessingCoordinator(),
                externalIntakeStore:
                    resolvedExternalIntakeStore,
                photoRepository:
                    photoRepository,
                previewCoordinator:
                    previewCoordinator,
                exportCoordinator:
                    exportCoordinator,
                livePhotoProcessor:
                    livePhotoProcessor,
                outputFilenameSequenceStore:
                    outputFilenameSequenceStore,
                diagnosticsDefaults:
                    resolvedDefaults,
                productionDiagnostics:
                    productionDiagnostics,
                renderHealthValidator:
                    renderHealthValidator
            )
        self.persistence =
            persistence
            ?? BatchQueuePersistence(
                defaults: resolvedDefaults
            )
        self.history =
            BatchQueueHistory(
                externalIntakeStore:
                    resolvedExternalIntakeStore
            )
        self.notifications =
            BatchQueueNotifications(
                notificationService:
                    notificationService
            )
        self.commercePersistence =
            MemoMarkCommercePersistence(
                defaults: resolvedDefaults
            )
        let resolvedSaveReceiptStore =
            saveReceiptStore
            ?? PhotoLibrarySaveReceiptStore(
                defaults: resolvedDefaults
            )
        self.saveReceiptStore = resolvedSaveReceiptStore
        self.photoLibraryReceiptAssetLocator =
            photoLibraryReceiptAssetLocator
            ?? PhotoLibrarySaveReceiptAssetLocator(
                receiptStore: resolvedSaveReceiptStore
            )
        self.productionDiagnostics =
            productionDiagnostics
        self.commerceSnapshot =
            self.commercePersistence
            .loadSharedSnapshot(
                compatibleWith:
                    .currentRuntime
            )
        self.defaultConfigurationSnapshot =
            resolvedSettingsService
            .buildBatchConfigurationSnapshot()

        self.startupPersistenceError = nil
        self.isPersistenceBlocked = false

        switch self.persistence.loadPersistedJobsResult() {
        case .success(let loadedJobs):
            jobs = loadedJobs
            lastDurableJobs = loadedJobs
        case .failure(let error):
            jobs = []
            lastDurableJobs = []
            startupPersistenceError = error
            lastErrorMessage = error.message
            persistenceBlocked = true
            isPersistenceBlocked = true
            persistenceRecoveryRequiresReload = true
        }

        guard !persistenceBlocked else {
            return
        }

        reconcileCommittedPhotoLibraryReceiptsForResume()
        guard !persistenceBlocked else {
            return
        }
        normalizeJobsForResume()
        guard !persistenceBlocked else {
            return
        }
        reconcileSaveReceiptsWithPersistedJobs()
        guard !persistenceBlocked else {
            return
        }
        reconcileCommerceUsageWithDurableJobs()
        guard !persistenceBlocked else {
            return
        }
        if self.automaticallyStartsProcessing {
            startProcessingIfNeeded()
        }
    }

    // MARK: - Public API

    func updateDefaultConfiguration(
        _ snapshot: BatchConfigurationSnapshot
    ) {

        defaultConfigurationSnapshot = snapshot
    }

    func enqueue(
        urls: [URL],
        launchSource: BatchJobLaunchSource = .inAppPreview,
        title: String? = nil
    ) -> BatchJob? {

        let payloads = urls.map {
            BatchTaskIntakePayload(
                sourceURL: $0
            )
        }

        return enqueue(
            payloads: payloads,
            configuration:
                defaultConfigurationSnapshot,
            launchSource: launchSource,
            title: title
        )
    }

    func enqueue(
        payloads: [BatchTaskIntakePayload],
        configuration: BatchConfigurationSnapshot,
        launchSource: BatchJobLaunchSource,
        intakeSummary:
            ExternalPhotoImportSummary? = nil,
        intakeRequestID: UUID? = nil,
        title: String? = nil
    ) -> BatchJob? {

        if let intakeRequestID,
           let existingJob = jobs.first(
               where: {
                   $0.intakeRequestID
                   == intakeRequestID
               }
           ) {
            return existingJob
        }

        let reservedRecordCount =
            jobs.reduce(into: 0) { count, job in
                count += job.tasks.count {
                    !$0.phase.isTerminal
                }
            }
        let maximumAdmissionCount =
            MemoMarkCommercePolicy(
                isPlus:
                    commerceSnapshot.isPlus,
                totalAllowance:
                    commerceSnapshot.totalAllowance,
                batchLimit:
                    commerceSnapshot.batchLimit
            )
            .maximumAdmissionCount(
                after:
                    commerceSnapshot
                    .successfulRecordCount,
                reservedRecordCount:
                    reservedRecordCount
            )

        guard payloads.count
                <= maximumAdmissionCount else {
            lastErrorMessage =
                maximumAdmissionCount == 0
                ? commerceLocalized(
                    "commerce.queue.allowance_completed",
                    fallback: "免费成长记录额度已使用完，请在时光记中了解 MemoMark+。"
                )
                : commerceFormatted(
                    "commerce.queue.maximum_admission_format",
                    fallback: "当前一次最多可以加入 %lld 张照片。",
                    Int64(maximumAdmissionCount)
                )
            return nil
        }

        guard let job =
            execution.enqueue(
                payloads: payloads,
                configuration: configuration,
                launchSource: launchSource,
                intakeSummary:
                    intakeSummary,
                intakeRequestID:
                    intakeRequestID,
                title: title
            )
        else {
            return nil
        }

        let jobsBeforeAdmission = jobs
        let pendingReceiptKeysBeforeAdmission =
            pendingSaveReceiptRemovalKeys
        jobs.insert(job, at: 0)
        guard persistJobs() else {
            jobs = jobsBeforeAdmission
            pendingSaveReceiptRemovalKeys =
                pendingReceiptKeysBeforeAdmission
            return nil
        }
        scheduleStartNotificationIfNeeded(
            for: job.id
        )
        if automaticallyStartsProcessing {
            startProcessingIfNeeded()
        }
        return job
    }

    func updateCommerceSnapshot(
        _ snapshot: MemoMarkCommerceSnapshot
    ) {
        _ = persistCommerceSnapshot(
            snapshot,
            failureMessage: "同步使用额度时无法完成本地保存，处理已暂停。"
        )
    }

    func retryFailedTasks(
        in jobID: UUID
    ) {

        guard let job = jobs.first(
            where: { $0.id == jobID }
        ) else {
            return
        }

        let retryableTaskCount =
            job.tasks.count {
                $0.phase == .failed
                && ($0.failure?.canRetry ?? true)
            }
        let reservedRecordCount =
            jobs.reduce(into: 0) { count, currentJob in
                count += currentJob.tasks.count {
                    !$0.phase.isTerminal
                }
            }
        let maximumAdmissionCount =
            MemoMarkCommercePolicy(
                isPlus:
                    commerceSnapshot.isPlus,
                totalAllowance:
                    commerceSnapshot.totalAllowance,
                batchLimit:
                    commerceSnapshot.batchLimit
            )
            .maximumAdmissionCount(
                after:
                    commerceSnapshot
                    .successfulRecordCount,
                reservedRecordCount:
                    reservedRecordCount
            )

        guard retryableTaskCount > 0,
              retryableTaskCount
                <= maximumAdmissionCount else {
            if retryableTaskCount > 0 {
                lastErrorMessage =
                    maximumAdmissionCount == 0
                    ? commerceLocalized(
                        "commerce.queue.allowance_completed",
                        fallback: "免费成长记录额度已使用完，请在时光记中了解 MemoMark+。"
                    )
                    : commerceFormatted(
                        "commerce.queue.retry_available_format",
                        fallback: "当前剩余额度可重试 %lld 张照片。",
                        Int64(maximumAdmissionCount)
                    )
            }
            return
        }

        guard execution.retryFailedTasks(
            in: &jobs,
            jobID: jobID
        ) else {
            lastErrorMessage = "重试没有开始，请重新打开处理进度后再试。"
            return
        }

        guard persistJobs() else {
            return
        }
        startProcessingIfNeeded()
    }

    func cancelJob(
        _ jobID: UUID
    ) {

        let queuedSourceURLs =
            jobs.first {
                $0.id == jobID
            }?
            .tasks
            .filter {
                $0.phase == .queued
            }
            .map(\.sourceURL)
            ?? []

        guard execution.cancelJob(
            in: &jobs,
            jobID: jobID
        ) else {
            return
        }

        guard persistJobs() else {
            return
        }

        for sourceURL in queuedSourceURLs {
            execution
                .cleanupManagedSourceIfNeeded(
                    at: sourceURL
                )
        }
    }

    func startProcessingIfNeeded() {

        guard !persistenceBlocked else {
            return
        }

        guard processingTask == nil else {
            return
        }

        reconcileCommittedPhotoLibraryReceiptsForResume()
        guard !persistenceBlocked else {
            return
        }

        guard nextPendingTaskReference() != nil else {
            clearProcessingIndicators()
            return
        }

        processingTask = Task { @MainActor in
            await execution
                .processingLoop(
                    in: self
                )
        }
    }

    var canContinueProcessing: Bool {
        !persistenceBlocked
    }

    var pendingTaskCount: Int {
        jobs
            .flatMap(\.tasks)
            .filter { $0.phase.isPending }
            .count
    }

    func stopProcessingForBackgroundExpiration() {
        guard processingTask != nil else {
            return
        }
        markActiveTaskAsBackgroundExpiredIfNeeded()
        processingTask?.cancel()
    }

    /// Stops the current processing owner after a processor reports a plain
    /// cancellation. The task remains queued for a future owner; unlike a
    /// background expiration this does not create a failure record.
    func stopProcessingForCancellation() {
        processingTask?.cancel()
    }

    private func markActiveTaskAsBackgroundExpiredIfNeeded() {
        guard let activeJobID,
              let activeTaskID,
              let jobIndex = jobs.firstIndex(where: { $0.id == activeJobID }),
              let taskIndex = jobs[jobIndex].tasks.firstIndex(where: { $0.id == activeTaskID })
        else {
            return
        }

        let currentPhase = jobs[jobIndex].tasks[taskIndex].phase
        guard !currentPhase.isTerminal,
              currentPhase != .savingToPhotoLibrary
        else {
            // A save in flight must remain recoverable through its durable
            // receipt/readback reconciliation path. It must not be reported
            // as a processing failure before PhotoKit ownership is known.
            return
        }

        let taskID = jobs[jobIndex].tasks[taskIndex].id
        let diagnosticFailure = ProductionDiagnosticFailureClassifier
            .backgroundExpired(
                phase: currentPhase.rawValue,
                operationID: taskID,
                language: .interfaceStored
            )
        jobs[jobIndex].tasks[taskIndex].renderedFileURL = nil
        jobs[jobIndex].tasks[taskIndex].notificationAttachmentURL = nil
        jobs[jobIndex].tasks[taskIndex].failure = BatchTaskFailure(
            phase: currentPhase,
            message: diagnosticFailure.userMessage,
            classification: .interrupted,
            canRetry: true,
            diagnosticCode: diagnosticFailure.code.rawValue,
            supportID: diagnosticFailure.supportID
        )
        jobs[jobIndex].tasks[taskIndex].progress = BatchTaskProgress(
            currentUnit: 0,
            totalUnits: 1,
            statusMessage: "后台处理时间已用尽，请重试"
        )
        // Publish the terminal phase last. Observers use the phase as the
        // durable-state boundary; publishing it first could expose a failed
        // task before its diagnostic and progress fields were fully written.
        jobs[jobIndex].tasks[taskIndex].phase = .failed
        jobs[jobIndex].updatedAt = Date()
        jobs[jobIndex].state = execution.derivedJobState(from: jobs[jobIndex].tasks)
        setLastErrorMessage(diagnosticFailure.userMessage)
        _ = persistJobs()
    }

    func retryPersistence() {

        guard persistenceBlocked else {
            return
        }

        switch persistence.loadPersistedJobsResult() {
        case .success(let loadedJobs):
            if persistenceRecoveryRequiresReload {
                // Startup may have failed before an in-memory queue existed.
                // Rehydrate first; never let the empty startup fallback
                // overwrite a queue that became readable later.
                jobs = loadedJobs
                lastDurableJobs = loadedJobs
                pendingSaveReceiptRemovalKeys = []
                lastDurableSaveReceiptRemovalKeys = []
            }

            if let error = persistence.persistJobs(jobs).error {
                startupPersistenceError = error
                lastErrorMessage = error.message
                return
            }

            // The queue itself is durable again. Clear the queue-level block
            // before secondary reconciliation so a later receipt/commerce
            // failure reports its own recoverable cause instead of leaving a
            // stale startup decoding error visible to the user.
            persistenceBlocked = false
            isPersistenceBlocked = false
            persistenceRecoveryRequiresReload = false
            startupPersistenceError = nil
            lastErrorMessage = ""

            history.commitResourceCleanup(
                retaining: jobs
            )
            removePendingSaveReceipts()
            lastDurableJobs = jobs
            lastDurableSaveReceiptRemovalKeys =
                pendingSaveReceiptRemovalKeys
            reconcileSaveReceiptsWithPersistedJobs()
            guard !persistenceBlocked else {
                return
            }

            if let pendingCommerceSnapshot {
                guard persistCommerceSnapshot(
                    pendingCommerceSnapshot,
                    failureMessage: "同步使用额度时无法完成本地保存，处理已暂停。"
                ) else {
                    return
                }
            }

            reconcileCommerceUsageWithDurableJobs()
            guard !persistenceBlocked else {
                return
            }
            startProcessingIfNeeded()
        case .failure(let error):
            startupPersistenceError = error
            lastErrorMessage = error.message
            isPersistenceBlocked = true
        }
    }

    /// Retries a blocked persistence state when the application returns to a
    /// usable lifecycle phase. The method is intentionally idempotent so
    /// callers can invoke it from both UI recovery and lifecycle refresh.
    func retryPersistenceIfNeeded() {
        guard persistenceBlocked else {
            return
        }

        retryPersistence()
    }

    var usageSnapshot: BatchUsageSnapshot {

        history.usageSnapshot(
            for: jobs
        )
    }

    var latestFailureSummary:
        BatchFailureSummary? {

        history.latestFailureSummary(
            for: jobs
        )
    }

    var recentFailureRecords:
        [BatchFailureRecord] {

        history.recentFailureRecords(
            for: jobs
        )
    }

    var latestExternalIntakeSummary:
        ExternalIntakeSummary? {

        history.latestExternalIntakeSummary(
            for: jobs
        )
    }

    var referencedManagedSourceURLs:
        Set<URL> {

        history.referencedManagedSourceURLs(
            for: jobs
        )
    }

    func retryLatestFailedTasks() {

        guard let latestFailureSummary else {
            return
        }

        guard latestFailureSummary
            .hasRetryableFailures else {
            return
        }

        retryFailedTasks(
            in: latestFailureSummary.jobID
        )
    }

    func clearTerminalExternalJobHistory(
        preserving preservedJobID: UUID?
    ) {

        let originalJobs = jobs
        let originalCount = originalJobs.count

        jobs =
            jobs.filter { job in
                if job.id == preservedJobID {
                    return true
                }

                guard job.launchSource != .inAppPreview else {
                    return true
                }

                guard job.tasks.allSatisfy({
                    $0.phase.isTerminal
                }) else {
                    return true
                }

                return false
            }

        guard jobs.count != originalCount else {
            return
        }

        let retainedJobIDs = Set(jobs.map(\.id))
        pendingSaveReceiptRemovalKeys.formUnion(
            originalJobs
            .filter {
                !retainedJobIDs.contains($0.id)
            }
            .flatMap(\.tasks)
            .map {
                $0.id.uuidString
            }
        )
        persistJobs()
    }
}

// MARK: - Internal Coordination

extension BatchQueueStore {

    func reconcileCommittedPhotoLibraryReceiptsForResume() {

        let savingTaskReferences:
            [BatchQueueExecution.TaskReference] = jobs.flatMap { job in
            job.tasks.compactMap { task in
                guard task.phase
                        == BatchTaskPhase
                        .savingToPhotoLibrary else {
                    return nil
                }
                return BatchQueueExecution.TaskReference(
                    jobID: job.id,
                    taskID: task.id
                )
            }
        }
        var didReconcile = false
        var reconciledTasks: [BatchTask] = []
        var reconciledResourceURLs:
            [(rendered: URL?, source: URL)] = []

        for reference in savingTaskReferences {
            guard let task = currentTask(at: reference),
                  task.phase
                    == BatchTaskPhase
                    .savingToPhotoLibrary,
                  let assetIdentifier =
                    photoLibraryReceiptAssetLocator
                    .visibleAssetIdentifier(
                        for: task.id.uuidString
                    ) else {
                continue
            }

            // Startup reconciliation has directly observed the exact
            // PhotoKit asset. Upgrade the local receipt before completing the
            // durable queue projection. A receipt that is already committed
            // needs no write; otherwise a failed upgrade must leave the task
            // in its recoverable saving phase instead of projecting success
            // without durable acknowledgement.
            if saveReceiptStore.assetIdentifier(
                for: task.id.uuidString
            ) == nil,
               !saveReceiptStore.materializePendingIntent(
                   for: task.id.uuidString
               ) {
                continue
            }
            guard saveReceiptStore.ensureCommitted(
                for: task.id.uuidString
            ) else {
                continue
            }

            reconciledResourceURLs.append(
                (
                    rendered: task.renderedFileURL,
                    source: task.sourceURL
                )
            )

            updateTask(
                at: reference,
                persist: false,
                recordsSuccessfulSave: false
            ) { task in
                task.renderedFileURL = nil
                task.savedAssetIdentifier = assetIdentifier
                task.failure = nil
                task.phase = .completed
                task.progress = BatchTaskProgress(
                    currentUnit: task.progress.totalUnits,
                    totalUnits: task.progress.totalUnits,
                    statusMessage: "处理完成"
                )
            }
            if let completedTask = currentTask(at: reference) {
                reconciledTasks.append(completedTask)
            }
            didReconcile = true
        }

        guard didReconcile else {
            return
        }

        guard persistJobs() else {
            return
        }

        for task in reconciledTasks {
            recordSuccessfulSaveIfNeeded(for: task)
        }

        for resourceURLs in reconciledResourceURLs {
            execution.cleanupTemporaryFileIfNeeded(
                at: resourceURLs.rendered
            )
            execution.cleanupManagedSourceIfNeeded(
                at: resourceURLs.source
            )
        }
    }

    func nextPendingTaskReference()
    -> BatchQueueExecution.TaskReference? {

        execution.nextPendingTaskReference(
            in: jobs
        )
    }

    func normalizeJobsForResume() {

        let existingFailureTaskIDs = Set(
            jobs.flatMap(\.tasks)
                .filter { $0.failure != nil }
                .map(\.id)
        )
        let protectedTaskIDs =
            unresolvedPhotoLibrarySaveTaskIDs()

        guard persistence.normalizeJobsForResume(
            &jobs,
            protectedTaskIDs: protectedTaskIDs,
            deriveJobState:
                execution.derivedJobState
        ) else {
            return
        }

        persistJobs()

        guard let productionDiagnostics else {
            return
        }
        let recoveredFailures:
            [(UUID, BatchTask, BatchTaskFailure)] =
            jobs.flatMap { job in
            job.tasks.compactMap { task in
                guard !existingFailureTaskIDs.contains(task.id),
                      let failure = task.failure else {
                    return nil
                }
                return (job.id, task, failure)
            }
        }
        Task {
            for (jobID, task, failure) in recoveredFailures {
                let pixelSize = MediaPixelSize(
                    fileURL: task.sourceURL
                )
                await productionDiagnostics.record(
                    ProductionDiagnosticEvent(
                        operationID: task.id,
                        category: .processing,
                        stage:
                            "processing.recovery.\(failure.phase.rawValue)",
                        outcome: .failed,
                        errorCode:
                            failure.diagnosticCode.flatMap {
                                ProductionDiagnosticErrorCode(
                                    rawValue: $0
                                )
                            },
                        context:
                            ProductionDiagnosticContext(
                                jobID: jobID,
                                taskID: task.id,
                                mediaContentTypeIdentifier:
                                    task.contentTypeIdentifier,
                                mediaPixelWidth:
                                    pixelSize?.width,
                                mediaPixelHeight:
                                    pixelSize?.height,
                                processingPhase:
                                    failure.phase.rawValue
                            )
                    )
                )
            }
        }
    }

    func unresolvedPhotoLibrarySaveTaskIDs()
    -> Set<UUID> {

        Set(
            jobs.flatMap(\.tasks)
                .compactMap { task in
                    guard task.phase
                            == BatchTaskPhase
                            .savingToPhotoLibrary else {
                        return nil
                    }

                    let hasAssetReceipt =
                        saveReceiptStore.assetIdentifier(
                            for: task.id.uuidString
                        ) != nil
                    let hasPendingIntent =
                        saveReceiptStore.hasPendingIntent(
                            for: task.id.uuidString
                        )
                    guard hasAssetReceipt || hasPendingIntent else {
                        return nil
                    }

                    return task.id
                }
        )
    }

    @discardableResult
    func persistJobs() -> Bool {

        guard !persistenceBlocked else {
            return false
        }

        var candidateJobs = jobs
        var candidatePendingReceiptKeys =
            pendingSaveReceiptRemovalKeys
        candidatePendingReceiptKeys.formUnion(
            history.trimTerminalJobHistoryIfNeeded(
                &candidateJobs
            )
        )

        if let error = persistence.persistJobs(candidateJobs).error {
            // Never expose an in-memory projection that will disappear after
            // restart. Restore the last durable queue and stop the active
            // owner before it can continue processing against a split state.
            jobs = lastDurableJobs
            pendingSaveReceiptRemovalKeys =
                lastDurableSaveReceiptRemovalKeys
            lastErrorMessage = error.message
            persistenceBlocked = true
            isPersistenceBlocked = true
            processingTask?.cancel()
            return false
        } else {
            jobs = candidateJobs
            pendingSaveReceiptRemovalKeys =
                candidatePendingReceiptKeys
            history.commitResourceCleanup(
                retaining: jobs
            )
            removePendingSaveReceipts()
            lastDurableJobs = jobs
            lastDurableSaveReceiptRemovalKeys =
                pendingSaveReceiptRemovalKeys
            return true
        }
    }

    func removePendingSaveReceipts() {
        saveReceiptStore.removeReceipts(
            for: pendingSaveReceiptRemovalKeys
        )
        pendingSaveReceiptRemovalKeys.removeAll()
    }

    func reconcileSaveReceiptsWithPersistedJobs() {
        saveReceiptStore.pruneReceipts(
            retaining: Set(
                jobs
                .flatMap(\.tasks)
                .map {
                    $0.id.uuidString
                }
            )
        )
    }

    func scheduleStartNotificationIfNeeded(
        for jobID: UUID
    ) {

        notifications
            .scheduleStartNotificationIfNeeded(
                for: jobID,
                in: self
            )
    }

    func deliverProgressNotificationIfNeeded(
        for jobID: UUID,
        stage: String
    ) async {

        await notifications
            .deliverProgressNotificationIfNeeded(
                for: jobID,
                stage: stage,
                in: self
            )
    }

    func deliverFinalNotificationIfNeeded(
        for jobID: UUID
    ) async {

        await notifications
            .deliverFinalNotificationIfNeeded(
                for: jobID,
                in: self
            )
    }

    func processingLoopDidFinish(
        shouldRestart: Bool = true
    ) {

        processingTask = nil
        clearProcessingIndicators()

        if !shouldRestart {
            normalizeJobsForResume()
        }

        if shouldRestart,
           canContinueProcessing,
           nextPendingTaskReference() != nil {
            startProcessingIfNeeded()
        }
    }

    func setActiveProcessingReference(
        _ reference:
            BatchQueueExecution.TaskReference
    ) {

        activeJobID = currentJobID(
            at: reference
        )
        activeTaskID = currentTask(
            at: reference
        )?.id
    }

    func clearProcessingIndicators() {

        isProcessing = false
        activeJobID = nil
        activeTaskID = nil
    }

    func markProcessingStarted() {

        isProcessing = true
    }

    func setLastErrorMessage(
        _ message: String
    ) {

        lastErrorMessage = message
    }

    func currentJobID(
        at reference:
            BatchQueueExecution.TaskReference
    ) -> UUID? {

        currentJob(
            at: reference
        )?.id
    }

    func currentJob(
        at reference:
            BatchQueueExecution.TaskReference
    ) -> BatchJob? {
        jobs.first { $0.id == reference.jobID }
    }

    func currentTask(
        at reference:
            BatchQueueExecution.TaskReference
    ) -> BatchTask? {

        guard let job = jobs.first(where: { $0.id == reference.jobID }) else {
            return nil
        }
        return job.tasks.first { $0.id == reference.taskID }
    }

    func currentTaskPhase(
        at reference:
            BatchQueueExecution.TaskReference
    ) -> BatchTaskPhase? {

        currentTask(
            at: reference
        )?.phase
    }

    @discardableResult
    func cleanupManagedSourceForDurablyTerminalTask(
        at reference:
            BatchQueueExecution.TaskReference
    ) -> Bool {

        guard let task = currentTask(
            at: reference
        ),
        task.phase.isTerminal,
        persistJobs() else {
            return false
        }

        execution
            .cleanupManagedSourceIfNeeded(
                at: task.sourceURL
            )
        return true
    }

    @discardableResult
    func updateTask(
        at reference:
            BatchQueueExecution.TaskReference,
        persist: Bool = true,
        recordsSuccessfulSave: Bool = true,
        historyCoverCandidate: BatchJobHistoryCover? = nil,
        mutate: (inout BatchTask) -> Void
    ) -> Bool {

        guard let jobIndex = jobs.firstIndex(where: { $0.id == reference.jobID }),
              let taskIndex = jobs[jobIndex].tasks.firstIndex(where: { $0.id == reference.taskID }) else {
            return false
        }

        var job = jobs[jobIndex]
        let previousTask =
            job.tasks[taskIndex]
        mutate(&job.tasks[taskIndex])
        let updatedTask =
            job.tasks[taskIndex]
        job.updatedAt = Date()
        if job.historyCover == nil,
           let historyCoverCandidate,
           historyCoverCandidate.sourceTaskID == updatedTask.id {
            job.historyCover = historyCoverCandidate
        }
        job.state =
            execution.derivedJobState(
                from: job.tasks
            )
        jobs[jobIndex] = job

        guard persist else {
            return true
        }

        guard persistJobs() else {
            return false
        }

        if previousTask.phase != .completed,
           updatedTask.phase == .completed,
           recordsSuccessfulSave {
            recordSuccessfulSaveIfNeeded(
                for: updatedTask
            )
        }
        return true
    }

    func recordSuccessfulSaveIfNeeded(
        for task: BatchTask
    ) {

        guard task.savedAssetIdentifier != nil,
              !commerceSnapshot.isPlus else {
            return
        }

        if commercePersistence.hasRecordedSuccessfulSave(
            taskID: task.id,
            environment: commerceSnapshot.environment
        ) {
            return
        }

        if !commercePersistence.recordSuccessfulSave(
            taskID: task.id,
            environment: commerceSnapshot.environment
        ) {
            // Another process may have recorded the same completed task
            // between the idempotency check above and this write. Treat that
            // already-durable state as success instead of blocking the queue.
            guard commercePersistence.hasRecordedSuccessfulSave(
                taskID: task.id,
                environment: commerceSnapshot.environment
            ) else {
                lastErrorMessage = "记录使用额度时无法完成本地保存，处理已暂停。"
                persistenceBlocked = true
                isPersistenceBlocked = true
                processingTask?.cancel()
                return
            }
        }

        let bonus =
            commercePersistence
            .bonusAllowance(
                environment:
                    commerceSnapshot.environment
            )
        let nextCommerceSnapshot =
            MemoMarkCommerceSnapshot(
                environment:
                    commerceSnapshot.environment,
                accessSource: .free,
                successfulRecordCount:
                    commercePersistence
                    .successfulRecordCount(
                        environment:
                            commerceSnapshot.environment
                    ),
                totalAllowance:
                    MemoMarkCommercePolicy
                    .baseFreeAllowance
                    + bonus,
                batchLimit:
                    MemoMarkCommercePolicy
                    .freeBatchLimit,
                firstRecorderDate: nil,
                updatedAt: Date()
            )
        guard persistCommerceSnapshot(
            nextCommerceSnapshot,
            failureMessage: "同步使用额度时无法完成本地保存，处理已暂停。"
        ) else {
            return
        }
    }

    private func reconcileCommerceUsageWithDurableJobs() {
        guard !commerceSnapshot.isPlus else {
            return
        }

        let completedTaskIDs = Set(
            jobs
                .flatMap(\.tasks)
                .filter {
                    $0.phase == .completed
                    && $0.savedAssetIdentifier != nil
                }
                .map(\.id)
        )

        guard commercePersistence.reconcileSuccessfulSaves(
            taskIDs: completedTaskIDs,
            environment: commerceSnapshot.environment
        ) else {
            lastErrorMessage = "无法校准已完成记录的本地使用额度，处理已暂停。"
            persistenceBlocked = true
            isPersistenceBlocked = true
            processingTask?.cancel()
            return
        }

        let successfulRecordCount =
            commercePersistence.successfulRecordCount(
                environment: commerceSnapshot.environment
            )
        guard successfulRecordCount
                != commerceSnapshot.successfulRecordCount else {
            return
        }

        let reconciledSnapshot =
            MemoMarkCommerceSnapshot(
                environment: commerceSnapshot.environment,
                accessSource: .free,
                successfulRecordCount: successfulRecordCount,
                totalAllowance: MemoMarkCommercePolicy
                    .resolved(
                        for: commerceSnapshot.environment,
                        bonusAllowance:
                            commercePersistence.bonusAllowance(
                                environment:
                                    commerceSnapshot.environment
                            )
                    )
                    .totalAllowance,
                batchLimit: MemoMarkCommercePolicy
                    .resolved(
                        for: commerceSnapshot.environment,
                        bonusAllowance:
                            commercePersistence.bonusAllowance(
                                environment:
                                    commerceSnapshot.environment
                            )
                    )
                    .batchLimit,
                firstRecorderDate: nil,
                updatedAt: Date()
            )

        guard persistCommerceSnapshot(
            reconciledSnapshot,
            failureMessage: "无法保存校准后的使用额度，处理已暂停。"
        ) else {
            return
        }
    }

    @discardableResult
    private func persistCommerceSnapshot(
        _ snapshot: MemoMarkCommerceSnapshot,
        failureMessage: String
    ) -> Bool {
        guard commercePersistence.saveSharedSnapshot(snapshot) else {
            pendingCommerceSnapshot = snapshot
            lastErrorMessage = failureMessage
            persistenceBlocked = true
            isPersistenceBlocked = true
            processingTask?.cancel()
            return false
        }

        pendingCommerceSnapshot = nil
        commerceSnapshot = snapshot
        return true
    }

    func jobIndex(
        for jobID: UUID
    ) -> Int? {

        jobs.firstIndex {
            $0.id == jobID
        }
    }

    func job(
        at index: Int
    ) -> BatchJob? {

        guard jobs.indices.contains(index) else {
            return nil
        }

        return jobs[index]
    }

    func markStartNotificationSent(
        at jobIndex: Int
    ) {

        guard jobs.indices.contains(jobIndex)
        else {
            return
        }

        jobs[jobIndex]
            .startNotificationSentAt =
            Date()
        persistJobs()
    }

    func markFinalNotificationSent(
        at jobIndex: Int
    ) {

        guard jobs.indices.contains(jobIndex)
        else {
            return
        }

        jobs[jobIndex]
            .finalNotificationSentAt =
            Date()
        persistJobs()
    }

    func releaseNotificationAttachmentsIfCovered(
        for jobID: UUID
    ) {
        guard let index = jobs.firstIndex(where: { $0.id == jobID }),
              jobs[index].historyCover != nil,
              jobs[index].tasks.allSatisfy({ $0.phase.isTerminal }) else {
            return
        }
        for taskIndex in jobs[index].tasks.indices {
            jobs[index].tasks[taskIndex].notificationAttachmentURL = nil
        }
        persistJobs()
    }

    func markProgressNotificationSent(
        at jobIndex: Int,
        stage: String
    ) {

        guard jobs.indices.contains(jobIndex)
        else {
            return
        }

        jobs[jobIndex]
            .lastProgressNotificationStage =
            stage
        persistJobs()
    }

    private func commerceLocalized(
        _ key: String,
        fallback: String
    ) -> String {
        MemoMarkLanguage.interfaceStored.localized(
            key: key,
            fallback: fallback
        )
    }

    private func commerceFormatted(
        _ key: String,
        fallback: String,
        _ arguments: CVarArg...
    ) -> String {
        let language = MemoMarkLanguage.interfaceStored
        return String(
            format: language.localized(
                key: key,
                fallback: fallback
            ),
            locale: language.locale,
            arguments: arguments
        )
    }
}
#endif
