#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Combine

@MainActor
final class BatchQueueStore:
    ObservableObject,
    BatchTaskExecutionRuntime {

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

    private let durableCommandGate =
        BatchQueueCommandGate()

    private lazy var durableLedger:
        BatchQueueDurableLedger =
        BatchQueueDurableLedger.bootstrap(
            persistence: persistence
        ).ledger

    private let history:
        BatchQueueHistory

    private let notifications:
        BatchQueueNotifications

    private let commerceAccounting:
        BatchQueueCommerceAccounting

    private let saveReceiptStore:
        PhotoLibrarySaveReceiptStore

    private let saveReceiptLedger:
        PhotoLibrarySaveReceiptLedger

    private let photoLibraryReceiptAssetLocator:
        any PhotoLibraryReceiptAssetLocating

    private let photoLibraryReceiptResumeRecoveryPlanner:
        PhotoLibraryReceiptResumeRecoveryPlanner

    private let bootstrapReceiptReconciler:
        BatchQueueBootstrapReceiptReconciler
    private let bootstrapRecoveryNormalizer:
        BatchQueueBootstrapRecoveryNormalizer

    private let productionDiagnostics:
        ProductionDiagnosticsRepository?

    private var processingTask:
        Task<Void, Never>?

    private var persistenceBlocked = false

    private var pendingCommerceSnapshot:
        MemoMarkCommerceSnapshot?

    private var pendingSaveReceiptRemovalKeys = Set<String>()

    private var lastDurableJobs: [BatchJob] = []

    private var lastDurableSaveReceiptRemovalKeys = Set<String>()

    init(
        defaults: UserDefaults? = nil,
        settingsService: SettingsService? = nil,
        notificationService:
            BatchNotificationService? = nil,
        externalIntakeStore:
            ExternalPhotoIntakeStore? = nil,
        photoRepository:
            PhotoRepository? = nil,
        photoLibraryExportService:
            PhotoLibraryExportService? = nil,
        buildRecordCard:
            BuildRecordCardTransaction? = nil,
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
            @MainActor (RecordCard, BatchConfigurationSnapshot) async throws -> [CardTextBlock] = {
                card,
                configuration in
                try ProductionRenderHealthCheck.validate(
                    card: card,
                    configuration: configuration
                )
            }
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
        let resolvedExecution =
            BatchQueueExecution(
                externalIntakeStore:
                    resolvedExternalIntakeStore,
                photoRepository:
                    photoRepository,
                photoLibraryExportService:
                    photoLibraryExportService,
                buildRecordCard:
                    buildRecordCard,
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
        self.execution = resolvedExecution
        let resolvedQueuePersistence =
            persistence
            ?? (defaults == nil
                ? BatchQueuePersistence()
                : BatchQueuePersistence(
                    defaults: resolvedDefaults
                ))
        self.persistence =
            resolvedQueuePersistence
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
        let resolvedCommerceAccounting =
            BatchQueueCommerceAccounting(
                persistence:
                    MemoMarkCommercePersistence(
                        defaults: resolvedDefaults
                    )
            )
        self.commerceAccounting =
            resolvedCommerceAccounting
        let usesSharedReceiptPersistence =
            saveReceiptStore == nil
            && defaults == nil
        let resolvedSaveReceiptStore =
            saveReceiptStore
            ?? (usesSharedReceiptPersistence
                ? PhotoLibrarySaveReceiptLedger.sharedStore
                : PhotoLibrarySaveReceiptStore(
                    defaults: resolvedDefaults
                ))
        self.saveReceiptStore = resolvedSaveReceiptStore
        let resolvedSaveReceiptLedger =
            usesSharedReceiptPersistence
            ? .shared
            : PhotoLibrarySaveReceiptLedger(
                store: resolvedSaveReceiptStore
            )
        self.saveReceiptLedger = resolvedSaveReceiptLedger
        let resolvedPhotoLibraryReceiptAssetLocator =
            photoLibraryReceiptAssetLocator
            ?? PhotoLibrarySaveReceiptAssetLocator()
        self.photoLibraryReceiptAssetLocator =
            resolvedPhotoLibraryReceiptAssetLocator
        self.photoLibraryReceiptResumeRecoveryPlanner =
            PhotoLibraryReceiptResumeRecoveryPlanner(
                receiptLedger: resolvedSaveReceiptLedger,
                assetLocator: resolvedPhotoLibraryReceiptAssetLocator
            )
        let resolvedBootstrapReceiptReconciler =
            BatchQueueBootstrapReceiptReconciler(
                saveReceiptStore: resolvedSaveReceiptStore,
                assetLocator:
                    resolvedPhotoLibraryReceiptAssetLocator
            )
        self.bootstrapReceiptReconciler =
            resolvedBootstrapReceiptReconciler
        self.bootstrapRecoveryNormalizer =
            BatchQueueBootstrapRecoveryNormalizer(
                persistence: resolvedQueuePersistence,
                receiptReconciler:
                    resolvedBootstrapReceiptReconciler,
                deriveJobState:
                    resolvedExecution.derivedJobState(from:)
            )
        self.productionDiagnostics =
            productionDiagnostics
        self.commerceSnapshot =
            resolvedCommerceAccounting
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
        }

        guard !persistenceBlocked else {
            return
        }

        applyBootstrapReceiptReconciliation()
        guard !persistenceBlocked else {
            return
        }
        normalizeJobsDuringBootstrap()
        guard !persistenceBlocked else {
            return
        }
        pruneBootstrapReceipts()
        guard !persistenceBlocked else {
            return
        }
        reconcileCommerceUsageWithDurableJobs()
        guard !persistenceBlocked else {
            return
        }
        if self.automaticallyStartsProcessing {
            Task { @MainActor [weak self] in
                await self?.startProcessingIfNeeded()
            }
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
    ) async -> BatchJob? {

        let payloads = urls.map {
            BatchTaskIntakePayload(
                sourceURL: $0
            )
        }

        return await enqueue(
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
    ) async -> BatchJob? {

        let admission = await withDurableCommand {
            await admitJob(
                payloads: payloads,
                configuration: configuration,
                launchSource: launchSource,
                intakeSummary: intakeSummary,
                intakeRequestID: intakeRequestID,
                title: title
            )
        }
        guard let admission else {
            return nil
        }
        if admission.didInsert,
           automaticallyStartsProcessing {
            await startProcessingIfNeeded()
        }
        return admission.job
    }

    private func admitJob(
        payloads: [BatchTaskIntakePayload],
        configuration: BatchConfigurationSnapshot,
        launchSource: BatchJobLaunchSource,
        intakeSummary:
            ExternalPhotoImportSummary?,
        intakeRequestID: UUID?,
        title: String?
    ) async -> BatchQueueAdmission? {

        if let intakeRequestID,
           let existingJob = jobs.first(
               where: {
                   $0.intakeRequestID
                   == intakeRequestID
               }
           ) {
            return BatchQueueAdmission(
                job: existingJob,
                didInsert: false
            )
        }

        let maximumAdmissionCount =
            commerceAccounting.admissionCapacity(
                among: jobs,
                current: commerceSnapshot
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

        let result = await durableLedger.admit(job)
        guard let admission =
                await projectDurableTransaction(result) else {
            return nil
        }

        guard admission.didInsert else {
            return admission
        }
        scheduleStartNotificationIfNeeded(
            for: admission.job.id
        )
        return admission
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
    ) async {

        let didRetry = await withDurableCommand {
            await retryFailedTasksCommand(
                in: jobID
            )
        }
        if didRetry {
            await startProcessingIfNeeded()
        }
    }

    private func retryFailedTasksCommand(
        in jobID: UUID
    ) async -> Bool {

        guard let job = jobs.first(
            where: { $0.id == jobID }
        ) else {
            return false
        }

        let admission = commerceAccounting.retryAdmission(
            for: job,
            among: jobs,
            current: commerceSnapshot
        )

        guard admission.retryableTaskCount > 0,
              admission.retryableTaskCount
                <= admission.maximumAdmissionCount else {
            if admission.retryableTaskCount > 0 {
                lastErrorMessage =
                    admission.maximumAdmissionCount == 0
                    ? commerceLocalized(
                        "commerce.queue.allowance_completed",
                        fallback: "免费成长记录额度已使用完，请在时光记中了解 MemoMark+。"
                    )
                    : commerceFormatted(
                        "commerce.queue.retry_available_format",
                        fallback: "当前剩余额度可重试 %lld 张照片。",
                        Int64(admission.maximumAdmissionCount)
                    )
            }
            return false
        }

        let result = await durableLedger
            .retryFailedTasks(in: jobID)
        guard let didRetry =
                await projectDurableTransaction(result),
              didRetry else {
            lastErrorMessage = "重试没有开始，请重新打开处理进度后再试。"
            return false
        }
        return true
    }

    func cancelJob(
        _ jobID: UUID
    ) async {

        await withDurableCommand {
            await cancelJobCommand(jobID)
        }
    }

    private func cancelJobCommand(
        _ jobID: UUID
    ) async {

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

        let result = await durableLedger.cancelJob(jobID)
        guard let didCancel =
                await projectDurableTransaction(result),
              didCancel else {
            return
        }

        for sourceURL in queuedSourceURLs {
            execution
                .cleanupManagedSourceIfNeeded(
                    at: sourceURL
                )
        }
    }

    func startProcessingIfNeeded() async {

        guard !persistenceBlocked else {
            return
        }

        guard processingTask == nil else {
            return
        }

        await reconcileCommittedPhotoLibraryReceiptsForResume()
        guard !persistenceBlocked else {
            return
        }
        guard processingTask == nil else {
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

    func stopProcessingForBackgroundExpiration() async {
        guard processingTask != nil else {
            return
        }
        await markActiveTaskAsBackgroundExpiredIfNeeded()
        processingTask?.cancel()
    }

    /// Stops the current processing owner after a processor reports a plain
    /// cancellation. The task remains queued for a future owner; unlike a
    /// background expiration this does not create a failure record.
    func stopProcessingForCancellation() {
        processingTask?.cancel()
    }

    private func markActiveTaskAsBackgroundExpiredIfNeeded() async {
        guard let activeJobID,
              let activeTaskID,
              let task = jobs
                .first(where: { $0.id == activeJobID })?
                .tasks
                .first(where: { $0.id == activeTaskID })
        else {
            return
        }

        let currentPhase = task.phase
        guard !currentPhase.isTerminal,
              currentPhase != .savingToPhotoLibrary
        else {
            // A save in flight must remain recoverable through its durable
            // receipt/readback reconciliation path. It must not be reported
            // as a processing failure before PhotoKit ownership is known.
            return
        }

        let taskID = task.id
        let diagnosticFailure = ProductionDiagnosticFailureClassifier
            .backgroundExpired(
                phase: currentPhase.rawValue,
                operationID: taskID,
                language: .interfaceStored
            )
        let failure = BatchTaskFailure(
            phase: currentPhase,
            message: diagnosticFailure.userMessage,
            classification: .interrupted,
            canRetry: true,
            diagnosticCode: diagnosticFailure.code.rawValue,
            supportID: diagnosticFailure.supportID
        )
        await withDurableCommand {
            let result = await durableLedger
                .expireActiveTask(
                    at: BatchTaskReference(
                        jobID: activeJobID,
                        taskID: activeTaskID
                    ),
                    failure: failure
                )
            guard await projectDurableTransaction(result) == true else {
                return
            }
            setLastErrorMessage(
                diagnosticFailure.userMessage
            )
        }
    }

    func retryPersistence() async {

        guard persistenceBlocked else {
            return
        }
        let recovered = await withDurableCommand {
            let result = await durableLedger.recover()
            switch result {
            case .recovered(let snapshot):
                jobs = snapshot.jobs
                lastDurableJobs = snapshot.jobs
                pendingSaveReceiptRemovalKeys = []
                lastDurableSaveReceiptRemovalKeys = []
                persistenceBlocked = false
                isPersistenceBlocked = false
                startupPersistenceError = nil
                lastErrorMessage = ""
                history.commitResourceCleanup(
                    retaining: jobs
                )
                return true

            case .failure(let error, let snapshot):
                jobs = snapshot.jobs
                lastDurableJobs = snapshot.jobs
                startupPersistenceError = error
                lastErrorMessage = error.message
                persistenceBlocked = true
                isPersistenceBlocked = true
                return false
            }
        }

        guard recovered else {
            return
        }
        await reconcileSaveReceiptsWithPersistedJobs()

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
        await startProcessingIfNeeded()
    }

    /// Retries a blocked persistence state when the application returns to a
    /// usable lifecycle phase. The method is intentionally idempotent so
    /// callers can invoke it from both UI recovery and lifecycle refresh.
    func retryPersistenceIfNeeded() async {
        guard persistenceBlocked else {
            return
        }

        await retryPersistence()
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

    func retryLatestFailedTasks() async {

        guard let latestFailureSummary else {
            return
        }

        guard latestFailureSummary
            .hasRetryableFailures else {
            return
        }

        await retryFailedTasks(
            in: latestFailureSummary.jobID
        )
    }

    func clearTerminalExternalJobHistory(
        preserving preservedJobID: UUID?
    ) async {
        await withDurableCommand {
            let result = await durableLedger
                .clearTerminalExternalHistory(
                    preserving: preservedJobID
                )
            guard let removal =
                    await projectDurableTransaction(result),
                  removal.didChange else {
                return
            }
            await saveReceiptLedger.removeReceipts(
                for: removal.removedTaskIDs
            )
        }
    }
}

// MARK: - Internal Coordination

extension BatchQueueStore {

    func applyBootstrapReceiptReconciliation() {

        let completions =
            bootstrapReceiptReconciler
            .reconcileCommittedReceipts(
                in: jobs
            )
        guard !completions.isEmpty else {
            return
        }
        var reconciledTasks: [BatchTask] = []
        var reconciledResourceURLs:
            [(rendered: URL?, source: URL)] = []

        for completion in completions {
            guard let task = currentTask(
                at: completion.reference
            ) else {
                continue
            }

            reconciledResourceURLs.append(
                (
                    rendered: task.renderedFileURL,
                    source: task.sourceURL
                )
            )

            updateTaskDuringBootstrap(
                at: completion.reference,
                persist: false,
                recordsSuccessfulSave: false
            ) { task in
                task.renderedFileURL = nil
                task.savedAssetIdentifier = completion.assetIdentifier
                task.failure = nil
                task.phase = .completed
                task.progress = BatchTaskProgress(
                    currentUnit: task.progress.totalUnits,
                    totalUnits: task.progress.totalUnits,
                    stage: .completed
                )
            }
            if let completedTask = currentTask(
                at: completion.reference
            ) {
                reconciledTasks.append(completedTask)
            }
        }

        guard !reconciledTasks.isEmpty else {
            return
        }

        guard persistJobsDuringBootstrap() else {
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

    func reconcileCommittedPhotoLibraryReceiptsForResume() async {
        await withDurableCommand {
            let reconciliationCommands =
                await photoLibraryReceiptResumeRecoveryPlanner.commands(
                    for: jobs
                )
            guard !reconciliationCommands.isEmpty else {
                return
            }
            let result = await durableLedger.transaction { jobs in
                var mutations: [BatchQueueTaskMutation] = []
                let policy = BatchQueueTransitionPolicy()
                for command in reconciliationCommands {
                    let mutation: BatchQueueTaskMutation?
                    switch command {
                    case .complete(
                        let reference,
                        let assetIdentifier
                    ):
                        mutation = policy
                            .reconcileCommittedPhotoLibrarySave(
                                at: reference,
                                in: &jobs,
                                assetIdentifier: assetIdentifier,
                                now: Date()
                            )
                    case .permissionRecoveryRequired(
                        let reference,
                        let failure
                    ):
                        mutation = policy.apply(
                            .failed(failure),
                            at: reference,
                            in: &jobs,
                            now: Date()
                        )
                    }
                    if let mutation {
                        mutations.append(mutation)
                    }
                }
                return mutations.isEmpty
                    ? .unchanged(mutations)
                    : .commit(mutations)
            }
            guard let mutations =
                    await projectDurableTransaction(result) else {
                return
            }

            for mutation in mutations {
                recordSuccessfulSaveIfNeeded(
                    for: mutation.updated
                )
                if let failure = mutation.updated.failure {
                    lastErrorMessage = failure.message
                }
                execution.cleanupTemporaryFileIfNeeded(
                    at: mutation.previous.renderedFileURL
                )
                execution.cleanupManagedSourceIfNeeded(
                    at: mutation.previous.sourceURL
                )
            }
        }
    }

    func nextPendingTaskReference()
    -> BatchQueueExecution.TaskReference? {

        execution.nextPendingTaskReference(
            in: jobs
        )
    }

    func normalizeJobsDuringBootstrap() {

        let result =
            bootstrapRecoveryNormalizer.normalize(
                &jobs
            )
        guard result.didChange else {
            return
        }

        persistJobsDuringBootstrap()

        guard let productionDiagnostics else {
            return
        }
        Task {
            await BatchQueueRecoveryDiagnosticsReporter.record(
                result.recoveredFailures,
                to: productionDiagnostics
            )
        }
    }

    func normalizeJobsForResume() async {
        await withDurableCommand {
            let sourceInspector =
                BatchQueueResumeSourceInspector()
            let existingFailureTaskIDs = Set(
                jobs.flatMap(\.tasks)
                    .filter { $0.failure != nil }
                    .map(\.id)
            )
            let protectedTaskIDs =
                await unresolvedPhotoLibrarySaveTaskIDs()
            var missingSourceURLs = Set<URL>()
            var missingFailures:
                [UUID: BatchTaskFailure] = [:]

            for task in jobs.flatMap(\.tasks)
            where !task.phase.isTerminal
                && !protectedTaskIDs.contains(task.id)
                && sourceInspector.isMissingManagedSource(
                    task.sourceURL
                ) {
                missingSourceURLs.insert(
                    task.sourceURL.standardizedFileURL
                )
                missingFailures[task.id] =
                    sourceInspector.missingSourceFailure(
                        phase: task.phase,
                        taskID: task.id
                    )
            }

            let unavailableSourceURLs =
                missingSourceURLs
            let unavailableSourceFailures =
                missingFailures

            let result = await durableLedger.transaction { jobs in
                let changed = BatchQueueResumePolicy()
                    .normalize(
                        &jobs,
                        protectedTaskIDs:
                            protectedTaskIDs,
                        isMissingManagedSource: { url in
                            unavailableSourceURLs.contains(
                                url.standardizedFileURL
                            )
                        },
                        missingSourceFailure: {
                            phase,
                            taskID in
                            unavailableSourceFailures[taskID]
                            ?? BatchTaskFailure(
                                phase: phase,
                                message:
                                    "接收的照片副本已不可用。",
                                classification:
                                    .interrupted,
                                canRetry: false
                            )
                        }
                    )
                return changed
                    ? .commit(true)
                    : .unchanged(false)
            }
            guard await projectDurableTransaction(result) != nil,
                  let productionDiagnostics else {
                return
            }
            let recoveredFailures:
                [BatchQueueRecoveredFailure] =
                jobs.flatMap { job in
                    job.tasks.compactMap { task in
                        guard !existingFailureTaskIDs
                                .contains(task.id),
                              let failure = task.failure else {
                            return nil
                        }
                        return BatchQueueRecoveredFailure(
                            jobID: job.id,
                            task: task,
                            failure: failure
                        )
                    }
                }
            Task {
                await BatchQueueRecoveryDiagnosticsReporter.record(
                    recoveredFailures,
                    to: productionDiagnostics
                )
            }
        }
    }

    func unresolvedPhotoLibrarySaveTaskIDs()
    async -> Set<UUID> {
        var taskIDs = Set<UUID>()
        for task in jobs.flatMap(\.tasks)
        where task.phase == .savingToPhotoLibrary {
            if await saveReceiptLedger.hasRecoveryEvidence(
                for: task.id.uuidString
            ) {
                taskIDs.insert(task.id)
            }
        }
        return taskIDs
    }

    @discardableResult
    private func persistJobsDuringBootstrap() -> Bool {

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

    private func withDurableCommand<Value>(
        _ operation: () async -> Value
    ) async -> Value {
        await durableCommandGate.acquire()
        let value = await operation()
        await durableCommandGate.release()
        return value
    }

    private func projectDurableTransaction<Value: Sendable>(
        _ result:
            BatchQueueDurableTransactionResult<Value>
    ) async -> Value? {
        switch result {
        case .committed(let value, let snapshot):
            let previousJobs = jobs
            let retainedTaskIDs = Set(
                snapshot.jobs.flatMap(\.tasks).map(\.id)
            )
            let removedReceiptKeys = Set(
                previousJobs
                    .flatMap(\.tasks)
                    .filter {
                        !retainedTaskIDs.contains($0.id)
                    }
                    .map { $0.id.uuidString }
            )
            jobs = snapshot.jobs
            lastDurableJobs = snapshot.jobs
            persistenceBlocked = false
            isPersistenceBlocked = false
            startupPersistenceError = nil
            history.commitResourceCleanup(
                from: previousJobs,
                retaining: jobs
            )
            await saveReceiptLedger.removeReceipts(
                for: removedReceiptKeys
            )
            return value

        case .unchanged(let value, let snapshot):
            jobs = snapshot.jobs
            lastDurableJobs = snapshot.jobs
            return value

        case .failure(let error, let snapshot):
            jobs = snapshot.jobs
            lastDurableJobs = snapshot.jobs
            lastErrorMessage = error.message
            startupPersistenceError = error
            persistenceBlocked = true
            isPersistenceBlocked = true
            processingTask?.cancel()
            return nil
        }
    }

    func removePendingSaveReceipts() {
        saveReceiptStore.removeReceipts(
            for: pendingSaveReceiptRemovalKeys
        )
        pendingSaveReceiptRemovalKeys.removeAll()
    }

    func pruneBootstrapReceipts() {
        bootstrapReceiptReconciler.pruneReceipts(
            retaining: jobs
        )
    }

    func reconcileSaveReceiptsWithPersistedJobs() async {
        await saveReceiptLedger.pruneReceipts(
            retaining: Set(
                jobs
                    .flatMap(\.tasks)
                    .map { $0.id.uuidString }
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
                stage: stage
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
    ) async {

        processingTask = nil
        clearProcessingIndicators()

        if !shouldRestart {
            await normalizeJobsForResume()
        }

        if shouldRestart,
           canContinueProcessing,
           nextPendingTaskReference() != nil {
            await startProcessingIfNeeded()
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
    ) async -> Bool {
        await withDurableCommand {
            let snapshot = await durableLedger.snapshot()
            guard !snapshot.isPersistenceBlocked,
                  let task = snapshot.jobs
                    .first(where: {
                        $0.id == reference.jobID
                    })?
                    .tasks
                    .first(where: {
                        $0.id == reference.taskID
                    }),
                  task.phase.isTerminal else {
                return false
            }
            jobs = snapshot.jobs
            execution
                .cleanupManagedSourceIfNeeded(
                    at: task.sourceURL
                )
            return true
        }
    }

    @discardableResult
    func applyExecutionEvent(
        _ event: BatchTaskExecutionEvent,
        at reference:
            BatchQueueExecution.TaskReference,
        historyCoverCandidate:
            BatchJobHistoryCover? = nil
    ) async -> Bool {
        return await withDurableCommand {
            let result = await durableLedger.apply(
                event,
                at: reference,
                historyCoverCandidate:
                    historyCoverCandidate
            )
            guard let optionalMutation =
                    await projectDurableTransaction(result),
                  let mutation = optionalMutation else {
                return false
            }

            if mutation.previous.phase != .completed,
               mutation.updated.phase == .completed {
                recordSuccessfulSaveIfNeeded(
                    for: mutation.updated
                )
            }
            return true
        }
    }

    @discardableResult
    private func updateTaskDuringBootstrap(
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

        guard persistJobsDuringBootstrap() else {
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

        let outcome = commerceAccounting.recordSuccessfulSave(
            for: task,
            current: commerceSnapshot
        )
        guard !outcome.requiresRecovery else {
            lastErrorMessage = "记录使用额度时无法完成本地保存，处理已暂停。"
            persistenceBlocked = true
            isPersistenceBlocked = true
            processingTask?.cancel()
            return
        }
        guard let nextCommerceSnapshot = outcome.updatedSnapshot else {
            return
        }
        guard persistCommerceSnapshot(
            nextCommerceSnapshot,
            failureMessage: "同步使用额度时无法完成本地保存，处理已暂停。"
        ) else {
            return
        }
    }

    private func reconcileCommerceUsageWithDurableJobs() {
        let outcome = commerceAccounting.reconcile(
            completedJobs: jobs,
            current: commerceSnapshot
        )
        guard !outcome.requiresRecovery else {
            lastErrorMessage = "无法校准已完成记录的本地使用额度，处理已暂停。"
            persistenceBlocked = true
            isPersistenceBlocked = true
            processingTask?.cancel()
            return
        }
        guard let reconciledSnapshot = outcome.updatedSnapshot else {
            return
        }
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
        guard commerceAccounting.saveSharedSnapshot(snapshot) else {
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
        for jobID: UUID
    ) async {
        await withDurableCommand {
            let result = await durableLedger
                .markStartNotificationSent(
                    for: jobID
                )
            _ = await projectDurableTransaction(result)
        }
    }

    func markFinalNotificationSent(
        for jobID: UUID
    ) async {
        await withDurableCommand {
            let result = await durableLedger
                .markFinalNotificationSent(
                    for: jobID
                )
            _ = await projectDurableTransaction(result)
        }
    }

    func releaseNotificationAttachmentsIfCovered(
        for jobID: UUID
    ) async {
        await withDurableCommand {
            let result = await durableLedger
                .releaseNotificationAttachmentsIfCovered(
                    for: jobID
                )
            _ = await projectDurableTransaction(result)
        }
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
