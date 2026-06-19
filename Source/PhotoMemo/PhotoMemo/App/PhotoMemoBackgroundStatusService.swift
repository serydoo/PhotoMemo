#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Combine

enum PhotoMemoBackgroundPresentationState: Hashable {

    case active

    case needsAttention

    case completed
}

struct PhotoMemoBackgroundJobSnapshot: Hashable {

    let jobID: UUID

    let title: String

    let launchSource: BatchJobLaunchSource

    let presentationState: PhotoMemoBackgroundPresentationState

    let jobState: BatchJobState

    let currentPhase: BatchTaskPhase?

    let currentPhaseTitle: String?

    let currentFileName: String?

    let statusMessage: String

    let completedCount: Int

    let failedCount: Int

    let totalCount: Int

    let progressFraction: Double

    let canRetryFailures: Bool

    let updatedAt: Date
}

@MainActor
final class PhotoMemoBackgroundStatusService:
    ObservableObject {

    @Published private(set)
    var currentSnapshot:
        PhotoMemoBackgroundJobSnapshot?

    private let batchQueueStore:
        BatchQueueStore

    private var cancellables:
        Set<AnyCancellable> = []

    init(
        batchQueueStore: BatchQueueStore
    ) {
        self.batchQueueStore =
            batchQueueStore

        bind()
        refreshSnapshot()
    }
}
private extension PhotoMemoBackgroundStatusService {

    func bind() {

        Publishers.CombineLatest4(
            batchQueueStore.$jobs,
            batchQueueStore.$isProcessing,
            batchQueueStore.$activeJobID,
            batchQueueStore.$activeTaskID
        )
        .sink { [weak self] _, _, _, _ in
            self?.refreshSnapshot()
        }
        .store(in: &cancellables)
    }

    func refreshSnapshot() {

        currentSnapshot =
            resolvedSnapshot(
                jobs: batchQueueStore.jobs,
                activeJobID:
                    batchQueueStore.activeJobID,
                activeTaskID:
                    batchQueueStore.activeTaskID
            )
    }

    func resolvedSnapshot(
        jobs: [BatchJob],
        activeJobID: UUID?,
        activeTaskID: UUID?
    ) -> PhotoMemoBackgroundJobSnapshot? {

        let externalJobs =
            jobs
            .filter {
                $0.launchSource != .inAppPreview
            }
            .sorted {
                $0.updatedAt > $1.updatedAt
            }

        guard !externalJobs.isEmpty else {
            return nil
        }

        if let activeJobID,
           let activeJob =
            externalJobs.first(
                where: { $0.id == activeJobID }
            ) {
            return snapshot(
                for: activeJob,
                activeTaskID: activeTaskID
            )
        }

        if let runningJob =
            externalJobs.first(
                where: { job in
                    !job.tasks.allSatisfy {
                        $0.phase.isTerminal
                    }
                }
            ) {
            return snapshot(
                for: runningJob,
                activeTaskID: nil
            )
        }

        if let retryableFailureJob =
            externalJobs.first(
                where: \.hasRetryableFailures
            ) {
            return snapshot(
                for: retryableFailureJob,
                activeTaskID: nil
            )
        }

        return externalJobs.first.map {
            snapshot(
                for: $0,
                activeTaskID: nil
            )
        }
    }

    func snapshot(
        for job: BatchJob,
        activeTaskID: UUID?
    ) -> PhotoMemoBackgroundJobSnapshot {

        let activeTask =
            job.tasks.first {
                $0.id == activeTaskID
            }
            ?? job.tasks.first {
                !$0.phase.isTerminal
            }

        let presentationState =
            resolvedPresentationState(
                for: job
            )

        return PhotoMemoBackgroundJobSnapshot(
            jobID: job.id,
            title: job.title,
            launchSource: job.launchSource,
            presentationState:
                presentationState,
            jobState: job.state,
            currentPhase:
                activeTask?.phase,
            currentPhaseTitle:
                activeTask?.phase.displayTitle,
            currentFileName:
                activeTask?.fileName,
            statusMessage:
                resolvedStatusMessage(
                    for: job,
                    activeTask: activeTask
                ),
            completedCount:
                job.completedTaskCount,
            failedCount:
                job.failedTaskCount,
            totalCount:
                job.totalTaskCount,
            progressFraction:
                resolvedProgressFraction(
                    for: job,
                    activeTask: activeTask
                ),
            canRetryFailures:
                job.hasRetryableFailures,
            updatedAt: job.updatedAt
        )
    }

    func resolvedPresentationState(
        for job: BatchJob
    ) -> PhotoMemoBackgroundPresentationState {

        if !job.tasks.allSatisfy({
            $0.phase.isTerminal
        }) {
            return .active
        }

        if job.failedTaskCount > 0 {
            return .needsAttention
        }

        return .completed
    }

    func resolvedStatusMessage(
        for job: BatchJob,
        activeTask: BatchTask?
    ) -> String {

        if let activeTask,
           !activeTask.progress.statusMessage
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty {

            let baseMessage =
                activeTask.progress
                .statusMessage

            let trimmedFileName =
                activeTask.fileName
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            if trimmedFileName.isEmpty {
                return baseMessage
            }

            return "\(baseMessage) · \(trimmedFileName)"
        }

        if job.hasRetryableFailures {
            return "有失败项可在 PhotoMemo 内重试"
        }

        if job.failedTaskCount > 0 {
            return "本批有未成功处理的照片"
        }

        if job.completedTaskCount == job.totalTaskCount,
           job.totalTaskCount > 0 {
            return "本批照片已完成并写回系统相册"
        }

        switch job.state {

        case .queued:
            return "等待后台处理"

        case .preparing,
             .ready,
             .running:
            return "正在后台处理"

        case .completed:
            return "处理完成"

        case .failed:
            return "处理失败"

        case .cancelled:
            return "任务已取消"

        case .draft:
            return "等待开始"
        }
    }

    func resolvedProgressFraction(
        for job: BatchJob,
        activeTask: BatchTask?
    ) -> Double {

        guard job.totalTaskCount > 0 else {
            return 0
        }

        let completedUnits =
            job.tasks.reduce(into: 0.0) {
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
                            min(
                                task.progress
                                .fractionCompleted,
                                0.99
                            ),
                            0.05
                        )
                    }
                }
            }

        return min(
            max(
                completedUnits
                / Double(job.totalTaskCount),
                0
            ),
            1
        )
    }
}
#endif
