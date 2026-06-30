#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import ImageIO
import UniformTypeIdentifiers

@MainActor
final class BatchQueueExecution {

    struct TaskReference {

        let jobIndex: Int

        let taskIndex: Int
    }

    private let coordinator:
        BatchProcessingCoordinator

    private let externalIntakeStore:
        ExternalPhotoIntakeStore

    init(
        coordinator:
            BatchProcessingCoordinator? = nil,
        externalIntakeStore:
            ExternalPhotoIntakeStore? = nil
    ) {
        self.coordinator =
            coordinator
            ?? BatchProcessingCoordinator()
        self.externalIntakeStore =
            externalIntakeStore
            ?? .shared
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

        return BatchJob(
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
            externalIntakeStore
                .cleanupManagedSourceIfNeeded(
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

        let isRAWTask =
            taskUsesRAWDisplayRepresentation(
                initialTask
            )
        let totalProgressUnits =
            isRAWTask ? 6 : 5

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
                    isRAWTask
                    ? "正在准备 RAW 照片"
                    : "正在读取原图"
            )
            task.failure = nil
        }

        if isRAWTask,
           let jobID =
            store.currentJobID(
                at: reference
            ) {
            await store
                .deliverProgressNotificationIfNeeded(
                    for: jobID,
                    stage: "raw"
                )
        }

        var temporaryFileURL: URL?

        do {

            guard let task =
                store.currentTask(
                    at: reference
                ) else {
                return
            }

            let importedPhoto =
                try await coordinator
                .importPhoto(
                    for: task
                )

            guard !shouldAbortFurtherProcessing(
                at: reference,
                in: store
            ) else {
                return
            }

            store.updateTask(
                at: reference
            ) { task in
                task.captureDate =
                    importedPhoto.metadata.captureDate
                task.phase = .metadataReady
                task.progress = BatchTaskProgress(
                    currentUnit:
                        isRAWTask ? 3 : 2,
                    totalUnits:
                        totalProgressUnits,
                    statusMessage:
                        isRAWTask
                        ? "已生成 RAW 显示版本"
                        : "已读取 EXIF 和拍摄时间"
                )
            }

            if let jobID =
                store.currentJobID(
                    at: reference
                ) {
                await store
                    .deliverProgressNotificationIfNeeded(
                        for: jobID,
                        stage: "imported"
                    )
            }

            guard let configuration =
                store.currentJob(
                    at: reference
                )?.configuration else {
                return
            }

            let card =
                coordinator.buildCard(
                    from: importedPhoto,
                    configuration: configuration
                )

            store.updateTask(
                at: reference
            ) { task in
                task.phase = .previewReady
                task.progress = BatchTaskProgress(
                    currentUnit:
                        isRAWTask ? 4 : 3,
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
                        isRAWTask ? 5 : 4,
                    totalUnits:
                        totalProgressUnits,
                    statusMessage:
                        "正在生成图片"
                )
            }

            if let jobID =
                store.currentJobID(
                    at: reference
                ) {
                await store
                    .deliverProgressNotificationIfNeeded(
                        for: jobID,
                        stage: "rendering"
                    )
            }

            let exportedFileURL =
                try coordinator.exportCard(
                    photo: importedPhoto,
                    card: card
                )

            temporaryFileURL =
                exportedFileURL

            guard !shouldAbortFurtherProcessing(
                at: reference,
                in: store
            ) else {
                coordinator.cleanupTemporaryFile(
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
                        isRAWTask ? 6 : 5,
                    totalUnits:
                        totalProgressUnits,
                    statusMessage:
                        "正在写入系统图库"
                )
            }

            if let jobID =
                store.currentJobID(
                    at: reference
                ) {
                await store
                    .deliverProgressNotificationIfNeeded(
                        for: jobID,
                        stage: "saving"
                    )
            }

            guard !shouldAbortFurtherProcessing(
                at: reference,
                in: store
            ) else {
                coordinator.cleanupTemporaryFile(
                    at: exportedFileURL
                )
                return
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

            let notificationAttachmentURL =
                makeNotificationAttachmentIfNeeded(
                    from: exportedFileURL,
                    taskID: task.id
                )

            coordinator.cleanupTemporaryFile(
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

            cleanupManagedTaskSourceIfNeeded(
                at: reference,
                in: store
            )

            store.persistJobs()

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

            if shouldIgnoreErrorBecauseTaskEnded(
                at: reference,
                in: store
            ) {
                coordinator.cleanupTemporaryFile(
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

            coordinator.cleanupTemporaryFile(
                at: temporaryFileURL
            )

            store.updateTask(
                at: reference
            ) { task in
                let canRetry =
                    canRetryTaskAfterFailure(
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
                    canRetry: canRetry
                )
                task.progress = BatchTaskProgress(
                    currentUnit: 0,
                    totalUnits: 1,
                    statusMessage: "处理失败"
                )
            }

            preserveManagedTaskSourceForRetryIfNeeded(
                at: reference,
                in: store
            )

            store.setLastErrorMessage(
                (error as? LocalizedError)?
                .errorDescription
                ?? error.localizedDescription
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

        for jobIndex in jobs.indices.reversed() {
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

private extension BatchQueueExecution {

    func shouldAbortFurtherProcessing(
        at reference: TaskReference,
        in store: BatchQueueStore
    ) -> Bool {

        guard let phase =
            store.currentTaskPhase(
                at: reference
            ) else {
            return true
        }

        return phase.isTerminal
    }

    func shouldIgnoreErrorBecauseTaskEnded(
        at reference: TaskReference,
        in store: BatchQueueStore
    ) -> Bool {

        guard let phase =
            store.currentTaskPhase(
                at: reference
            ) else {
            return true
        }

        return phase.isTerminal
    }

    func cleanupManagedTaskSourceIfNeeded(
        at reference: TaskReference,
        in store: BatchQueueStore
    ) {

        guard let sourceURL =
            store.currentTask(
                at: reference
            )?.sourceURL else {
            return
        }

        externalIntakeStore
            .cleanupManagedSourceIfNeeded(
                at: sourceURL
            )
    }

    func makeNotificationAttachmentIfNeeded(
        from exportedFileURL: URL,
        taskID: UUID
    ) -> URL? {

        let directory =
            PhotoMemoSharedContainer
            .baseDirectoryURL
            .appendingPathComponent(
                "NotificationAttachments",
                isDirectory: true
            )

        guard PhotoMemoSharedContainer
            .ensureDirectory(
                at: directory
            ) else {
            return nil
        }

        let destinationURL =
            directory
            .appendingPathComponent(
                "\(taskID.uuidString).jpg",
                isDirectory: false
            )

        try? FileManager.default
            .removeItem(
                at: destinationURL
            )

        guard let source =
            CGImageSourceCreateWithURL(
                exportedFileURL as CFURL,
                [
                    kCGImageSourceShouldCache:
                        false
                ] as CFDictionary
            ),
              let thumbnail =
            CGImageSourceCreateThumbnailAtIndex(
                source,
                0,
                [
                    kCGImageSourceCreateThumbnailFromImageAlways:
                        true,
                    kCGImageSourceCreateThumbnailWithTransform:
                        true,
                    kCGImageSourceShouldCacheImmediately:
                        true,
                    kCGImageSourceThumbnailMaxPixelSize:
                        720
                ] as CFDictionary
            ),
              let destination =
            CGImageDestinationCreateWithURL(
                destinationURL as CFURL,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            )
        else {
            return nil
        }

        CGImageDestinationAddImage(
            destination,
            thumbnail,
            [
                kCGImageDestinationLossyCompressionQuality:
                    0.82
            ] as CFDictionary
        )

        return CGImageDestinationFinalize(
            destination
        )
        ? destinationURL
        : nil
    }

    func preserveManagedTaskSourceForRetryIfNeeded(
        at reference: TaskReference,
        in store: BatchQueueStore
    ) {

        guard let sourceURL =
            store.currentTask(
                at: reference
            )?.sourceURL else {
            return
        }

        guard isManagedIntakeSourceURL(
            sourceURL
        ) else {
            return
        }

        guard FileManager.default.fileExists(
            atPath:
                sourceURL.standardizedFileURL.path
        ) else {
            store.updateTask(
                at: reference
            ) { task in
                task.failure?.canRetry = false
            }
            return
        }
    }

    func isManagedIntakeSourceURL(
        _ url: URL
    ) -> Bool {

        url.standardizedFileURL.path.hasPrefix(
            PhotoMemoSharedContainer
            .externalIntakeDirectoryURL
            .standardizedFileURL
            .path
        )
    }

    func canRetryTaskAfterFailure(
        sourceURL: URL
    ) -> Bool {

        if isManagedIntakeSourceURL(
            sourceURL
        ) {
            return FileManager.default
                .fileExists(
                    atPath:
                        sourceURL
                        .standardizedFileURL
                        .path
                )
        }

        return true
    }

    func taskUsesRAWDisplayRepresentation(
        _ task: BatchTask
    ) -> Bool {

        let contentType =
            task.contentTypeIdentifier
            .flatMap(UTType.init)

        return PhotoProcessingInputPolicy
            .isRawContentType(contentType)
            || PhotoProcessingInputPolicy
            .isRawFileURL(task.sourceURL)
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
