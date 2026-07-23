#if !PHOTOMEMO_SHARE_EXTENSION
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
        PhotoMemoError?

    @Published private(set) var defaultConfigurationSnapshot:
        BatchConfigurationSnapshot

    @Published private(set) var commerceSnapshot:
        MemoMarkCommerceSnapshot

    private let settingsService:
        SettingsService

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

    private var processingTask:
        Task<Void, Never>?

    private var persistenceBlocked = false

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
        renderHealthValidator: @escaping
            @MainActor (RecordCard, BatchConfigurationSnapshot) throws -> [CardTextBlock] =
                ProductionRenderHealthCheck.validate
    ) {
        let resolvedDefaults =
            defaults
            ?? PhotoMemoSharedContainer
            .sharedUserDefaults
        let resolvedSettingsService =
            settingsService
            ?? SettingsService()
        let resolvedExternalIntakeStore =
            externalIntakeStore
            ?? .shared

        self.settingsService =
            resolvedSettingsService
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
                diagnosticsDefaults:
                    resolvedDefaults,
                renderHealthValidator:
                    renderHealthValidator
            )
        self.persistence =
            BatchQueuePersistence(
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
        self.commerceSnapshot =
            self.commercePersistence
            .loadSharedSnapshot()
        self.defaultConfigurationSnapshot =
            resolvedSettingsService
            .buildBatchConfigurationSnapshot()

        self.startupPersistenceError = nil

        switch persistence.loadPersistedJobsResult() {
        case .success(let loadedJobs):
            jobs = loadedJobs
        case .failure(let error):
            jobs = []
            startupPersistenceError = error
            lastErrorMessage = error.message
            persistenceBlocked = true
        }

        guard !persistenceBlocked else {
            return
        }

        normalizeJobsForResume()
        startProcessingIfNeeded()
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
        title: String? = nil
    ) -> BatchJob? {

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
                ? "免费成长记录额度已使用完，请在时光记中了解 MemoMark+。"
                : "当前一次最多可以加入 \(maximumAdmissionCount) 张照片。"
            return nil
        }

        guard let job =
            execution.enqueue(
                payloads: payloads,
                configuration: configuration,
                launchSource: launchSource,
                intakeSummary:
                    intakeSummary,
                title: title
            )
        else {
            return nil
        }

        jobs.insert(job, at: 0)
        persistJobs()
        scheduleStartNotificationIfNeeded(
            for: job.id
        )
        startProcessingIfNeeded()
        return job
    }

    func updateCommerceSnapshot(
        _ snapshot: MemoMarkCommerceSnapshot
    ) {
        commerceSnapshot = snapshot
        commercePersistence
            .saveSharedSnapshot(snapshot)
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
                    ? "免费成长记录额度已使用完，请在时光记中了解 MemoMark+。"
                    : "当前剩余额度可重试 \(maximumAdmissionCount) 张照片。"
            }
            return
        }

        guard execution.retryFailedTasks(
            in: &jobs,
            jobID: jobID
        ) else {
            return
        }

        persistJobs()
        startProcessingIfNeeded()
    }

    func cancelJob(
        _ jobID: UUID
    ) {

        guard execution.cancelJob(
            in: &jobs,
            jobID: jobID
        ) else {
            return
        }

        persistJobs()
    }

    func startProcessingIfNeeded() {

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

    func retryPersistence() {

        guard persistenceBlocked else {
            return
        }

        switch persistence.loadPersistedJobsResult() {
        case .success:
            if let error = persistence.persistJobs(jobs).error {
                startupPersistenceError = error
                lastErrorMessage = error.message
                return
            }

            persistenceBlocked = false
            startupPersistenceError = nil
            lastErrorMessage = ""
            startProcessingIfNeeded()
        case .failure(let error):
            startupPersistenceError = error
            lastErrorMessage = error.message
        }
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

        let originalCount =
            jobs.count

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

        persistJobs()
    }
}

// MARK: - Internal Coordination

extension BatchQueueStore {

    func nextPendingTaskReference()
    -> BatchQueueExecution.TaskReference? {

        execution.nextPendingTaskReference(
            in: jobs
        )
    }

    func normalizeJobsForResume() {

        guard persistence.normalizeJobsForResume(
            &jobs,
            deriveJobState:
                execution.derivedJobState
        ) else {
            return
        }

        persistJobs()
    }

    func persistJobs() {

        guard !persistenceBlocked else {
            return
        }

        history.trimTerminalJobHistoryIfNeeded(
            &jobs
        )

        if let error = persistence.persistJobs(jobs).error {
            lastErrorMessage = error.message
            persistenceBlocked = true
        }
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

    func processingLoopDidFinish() {

        processingTask = nil
        clearProcessingIndicators()

        if nextPendingTaskReference() != nil {
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

    func updateTask(
        at reference:
            BatchQueueExecution.TaskReference,
        persist: Bool = true,
        mutate: (inout BatchTask) -> Void
    ) {

        guard let jobIndex = jobs.firstIndex(where: { $0.id == reference.jobID }),
              let taskIndex = jobs[jobIndex].tasks.firstIndex(where: { $0.id == reference.taskID }) else {
            return
        }

        var job = jobs[jobIndex]
        let previousTask =
            job.tasks[taskIndex]
        mutate(&job.tasks[taskIndex])
        let updatedTask =
            job.tasks[taskIndex]
        job.updatedAt = Date()
        job.state =
            execution.derivedJobState(
                from: job.tasks
            )
        jobs[jobIndex] = job

        if previousTask.phase != .completed,
           updatedTask.phase == .completed,
           updatedTask.savedAssetIdentifier != nil,
           !commerceSnapshot.isPlus,
           commercePersistence
            .recordSuccessfulSave(
                taskID: updatedTask.id,
                environment:
                    commerceSnapshot.environment
            ) {
            let bonus =
                commercePersistence
                .bonusAllowance(
                    environment:
                        commerceSnapshot.environment
                )
            commerceSnapshot =
                MemoMarkCommerceSnapshot(
                    environment:
                        commerceSnapshot.environment,
                    isPlus: false,
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
            commercePersistence
                .saveSharedSnapshot(
                    commerceSnapshot
                )
        }

        guard persist else {
            return
        }

        persistJobs()
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
}
#endif
