#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct MemoMarkBackgroundStatusProjection {

    let textCatalog: MemoMarkBackgroundStatusTextCatalog

    func resolvedSnapshot(
        externalJobs: [BatchJob],
        activeJobID: UUID?,
        activeTaskID: UUID?,
        focusedJobID: UUID? = nil
    ) -> MemoMarkBackgroundJobSnapshot? {

        guard !externalJobs.isEmpty else {
            return nil
        }

        if let focusedJobID,
           let focusedJob = externalJobs.first(where: { $0.id == focusedJobID }) {
            return snapshot(
                for: focusedJob,
                allExternalJobs: externalJobs,
                activeTaskID: nil
            )
        }

        if let activeJobID,
           let activeJob = externalJobs.first(where: { $0.id == activeJobID }) {
            return snapshot(
                for: activeJob,
                allExternalJobs: externalJobs,
                activeTaskID: activeTaskID
            )
        }

        if let runningJob = externalJobs.first(where: { job in
            !job.tasks.allSatisfy(\.phase.isTerminal)
        }) {
            return snapshot(
                for: runningJob,
                allExternalJobs: externalJobs,
                activeTaskID: nil
            )
        }

        return externalJobs.first.map {
            snapshot(
                for: $0,
                allExternalJobs: externalJobs,
                activeTaskID: nil
            )
        }
    }

    func taskOverview(
        from jobs: [BatchJob],
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> MemoMarkBackgroundTaskOverview {
        let tasks = jobs.flatMap(\.tasks)

        return MemoMarkBackgroundTaskOverview(
            activeJobCount: jobs.filter { job in
                job.tasks.contains { !$0.phase.isTerminal }
            }.count,
            completedPhotoCount: tasks.filter {
                $0.phase == .completed
            }.count,
            failedPhotoCount: tasks.filter {
                $0.phase == .failed
            }.count,
            todayProcessingCount: jobs.filter {
                calendar.isDate(
                    $0.updatedAt,
                    inSameDayAs: now
                )
            }.count
        )
    }

    func summary(
        for job: BatchJob
    ) -> MemoMarkBackgroundJobSummary {
        MemoMarkBackgroundJobSummary(
            jobID: job.id,
            configurationName: resolvedConfigurationName(for: job),
            templateName: job.configuration.template.preset.displayName,
            presentationState: resolvedPresentationState(for: job),
            jobState: job.state,
            completedCount: job.completedTaskCount,
            failedCount: job.failedTaskCount,
            totalCount: job.totalTaskCount,
            previewSourceURL:
                resolvedHistoryPreviewURL(for: job)
                ?? job.tasks.first(where: { !$0.phase.isTerminal })?.sourceURL,
            savedAlbumName: latestSavedTask(in: job)?.savedAlbumName,
            savedAssetIdentifier: latestSavedTask(in: job)?.savedAssetIdentifier,
            updatedAt: job.updatedAt
        )
    }
}

private extension MemoMarkBackgroundStatusProjection {

    var queueProjection: MemoMarkBackgroundQueueProjection {
        MemoMarkBackgroundQueueProjection(textCatalog: textCatalog)
    }

    func snapshot(
        for job: BatchJob,
        allExternalJobs: [BatchJob],
        activeTaskID: UUID?
    ) -> MemoMarkBackgroundJobSnapshot {
        let activeTask = job.tasks.first {
            $0.id == activeTaskID
        }
        ?? job.tasks.first {
            !$0.phase.isTerminal
        }
        ?? job.tasks
            .filter { $0.failure != nil }
            .max {
                ($0.failure?.timestamp ?? .distantPast)
                < ($1.failure?.timestamp ?? .distantPast)
            }
        ?? job.tasks.first {
            $0.phase == .cancelled
        }

        let presentationState = resolvedPresentationState(for: job)

        return MemoMarkBackgroundJobSnapshot(
            jobID: job.id,
            title: textCatalog.queueDisplayTitle(for: job),
            launchSource: job.launchSource,
            presentationState: presentationState,
            jobState: job.state,
            currentPhase: activeTask?.phase,
            currentPhaseTitle: textCatalog.taskPhaseTitle(activeTask?.phase),
            currentFileName: activeTask?.fileName,
            statusMessage: resolvedStatusMessage(
                for: job,
                activeTask: activeTask
            ),
            progressStage: activeTask?.failure == nil
                ? activeTask?.progress.stage
                : nil,
            displayMode: resolvedDisplayMode(
                for: job,
                allExternalJobs: allExternalJobs
            ),
            pipelineSteps: resolvedPipelineSteps(
                for: activeTask,
                job: job
            ),
            activePipelineStepIndex: resolvedActivePipelineStepIndex(
                for: activeTask,
                job: job
            ),
            queueLines: queueProjection.queueLines(
                jobs: allExternalJobs,
                activeJobID: job.id,
                activeTaskID: activeTaskID
            ),
            overflowQueueCount: queueProjection.overflowQueueCount(
                jobs: allExternalJobs,
                activeJobID: job.id
            ),
            queuedJobCount: queueProjection.queuedJobCount(
                in: allExternalJobs,
                excluding: job.id
            ),
            completedCount: job.completedTaskCount,
            failedCount: job.failedTaskCount,
            totalCount: job.totalTaskCount,
            progressFraction: resolvedProgressFraction(
                for: job,
                activeTask: activeTask
            ),
            canRetryFailures: job.hasRetryableFailures,
            hasOnlyUnsupportedFailures: job.hasOnlyUnsupportedFailures,
            updatedAt: job.updatedAt,
            configurationName: resolvedConfigurationName(for: job),
            templateName: job.configuration.template.preset.displayName,
            previewSourceURL:
                activeTask?.sourceURL
                ?? resolvedHistoryPreviewURL(for: job)
                ?? job.tasks.first(where: { !$0.phase.isTerminal })?.sourceURL,
            savedAlbumName: latestSavedTask(in: job)?.savedAlbumName,
            savedAssetIdentifier: latestSavedTask(in: job)?.savedAssetIdentifier
        )
    }

    func latestSavedTask(
        in job: BatchJob
    ) -> BatchTask? {
        job.tasks
            .filter {
                $0.savedAssetIdentifier != nil
                || $0.savedAlbumName != nil
            }
            .sorted {
                $0.createdAt > $1.createdAt
            }
            .first
    }

    func resolvedHistoryPreviewURL(
        for job: BatchJob,
        fileManager: FileManager = .default
    ) -> URL? {
        if let cover = job.historyCover,
           let coverURL = BatchTaskResourceLifecycle.historyCoverURL(for: cover),
           fileManager.fileExists(atPath: coverURL.path) {
            return coverURL
        }

        return job.tasks.first(where: { task in
            guard task.phase == .completed,
                  let url = task.notificationAttachmentURL else {
                return false
            }
            return fileManager.fileExists(atPath: url.path)
        })?.notificationAttachmentURL
    }

    func resolvedConfigurationName(
        for job: BatchJob
    ) -> String {
        let trimmedName = job.configuration.template.name
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return trimmedName.isEmpty
            ? job.configuration.template.preset.displayName
            : trimmedName
    }

    func resolvedDisplayMode(
        for job: BatchJob,
        allExternalJobs: [BatchJob]
    ) -> MemoMarkBackgroundDisplayMode {
        if job.totalTaskCount <= 1 {
            return .singleTask
        }

        let activeOrWaitingJobs = allExternalJobs.filter {
            !$0.tasks.allSatisfy(\.phase.isTerminal)
            || $0.hasRetryableFailures
            || $0.failedTaskCount > 0
        }

        return activeOrWaitingJobs.count >= 4
            ? .aggregate
            : .queueLines
    }

    func resolvedPresentationState(
        for job: BatchJob
    ) -> MemoMarkBackgroundPresentationState {
        if !job.tasks.allSatisfy(\.phase.isTerminal) {
            return .active
        }

        if job.failedTaskCount > 0
            || job.tasks.contains(where: { $0.phase == .cancelled }) {
            return .needsAttention
        }

        return .completed
    }

    func resolvedStatusMessage(
        for job: BatchJob,
        activeTask: BatchTask?
    ) -> String {
        textCatalog.statusMessage(
            for: job,
            activeTask: activeTask,
            feedbackState: resolvedFeedbackState(for: job)
        )
    }

    func resolvedFeedbackState(
        for job: BatchJob
    ) -> MemoMarkBackgroundFeedbackState {
        if !job.tasks.allSatisfy(\.phase.isTerminal) {
            switch job.state {
            case .draft,
                 .queued,
                 .preparing:
                return .preparing
            case .ready,
                 .running,
                 .completed,
                 .failed,
                 .cancelled:
                return .processing
            }
        }

        if job.hasOnlyUnsupportedFailures,
           job.completedTaskCount == 0 {
            return .unsupported
        }

        if job.failedTaskCount > 0,
           job.completedTaskCount > 0 {
            return .partialSuccess
        }

        if job.failedTaskCount > 0
            || job.tasks.contains(where: { $0.phase == .cancelled }) {
            return .needsAttention
        }

        return .completed
    }

    func resolvedProgressFraction(
        for job: BatchJob,
        activeTask: BatchTask?
    ) -> Double {
        guard job.totalTaskCount > 0 else {
            return 0
        }

        let completedUnits = job.tasks.reduce(into: 0.0) {
            partialResult,
            task in

            switch task.phase {
            case .completed,
                 .failed,
                 .cancelled:
                partialResult += 1
            case .queued:
                break
            case .importing,
                 .metadataReady,
                 .previewReady,
                 .waitingForExport,
                 .exporting,
                 .savingToPhotoLibrary:
                if task.id == activeTask?.id {
                    partialResult += max(
                        min(task.progress.fractionCompleted, 0.99),
                        0.05
                    )
                }
            }
        }

        return min(
            max(
                completedUnits / Double(job.totalTaskCount),
                0
            ),
            1
        )
    }

    func resolvedPipelineSteps(
        for activeTask: BatchTask?,
        job: BatchJob
    ) -> [MemoMarkBackgroundPipelineStep] {
        let titles = textCatalog.pipelineTitles
        let activeIndex = resolvedActivePipelineStepIndex(
            for: activeTask,
            job: job
        )

        return titles.indices.map { index in
            MemoMarkBackgroundPipelineStep(
                title: titles[index],
                state: pipelineStepState(
                    index: index,
                    activeIndex: activeIndex,
                    activeTask: activeTask,
                    job: job
                )
            )
        }
    }

    func resolvedActivePipelineStepIndex(
        for activeTask: BatchTask?,
        job: BatchJob
    ) -> Int {
        if job.completedTaskCount == job.totalTaskCount,
           job.failedTaskCount == 0,
           job.totalTaskCount > 0 {
            return 4
        }

        if let failurePhase = activeTask?.failure?.phase {
            return pipelineIndex(for: failurePhase)
        }

        guard let activeTask else {
            return 0
        }

        return pipelineIndex(for: activeTask.phase)
    }

    func pipelineStepState(
        index: Int,
        activeIndex: Int,
        activeTask: BatchTask?,
        job: BatchJob
    ) -> MemoMarkBackgroundPipelineStepState {
        if activeTask?.phase == .failed
            || activeTask?.phase == .cancelled
            || job.failedTaskCount > 0,
           index == activeIndex {
            return .needsAttention
        }

        if job.completedTaskCount == job.totalTaskCount,
           job.failedTaskCount == 0,
           job.totalTaskCount > 0 {
            return .completed
        }

        if index < activeIndex {
            return .completed
        }

        if index == activeIndex {
            return .active
        }

        return .pending
    }

    func pipelineIndex(
        for phase: BatchTaskPhase
    ) -> Int {
        switch phase {
        case .queued:
            return 0
        case .importing,
             .metadataReady:
            return 1
        case .previewReady,
             .waitingForExport,
             .exporting:
            return 2
        case .savingToPhotoLibrary:
            return 3
        case .completed:
            return 4
        case .failed:
            return 2
        case .cancelled:
            return 0
        }
    }
}
#endif
