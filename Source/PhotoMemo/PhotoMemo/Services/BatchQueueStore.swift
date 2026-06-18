import Foundation
import Combine

@MainActor
final class BatchQueueStore: ObservableObject {

    @Published private(set) var jobs: [BatchJob] = []

    @Published private(set) var isProcessing = false

    @Published private(set) var activeJobID: UUID?

    @Published private(set) var activeTaskID: UUID?

    @Published private(set) var lastErrorMessage = ""

    @Published private(set) var defaultConfigurationSnapshot:
        BatchConfigurationSnapshot

    private let storageKey =
        "photomemo.batchQueue.jobs"

    private let settingsService:
        SettingsService

    private let coordinator:
        BatchProcessingCoordinator

    private let notificationService:
        BatchNotificationService

    private var processingTask:
        Task<Void, Never>?

    init() {
        self.settingsService =
            SettingsService()
        self.coordinator =
            BatchProcessingCoordinator()
        self.notificationService =
            BatchNotificationService()
        self.defaultConfigurationSnapshot =
            settingsService
            .buildBatchConfigurationSnapshot()

        loadPersistedJobs()
        normalizeJobsForResume()
        startProcessingIfNeeded()
    }

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
        title: String? = nil
    ) -> BatchJob? {

        guard !payloads.isEmpty else {
            return nil
        }

        let tasks = payloads.map {
            BatchTask(
                sourceURL: $0.sourceURL,
                createdAt: $0.requestedAt
            )
        }

        let job = BatchJob(
            title:
                resolvedJobTitle(
                    customTitle: title,
                    taskCount: tasks.count
                ),
            state: .queued,
            launchSource: launchSource,
            configuration: configuration,
            tasks: tasks
        )

        jobs.insert(job, at: 0)
        persistJobs()
        scheduleStartNotificationIfNeeded(
            for: job.id
        )
        startProcessingIfNeeded()
        return job
    }

    func retryFailedTasks(
        in jobID: UUID
    ) {

        guard let jobIndex =
            jobs.firstIndex(
                where: { $0.id == jobID }
            ) else {
            return
        }

        var job = jobs[jobIndex]

        for index in job.tasks.indices {
            guard job.tasks[index].phase == .failed else {
                continue
            }

            job.tasks[index].phase = .queued
            job.tasks[index].failure = nil
            job.tasks[index].renderedFileURL = nil
            job.tasks[index].savedAlbumName = nil
            job.tasks[index].savedAssetIdentifier = nil
            job.tasks[index].progress = BatchTaskProgress()
            job.tasks[index].retryCount += 1
        }

        job.updatedAt = Date()
        job.finalNotificationSentAt = nil
        job.state = derivedJobState(
            from: job.tasks
        )
        jobs[jobIndex] = job

        persistJobs()
        startProcessingIfNeeded()
    }

    func cancelJob(
        _ jobID: UUID
    ) {

        guard let jobIndex =
            jobs.firstIndex(
                where: { $0.id == jobID }
            ) else {
            return
        }

        var job = jobs[jobIndex]

        for index in job.tasks.indices {
            guard !job.tasks[index].phase.isTerminal else {
                continue
            }

            job.tasks[index].phase = .cancelled
            job.tasks[index].progress =
                BatchTaskProgress(
                    currentUnit: 1,
                    totalUnits: 1,
                    statusMessage: "已取消"
                )
        }

        job.updatedAt = Date()
        job.state = .cancelled
        jobs[jobIndex] = job
        persistJobs()
    }

    func startProcessingIfNeeded() {

        guard processingTask == nil else {
            return
        }

        guard nextPendingTaskReference() != nil else {
            isProcessing = false
            activeJobID = nil
            activeTaskID = nil
            return
        }

        processingTask = Task { @MainActor in
            await processingLoop()
        }
    }

    var usageSnapshot: BatchUsageSnapshot {

        let completedTasks =
            jobs.flatMap(\.tasks).filter {
                $0.phase == .completed
            }

        let failedTasks =
            jobs.flatMap(\.tasks).filter {
                $0.phase == .failed
            }

        let activeTasks =
            jobs.flatMap(\.tasks).filter {
                !$0.phase.isTerminal
            }

        let completedBatchCount =
            jobs.filter {
                $0.completedTaskCount > 0
            }.count

        var templateCounts:
            [String: Int] = [:]

        var anchorCounts:
            [String: Int] = [:]

        for job in jobs {
            let completedCount =
                job.tasks.filter {
                    $0.phase == .completed
                }.count

            guard completedCount > 0 else {
                continue
            }

            templateCounts[
                job.configuration.template.name
            ] = (
                templateCounts[
                    job.configuration.template.name
                ] ?? 0
            ) + completedCount

            if let anchorTitle =
                job.configuration.anchor?.title
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
               !anchorTitle.isEmpty {
                anchorCounts[anchorTitle] = (
                    anchorCounts[anchorTitle] ?? 0
                ) + completedCount
            }
        }

        let templateChampion =
            templateCounts.max {
                $0.value < $1.value
            }
            .map {
                BatchUsageLeaderboardEntry(
                    title: $0.key,
                    count: $0.value
                )
            }

        let anchorChampion =
            anchorCounts.max {
                $0.value < $1.value
            }
            .map {
                BatchUsageLeaderboardEntry(
                    title: $0.key,
                    count: $0.value
                )
            }

        let lastCompletedAt =
            jobs.flatMap { job in
                job.tasks.compactMap { task in
                    task.phase == .completed
                    ? job.updatedAt
                    : nil
                }
            }
            .max()

        return BatchUsageSnapshot(
            completedPhotoCount:
                completedTasks.count,
            completedBatchCount:
                completedBatchCount,
            failedPhotoCount:
                failedTasks.count,
            activePhotoCount:
                activeTasks.count,
            templateChampion:
                templateChampion,
            anchorChampion:
                anchorChampion,
            lastCompletedAt:
                lastCompletedAt
        )
    }

    var latestFailureSummary:
        BatchFailureSummary? {

        jobs
            .filter {
                $0.failedTaskCount > 0
            }
            .sorted {
                $0.updatedAt > $1.updatedAt
            }
            .compactMap { job in

                guard let latestFailure =
                    job.latestFailure
                else {
                    return nil
                }

                return BatchFailureSummary(
                    jobID: job.id,
                    jobTitle: job.title,
                    failedTaskCount:
                        job.failedTaskCount,
                    latestFailure:
                        latestFailure,
                    updatedAt: job.updatedAt
                )
            }
            .first
    }

    var recentFailureRecords:
        [BatchFailureRecord] {

        jobs.flatMap { job in
            job.tasks.compactMap { task in

                guard let failure = task.failure else {
                    return nil
                }

                return BatchFailureRecord(
                    id:
                        "\(job.id.uuidString)-\(task.id.uuidString)-\(failure.timestamp.timeIntervalSince1970)",
                    jobID: job.id,
                    jobTitle: job.title,
                    taskID: task.id,
                    fileName: task.fileName,
                    retryCount: task.retryCount,
                    failure: failure
                )
            }
        }
        .sorted {
            $0.failure.timestamp
            > $1.failure.timestamp
        }
    }

    var latestExternalIntakeSummary:
        ExternalIntakeSummary? {

        jobs
            .filter {
                $0.launchSource != .inAppPreview
            }
            .sorted {
                $0.updatedAt > $1.updatedAt
            }
            .first
            .map { job in

                let trimmedTemplateName =
                    job.configuration.template.name
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                let templateName =
                    trimmedTemplateName.isEmpty
                    ? job.configuration
                        .template.preset.displayName
                    : trimmedTemplateName

                let trimmedAnchorTitle =
                    job.configuration.anchor?.title
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ) ?? ""

                return ExternalIntakeSummary(
                    jobID: job.id,
                    title: job.title,
                    launchSource:
                        job.launchSource,
                    taskCount:
                        job.totalTaskCount,
                    state: job.state,
                    templateName:
                        templateName,
                    anchorTitle:
                        trimmedAnchorTitle.isEmpty
                        ? nil
                        : trimmedAnchorTitle,
                    updatedAt: job.updatedAt
                )
            }
    }

    func retryLatestFailedTasks() {

        guard let latestFailureSummary else {
            return
        }

        retryFailedTasks(
            in: latestFailureSummary.jobID
        )
    }
}

private extension BatchQueueStore {

    struct TaskReference {

        let jobIndex: Int

        let taskIndex: Int
    }

    func processingLoop() async {

        isProcessing = true

        defer {
            processingTask = nil
            isProcessing = false
            activeJobID = nil
            activeTaskID = nil

            if nextPendingTaskReference() != nil {
                startProcessingIfNeeded()
            }
        }

        while let reference =
            nextPendingTaskReference() {

            await processTask(
                at: reference
            )
        }
    }

    func processTask(
        at reference: TaskReference
    ) async {

        guard jobs.indices.contains(reference.jobIndex),
              jobs[reference.jobIndex].tasks.indices.contains(reference.taskIndex) else {
            return
        }

        activeJobID =
            jobs[reference.jobIndex].id
        activeTaskID =
            jobs[reference.jobIndex]
            .tasks[reference.taskIndex].id

        updateTask(
            at: reference
        ) { task in
            task.phase = .importing
            task.progress = BatchTaskProgress(
                currentUnit: 1,
                totalUnits: 5,
                statusMessage: "正在读取原图"
            )
            task.failure = nil
        }

        var temporaryFileURL: URL?

        do {

            let importedPhoto =
                try await coordinator
                .importPhoto(
                    for: jobs[reference.jobIndex]
                        .tasks[reference.taskIndex]
                )

            updateTask(
                at: reference
            ) { task in
                task.captureDate =
                    importedPhoto.metadata.captureDate
                task.phase = .metadataReady
                task.progress = BatchTaskProgress(
                    currentUnit: 2,
                    totalUnits: 5,
                    statusMessage:
                        "已读取 EXIF 和拍摄时间"
                )
            }

            let configuration =
                jobs[reference.jobIndex]
                .configuration

            let card =
                coordinator.buildCard(
                    from: importedPhoto,
                    configuration: configuration
                )

            updateTask(
                at: reference
            ) { task in
                task.phase = .previewReady
                task.progress = BatchTaskProgress(
                    currentUnit: 3,
                    totalUnits: 5,
                    statusMessage:
                        "已生成模板内容"
                )
            }

            updateTask(
                at: reference
            ) { task in
                task.phase = .exporting
                task.progress = BatchTaskProgress(
                    currentUnit: 4,
                    totalUnits: 5,
                    statusMessage:
                        "正在生成图片"
                )
            }

            let exportedFileURL =
                try coordinator.exportCard(
                    photo: importedPhoto,
                    card: card
                )

            temporaryFileURL =
                exportedFileURL

            updateTask(
                at: reference
            ) { task in
                task.renderedFileURL =
                    exportedFileURL
                task.phase = .savingToPhotoLibrary
                task.progress = BatchTaskProgress(
                    currentUnit: 5,
                    totalUnits: 5,
                    statusMessage:
                        "正在写入系统图库"
                )
            }

            let saveResult =
                try await coordinator
                .saveRenderedPhoto(
                    at: exportedFileURL,
                    metadata:
                        importedPhoto.metadata,
                    preferredAlbumIdentifier:
                        configuration
                        .selectedAlbumIdentifier
                )

            coordinator.cleanupTemporaryFile(
                at: exportedFileURL
            )

            updateTask(
                at: reference
            ) { task in
                task.renderedFileURL = nil
                task.savedAlbumName =
                    saveResult.albumTitle
                task.savedAssetIdentifier =
                    saveResult.assetLocalIdentifier
                task.phase = .completed
                task.progress = BatchTaskProgress(
                    currentUnit: 5,
                    totalUnits: 5,
                    statusMessage: "处理完成"
                )
            }

            persistJobs()
            await deliverFinalNotificationIfNeeded(
                for: jobs[reference.jobIndex].id
            )

        } catch {

            let failurePhase =
                jobs[reference.jobIndex]
                .tasks[reference.taskIndex].phase

            coordinator.cleanupTemporaryFile(
                at: temporaryFileURL
            )

            updateTask(
                at: reference
            ) { task in
                task.renderedFileURL = nil
                task.phase = .failed
                task.failure = BatchTaskFailure(
                    phase: failurePhase,
                    message:
                        (error as? LocalizedError)?
                        .errorDescription
                        ?? error.localizedDescription
                )
                task.progress = BatchTaskProgress(
                    currentUnit: 0,
                    totalUnits: 1,
                    statusMessage: "处理失败"
                )
            }

            lastErrorMessage =
                (error as? LocalizedError)?
                .errorDescription
                ?? error.localizedDescription

            await deliverFinalNotificationIfNeeded(
                for: jobs[reference.jobIndex].id
            )
        }
    }

    func updateTask(
        at reference: TaskReference,
        mutate: (inout BatchTask) -> Void
    ) {

        guard jobs.indices.contains(reference.jobIndex),
              jobs[reference.jobIndex].tasks.indices.contains(reference.taskIndex) else {
            return
        }

        var job = jobs[reference.jobIndex]
        mutate(&job.tasks[reference.taskIndex])
        job.updatedAt = Date()
        job.state = derivedJobState(
            from: job.tasks
        )
        jobs[reference.jobIndex] = job
        persistJobs()
    }

    func nextPendingTaskReference() -> TaskReference? {

        for jobIndex in jobs.indices.reversed() {
            let job = jobs[jobIndex]

            for taskIndex in job.tasks.indices {
                if job.tasks[taskIndex].phase == .queued {
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

    func resolvedJobTitle(
        customTitle: String?,
        taskCount: Int
    ) -> String {

        let trimmedTitle =
            customTitle?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        if !trimmedTitle.isEmpty {
            return trimmedTitle
        }

        let formatter =
            DateFormatter()
        formatter.locale =
            Locale(identifier: "zh_CN")
        formatter.dateFormat =
            "yyyy.MM.dd HH:mm"

        return "PhotoMemo 后台任务 \(formatter.string(from: Date())) · \(taskCount)张"
    }

    func scheduleStartNotificationIfNeeded(
        for jobID: UUID
    ) {

        Task { @MainActor [weak self] in
            await self?
                .deliverStartNotificationIfNeeded(
                    for: jobID
                )
        }
    }

    func deliverStartNotificationIfNeeded(
        for jobID: UUID
    ) async {

        guard let jobIndex =
            jobs.firstIndex(
                where: { $0.id == jobID }
            ) else {
            return
        }

        let job = jobs[jobIndex]

        guard job.startNotificationSentAt == nil else {
            return
        }

        let didSend =
            await notificationService
            .notifyJobQueued(job)

        guard didSend else {
            return
        }

        jobs[jobIndex]
            .startNotificationSentAt =
            Date()
        persistJobs()
    }

    func deliverFinalNotificationIfNeeded(
        for jobID: UUID
    ) async {

        guard let jobIndex =
            jobs.firstIndex(
                where: { $0.id == jobID }
            ) else {
            return
        }

        let job = jobs[jobIndex]

        guard job.finalNotificationSentAt == nil else {
            return
        }

        guard shouldSendFinalNotification(
            for: job
        ) else {
            return
        }

        let didSend =
            await notificationService
            .notifyJobFinished(job)

        guard didSend else {
            return
        }

        jobs[jobIndex]
            .finalNotificationSentAt =
            Date()
        persistJobs()
    }

    func shouldSendFinalNotification(
        for job: BatchJob
    ) -> Bool {

        guard job.tasks.allSatisfy({
            $0.phase.isTerminal
        }) else {
            return false
        }

        guard job.state != .cancelled else {
            return false
        }

        return job.completedTaskCount > 0
            || job.failedTaskCount > 0
    }

    func normalizeJobsForResume() {

        var changed = false

        for jobIndex in jobs.indices {
            for taskIndex in jobs[jobIndex].tasks.indices {
                let phase =
                    jobs[jobIndex].tasks[taskIndex].phase

                guard !phase.isTerminal else {
                    continue
                }

                jobs[jobIndex].tasks[taskIndex].phase =
                    .queued
                jobs[jobIndex].tasks[taskIndex]
                    .renderedFileURL = nil
                jobs[jobIndex].tasks[taskIndex]
                    .progress = BatchTaskProgress(
                        currentUnit: 0,
                        totalUnits: 1,
                        statusMessage:
                            "等待恢复处理"
                    )
                changed = true
            }

            jobs[jobIndex].state =
                derivedJobState(
                    from: jobs[jobIndex].tasks
                )
        }

        if changed {
            persistJobs()
        }
    }

    func loadPersistedJobs() {

        guard
            let data = UserDefaults.standard.data(
                forKey: storageKey
            ),
            let decodedJobs =
                try? JSONDecoder().decode(
                    [BatchJob].self,
                    from: data
                )
        else {
            return
        }

        jobs = decodedJobs
    }

    func persistJobs() {

        guard let data =
            try? JSONEncoder().encode(
                jobs
            ) else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: storageKey
        )
    }
}
