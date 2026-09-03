#if !MEMOMARK_SHARE_EXTENSION
import Foundation

nonisolated struct BatchQueueTaskMutation:
    Sendable {

    let previous: BatchTask
    let updated: BatchTask
}

nonisolated struct BatchQueueAdmission:
    Sendable {

    let job: BatchJob
    let didInsert: Bool
}

nonisolated struct BatchQueueHistoryRemoval:
    Sendable {

    let removedTaskIDs: Set<String>

    var didChange: Bool {
        !removedTaskIDs.isEmpty
    }
}

/// Deterministic queue transition rules. This type owns no mutable queue
/// state, persistence, media work, notification, or presentation projection.
nonisolated struct BatchQueueTransitionPolicy:
    Sendable {

    @discardableResult
    func admit(
        _ job: BatchJob,
        into jobs: inout [BatchJob]
    ) -> BatchQueueAdmission {
        if let intakeRequestID = job.intakeRequestID,
           let existing = jobs.first(where: {
               $0.intakeRequestID == intakeRequestID
           }) {
            return BatchQueueAdmission(
                job: existing,
                didInsert: false
            )
        }

        jobs.insert(job, at: 0)
        return BatchQueueAdmission(
            job: job,
            didInsert: true
        )
    }

    func canRetry(
        phase: BatchTaskPhase,
        failureCanRetry: Bool?
    ) -> Bool {
        phase == .failed
        && (failureCanRetry ?? true)
    }

    func canCancel(
        phase: BatchTaskPhase
    ) -> Bool {
        !phase.isTerminal
        && phase != .savingToPhotoLibrary
    }

    @discardableResult
    func retryFailedTasks(
        in jobs: inout [BatchJob],
        jobID: UUID,
        now: Date
    ) -> Bool {
        guard let jobIndex = jobs.firstIndex(where: {
            $0.id == jobID
        }) else {
            return false
        }

        var job = jobs[jobIndex]
        var didQueueRetry = false
        for taskIndex in job.tasks.indices {
            guard canRetry(
                phase: job.tasks[taskIndex].phase,
                failureCanRetry:
                    job.tasks[taskIndex]
                    .failure?
                    .canRetry
            ) else {
                continue
            }

            job.tasks[taskIndex].phase = .queued
            job.tasks[taskIndex].failure = nil
            job.tasks[taskIndex].renderedFileURL = nil
            job.tasks[taskIndex]
                .notificationAttachmentURL = nil
            job.tasks[taskIndex].savedAlbumName = nil
            job.tasks[taskIndex].savedAssetIdentifier = nil
            job.tasks[taskIndex].progress = BatchTaskProgress()
            job.tasks[taskIndex].retryCount += 1
            didQueueRetry = true
        }

        guard didQueueRetry else {
            return false
        }
        job.updatedAt = now
        job.finalNotificationSentAt = nil
        job.state = derivedJobState(
            from: job.tasks.map(\.phase)
        )
        jobs[jobIndex] = job
        return true
    }

    @discardableResult
    func cancelJob(
        in jobs: inout [BatchJob],
        jobID: UUID,
        now: Date
    ) -> Bool {
        guard let jobIndex = jobs.firstIndex(where: {
            $0.id == jobID
        }) else {
            return false
        }

        var job = jobs[jobIndex]
        var didCancelTask = false
        for taskIndex in job.tasks.indices {
            guard canCancel(
                phase: job.tasks[taskIndex].phase
            ) else {
                continue
            }
            job.tasks[taskIndex].phase = .cancelled
            job.tasks[taskIndex].progress = BatchTaskProgress(
                currentUnit: 1,
                totalUnits: 1,
                stage: .cancelled
            )
            didCancelTask = true
        }

        guard didCancelTask else {
            return false
        }
        job.updatedAt = now
        job.state = derivedJobState(
            from: job.tasks.map(\.phase)
        )
        jobs[jobIndex] = job
        return true
    }

    @discardableResult
    func apply(
        _ event: BatchTaskExecutionEvent,
        at reference: BatchTaskReference,
        in jobs: inout [BatchJob],
        now: Date,
        historyCoverCandidate:
            BatchJobHistoryCover? = nil
    ) -> BatchQueueTaskMutation? {
        guard let jobIndex = jobs.firstIndex(where: {
            $0.id == reference.jobID
        }),
        let taskIndex = jobs[jobIndex]
            .tasks
            .firstIndex(where: {
                $0.id == reference.taskID
            }) else {
            return nil
        }

        let previousTask =
            jobs[jobIndex].tasks[taskIndex]
        guard BatchTaskExecutionTransitionPolicy()
            .canApply(
                event.transition,
                from: previousTask.phase
            ) else {
            return nil
        }

        var job = jobs[jobIndex]
        event.apply(to: &job.tasks[taskIndex])
        let updatedTask = job.tasks[taskIndex]
        job.updatedAt = now
        let lacksHistoryCover: Bool
        switch job.historyCover {
        case nil:
            lacksHistoryCover = true
        case .some:
            lacksHistoryCover = false
        }
        if lacksHistoryCover,
           let historyCoverCandidate,
           historyCoverCandidate.sourceTaskID
            == updatedTask.id {
            job.historyCover = historyCoverCandidate
        }
        job.state = derivedJobState(
            from: job.tasks.map(\.phase)
        )
        jobs[jobIndex] = job

        return BatchQueueTaskMutation(
            previous: previousTask,
            updated: updatedTask
        )
    }

    func expireActiveTask(
        at reference: BatchTaskReference,
        in jobs: inout [BatchJob],
        failure: BatchTaskFailure,
        now: Date
    ) -> Bool {
        guard let jobIndex = jobs.firstIndex(where: {
            $0.id == reference.jobID
        }),
        let taskIndex = jobs[jobIndex]
            .tasks
            .firstIndex(where: {
                $0.id == reference.taskID
            }) else {
            return false
        }

        let phase = jobs[jobIndex].tasks[taskIndex].phase
        guard !phase.isTerminal,
              phase != .savingToPhotoLibrary else {
            return false
        }

        var job = jobs[jobIndex]
        job.tasks[taskIndex].renderedFileURL = nil
        job.tasks[taskIndex]
            .notificationAttachmentURL = nil
        job.tasks[taskIndex].failure = failure
        job.tasks[taskIndex].progress = BatchTaskProgress(
            currentUnit: 0,
            totalUnits: 1,
            stage: .backgroundExpired
        )
        job.tasks[taskIndex].phase = .failed
        job.updatedAt = now
        job.state = derivedJobState(
            from: job.tasks.map(\.phase)
        )
        jobs[jobIndex] = job
        return true
    }

    func reconcileCommittedPhotoLibrarySave(
        at reference: BatchTaskReference,
        in jobs: inout [BatchJob],
        assetIdentifier: String,
        now: Date
    ) -> BatchQueueTaskMutation? {
        guard let jobIndex = jobs.firstIndex(where: {
            $0.id == reference.jobID
        }),
        let taskIndex = jobs[jobIndex]
            .tasks
            .firstIndex(where: {
                $0.id == reference.taskID
            }),
        jobs[jobIndex].tasks[taskIndex].phase
            == .savingToPhotoLibrary else {
            return nil
        }

        var job = jobs[jobIndex]
        let previous = job.tasks[taskIndex]
        job.tasks[taskIndex].renderedFileURL = nil
        job.tasks[taskIndex].savedAssetIdentifier =
            assetIdentifier
        job.tasks[taskIndex].failure = nil
        job.tasks[taskIndex].phase = .completed
        job.tasks[taskIndex].progress = BatchTaskProgress(
            currentUnit:
                job.tasks[taskIndex]
                .progress.totalUnits,
            totalUnits:
                job.tasks[taskIndex]
                .progress.totalUnits,
            stage: .completed
        )
        job.updatedAt = now
        job.state = derivedJobState(
            from: job.tasks.map(\.phase)
        )
        jobs[jobIndex] = job
        return BatchQueueTaskMutation(
            previous: previous,
            updated: job.tasks[taskIndex]
        )
    }

    func clearTerminalExternalHistory(
        in jobs: inout [BatchJob],
        preserving preservedJobID: UUID?
    ) -> BatchQueueHistoryRemoval {
        let originalJobs = jobs
        jobs = jobs.filter { job in
            if job.id == preservedJobID {
                return true
            }
            guard job.launchSource != .inAppPreview else {
                return true
            }
            return !job.tasks.allSatisfy {
                $0.phase.isTerminal
            }
        }

        let retainedJobIDs = Set(jobs.map(\.id))
        return BatchQueueHistoryRemoval(
            removedTaskIDs:
                Set(
                    originalJobs
                        .filter {
                            !retainedJobIDs.contains($0.id)
                        }
                        .flatMap(\.tasks)
                        .map {
                            $0.id.uuidString
                        }
                )
        )
    }

    func markStartNotificationSent(
        for jobID: UUID,
        in jobs: inout [BatchJob],
        at date: Date
    ) -> Bool {
        mutateJob(jobID, in: &jobs) { job in
            guard job.startNotificationSentAt == nil else {
                return false
            }
            job.startNotificationSentAt = date
            return true
        }
    }

    func markFinalNotificationSent(
        for jobID: UUID,
        in jobs: inout [BatchJob],
        at date: Date
    ) -> Bool {
        mutateJob(jobID, in: &jobs) { job in
            guard job.finalNotificationSentAt == nil else {
                return false
            }
            job.finalNotificationSentAt = date
            return true
        }
    }

    func releaseNotificationAttachmentsIfCovered(
        for jobID: UUID,
        in jobs: inout [BatchJob]
    ) -> Bool {
        mutateJob(jobID, in: &jobs) { job in
            let hasHistoryCover: Bool
            switch job.historyCover {
            case .some:
                hasHistoryCover = true
            case nil:
                hasHistoryCover = false
            }
            guard hasHistoryCover,
                  job.tasks.allSatisfy({ $0.phase.isTerminal }) else {
                return false
            }
            var changed = false
            for taskIndex in job.tasks.indices
            where job.tasks[taskIndex]
                .notificationAttachmentURL != nil {
                job.tasks[taskIndex]
                    .notificationAttachmentURL = nil
                changed = true
            }
            return changed
        }
    }

    func derivedJobState(
        from phases: [BatchTaskPhase]
    ) -> BatchJobState {
        guard !phases.isEmpty else {
            return .draft
        }
        if phases.allSatisfy({ $0 == .completed }) {
            return .completed
        }
        if phases.allSatisfy({ $0 == .cancelled }) {
            return .cancelled
        }
        if phases.contains(where: {
            $0 == .savingToPhotoLibrary
            || $0 == .exporting
        }) {
            return .running
        }
        if phases.contains(where: {
            $0 == .previewReady
            || $0 == .waitingForExport
            || $0 == .metadataReady
        }) {
            return .ready
        }
        if phases.contains(.importing) {
            return .preparing
        }
        if phases.contains(.queued) {
            return .queued
        }
        if phases.contains(.failed) {
            return .failed
        }
        return .draft
    }

    private func mutateJob(
        _ jobID: UUID,
        in jobs: inout [BatchJob],
        mutation: (inout BatchJob) -> Bool
    ) -> Bool {
        guard let jobIndex = jobs.firstIndex(where: {
            $0.id == jobID
        }) else {
            return false
        }
        var job = jobs[jobIndex]
        guard mutation(&job) else {
            return false
        }
        jobs[jobIndex] = job
        return true
    }
}
#endif
