#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Combine
import UniformTypeIdentifiers

enum PhotoMemoQueueDisplayFormatter {

    static func title(
        startedAt: Date,
        photoCount: Int,
        now: Date = Date()
    ) -> String {

        let count =
            max(photoCount, 0)
        let formatter =
            DateFormatter()
        formatter.locale =
            Locale(identifier: "zh_CN")

        let calendar =
            Calendar.current

        if calendar.isDate(
            startedAt,
            inSameDayAs:
                now
        ) {
            formatter.dateFormat =
                "HH:mm"
        } else if let yesterday =
            calendar.date(
                byAdding: .day,
                value: -1,
                to: now
            ),
            calendar.isDate(
                startedAt,
                inSameDayAs:
                    yesterday
            ) {
            formatter.dateFormat =
                "HH:mm"
            return "昨天 \(formatter.string(from: startedAt))（\(count)张）"
        } else if calendar.component(
            .year,
            from: startedAt
        ) == calendar.component(
            .year,
            from: now
        ) {
            formatter.dateFormat =
                "M月d日 HH:mm"
        } else {
            formatter.dateFormat =
                "yyyy年M月d日 HH:mm"
        }

        return "\(formatter.string(from: startedAt))（\(count)张）"
    }
}

enum PhotoMemoBackgroundPresentationState: Hashable {

    case active

    case needsAttention

    case completed
}

enum PhotoMemoBackgroundDisplayMode: String, Hashable {

    case singleTask

    case queueLines

    case aggregate
}

enum PhotoMemoBackgroundFeedbackState:
    String,
    Hashable {

    case preparing

    case processing

    case completed

    case partialSuccess

    case needsAttention

    case unsupported

    var displayTitle: String {

        switch self {
        case .preparing:
            return "准备中"
        case .processing:
            return "处理中"
        case .completed:
            return "已完成"
        case .partialSuccess:
            return "部分完成"
        case .needsAttention:
            return "需处理"
        case .unsupported:
            return "暂不支持"
        }
    }
}

enum PhotoMemoBackgroundPipelineStepState: Hashable {

    case pending

    case active

    case completed

    case needsAttention
}

struct PhotoMemoBackgroundPipelineStep: Hashable {

    let title: String

    let state: PhotoMemoBackgroundPipelineStepState
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

    let displayMode: PhotoMemoBackgroundDisplayMode

    let pipelineSteps: [PhotoMemoBackgroundPipelineStep]

    let activePipelineStepIndex: Int

    let queueLines: [String]

    let overflowQueueCount: Int

    let completedCount: Int

    let failedCount: Int

    let totalCount: Int

    let progressFraction: Double

    let canRetryFailures: Bool

    let hasOnlyUnsupportedFailures: Bool

    let updatedAt: Date

    var feedbackState:
        PhotoMemoBackgroundFeedbackState {

        switch presentationState {
        case .active:
            switch jobState {
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
        case .needsAttention:
            if hasOnlyUnsupportedFailures,
               completedCount == 0 {
                return .unsupported
            }

            if failedCount > 0,
               completedCount > 0 {
                return .partialSuccess
            }

            return .needsAttention
        case .completed:
            return .completed
        }
    }
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

    func clearCompletedHistory(
        preservingCurrentJob: Bool = true
    ) {

        let preservedJobID =
            preservingCurrentJob
            && currentSnapshot?
                .presentationState == .active
            ? currentSnapshot?.jobID
            : nil

        batchQueueStore
            .clearTerminalExternalJobHistory(
                preserving: preservedJobID
            )

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
                allExternalJobs:
                    externalJobs,
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
                allExternalJobs:
                    externalJobs,
                activeTaskID: nil
            )
        }

        return externalJobs.first.map {
            snapshot(
                for: $0,
                allExternalJobs:
                    externalJobs,
                activeTaskID: nil
            )
        }
    }

    func snapshot(
        for job: BatchJob,
        allExternalJobs: [BatchJob],
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
            title:
                queueDisplayTitle(
                    for: job
                ),
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
            displayMode:
                resolvedDisplayMode(
                    for: job,
                    allExternalJobs:
                        allExternalJobs
                ),
            pipelineSteps:
                resolvedPipelineSteps(
                    for: activeTask,
                    job: job
                ),
            activePipelineStepIndex:
                resolvedActivePipelineStepIndex(
                    for: activeTask,
                    job: job
                ),
            queueLines:
                resolvedQueueLines(
                    jobs: allExternalJobs,
                    activeJobID:
                        job.id,
                    activeTaskID:
                        activeTaskID
                ),
            overflowQueueCount:
                max(
                    displayableQueueJobs(
                        from: allExternalJobs,
                        activeJobID:
                            job.id
                    ).count - 3,
                    0
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
            hasOnlyUnsupportedFailures:
                job.hasOnlyUnsupportedFailures,
            updatedAt: job.updatedAt
        )
    }

    func resolvedDisplayMode(
        for job: BatchJob,
        allExternalJobs: [BatchJob]
    ) -> PhotoMemoBackgroundDisplayMode {

        if job.totalTaskCount <= 1 {
            return .singleTask
        }

        let activeOrWaitingJobs =
            allExternalJobs.filter {
                !$0.tasks.allSatisfy {
                    $0.phase.isTerminal
                }
                || $0.hasRetryableFailures
                || $0.failedTaskCount > 0
            }

        if activeOrWaitingJobs.count >= 4 {
            return .aggregate
        }

        return .queueLines
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

        switch resolvedFeedbackState(
            for: job
        ) {
        case .preparing:
            switch job.state {
            case .draft,
                 .queued:
                return "已接收，正在准备照片"
            case .preparing,
                 .ready,
                 .running,
                 .completed,
                 .failed,
                 .cancelled:
                return "正在准备原图与处理信息"
            }
        case .processing:
            if job.totalTaskCount <= 1 {
                return "正在生成新的结果图并写回系统相册"
            }

            return "正在继续处理这批照片，结果会写回系统相册"
        case .completed:
            return "本批照片已完成并写回系统相册"
        case .partialSuccess:
            if job.hasRetryableFailures {
                return "大部分照片已完成，剩余项目可回到时光记继续处理"
            }

            return "部分照片已完成，剩余项目需要回到时光记查看"
        case .needsAttention:
            if job.hasRetryableFailures {
                return "这批照片需要回到时光记处理"
            }

            return "这批照片需要回到时光记查看原因"
        case .unsupported:
            return "这批照片当前暂不支持处理"
        }
    }

    func resolvedFeedbackState(
        for job: BatchJob
    ) -> PhotoMemoBackgroundFeedbackState {

        if !job.tasks.allSatisfy({
            $0.phase.isTerminal
        }) {
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

        if job.failedTaskCount > 0 {
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

    func resolvedPipelineSteps(
        for activeTask: BatchTask?,
        job: BatchJob
    ) -> [PhotoMemoBackgroundPipelineStep] {

        let titles = [
            "接收照片",
            "读取信息",
            "生成卡片",
            "写入图库",
            "完成"
        ]
        let activeIndex =
            resolvedActivePipelineStepIndex(
                for: activeTask,
                job: job
            )

        return titles.indices.map { index in
            PhotoMemoBackgroundPipelineStep(
                title: titles[index],
                state:
                    pipelineStepState(
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

        if let failurePhase =
            activeTask?.failure?.phase {
            return pipelineIndex(
                for: failurePhase
            )
        }

        guard let activeTask else {
            return 0
        }

        return pipelineIndex(
            for: activeTask.phase
        )
    }

    func pipelineStepState(
        index: Int,
        activeIndex: Int,
        activeTask: BatchTask?,
        job: BatchJob
    ) -> PhotoMemoBackgroundPipelineStepState {

        if activeTask?.phase == .failed
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

    func resolvedQueueLines(
        jobs: [BatchJob],
        activeJobID: UUID,
        activeTaskID: UUID?
    ) -> [String] {

        let displayableJobs =
            displayableQueueJobs(
            from: jobs,
            activeJobID: activeJobID
        )

        let activeOrWaitingJobs =
            displayableJobs.filter {
                !$0.tasks.allSatisfy {
                    $0.phase.isTerminal
                }
            }

        if activeOrWaitingJobs.count >= 4 {
            return [
                aggregateQueueLine(
                    for: displayableJobs
                )
            ]
        }

        return displayableJobs
            .prefix(3)
        .map { job in
            queueLine(
                for: job,
                activeTaskID:
                    job.id == activeJobID
                    ? activeTaskID
                    : nil
            )
        }
    }

    func aggregateQueueLine(
        for jobs: [BatchJob]
    ) -> String {

        let runningCount =
            jobs.reduce(0) { partial, job in
                partial
                    + job.tasks
                    .filter {
                        !$0.phase.isTerminal
                        && $0.phase != .queued
                    }
                    .count
            }
        let waitingCount =
            jobs.reduce(0) { partial, job in
                partial
                    + job.tasks
                    .filter {
                        $0.phase == .queued
                    }
                    .count
            }
        let completedCount =
            jobs.reduce(0) {
                $0 + $1.completedTaskCount
            }
        let failedCount =
            jobs.reduce(0) {
                $0 + $1.failedTaskCount
            }

        if failedCount > 0 {
            return "\(failedCount) 张需要处理 · 已完成 \(completedCount) 张"
        }

        return "进行中 \(runningCount) 张 · 等待 \(waitingCount) 张 · 已完成 \(completedCount) 张"
    }

    func displayableQueueJobs(
        from jobs: [BatchJob],
        activeJobID: UUID
    ) -> [BatchJob] {

        jobs
            .filter {
                $0.launchSource != .inAppPreview
            }
            .sorted { lhs, rhs in
                queuePriority(
                    for: lhs,
                    activeJobID: activeJobID
                )
                < queuePriority(
                    for: rhs,
                    activeJobID: activeJobID
                )
            }
    }

    func queuePriority(
        for job: BatchJob,
        activeJobID: UUID
    ) -> Int {

        if job.id == activeJobID {
            return 0
        }

        if job.hasRetryableFailures
            || job.failedTaskCount > 0 {
            return 1
        }

        if !job.tasks.allSatisfy({
            $0.phase.isTerminal
        }) {
            return 2
        }

        return 3
    }

    func queueLine(
        for job: BatchJob,
        activeTaskID: UUID?
    ) -> String {

        let prefix =
            queueDisplayTitle(
                for: job
            )

        let body =
            queueLineBody(
                for: job,
                activeTaskID: activeTaskID
            )

        return "\(prefix) · \(body)"
    }

    func queueDisplayTitle(
        for job: BatchJob
    ) -> String {

        PhotoMemoQueueDisplayFormatter.title(
            startedAt:
                job.createdAt,
            photoCount:
                job.totalTaskCount
        )
    }

    func queueLineBody(
        for job: BatchJob,
        activeTaskID: UUID?
    ) -> String {

        if job.totalTaskCount <= 1 {
            return singlePhotoQueueLineBody(
                for: job,
                activeTaskID: activeTaskID
            )
        }

        if job.completedTaskCount == job.totalTaskCount,
           job.failedTaskCount == 0 {
            return "已保存 \(job.totalTaskCount) 张"
        }

        if job.failedTaskCount > 0,
           job.tasks.allSatisfy({
               $0.phase.isTerminal
           }) {
            if job.completedTaskCount > 0 {
                return "已保存 \(job.completedTaskCount) 张 · \(job.failedTaskCount) 张需要处理"
            }

            return "\(job.failedTaskCount) 张需要处理"
        }

        if !job.tasks.allSatisfy({
            $0.phase.isTerminal
        }) {
            return "\(job.completedTaskCount)/\(job.totalTaskCount) · \(remainingTimeText(for: job))"
        }

        return "\(job.completedTaskCount)/\(job.totalTaskCount)"
    }

    func singlePhotoQueueLineBody(
        for job: BatchJob,
        activeTaskID: UUID?
    ) -> String {

        if job.completedTaskCount == 1,
           job.failedTaskCount == 0 {
            return "已保存 1 张"
        }

        if job.failedTaskCount > 0 {
            return "1 张需要处理"
        }

        let activeTask =
            job.tasks.first {
                $0.id == activeTaskID
            }
            ?? job.tasks.first {
                !$0.phase.isTerminal
            }

        guard let activeTask else {
            return "1 张"
        }

        return "\(singlePhotoPhaseText(activeTask)) · \(remainingTimeText(for: job))"
    }

    func singlePhotoPhaseText(
        _ task: BatchTask
    ) -> String {

        let statusMessage =
            task.progress.statusMessage
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if statusMessage.contains("RAW") {
            switch task.phase {

            case .importing:
                return "准备 RAW"

            case .metadataReady:
                return "RAW 显示版本"

            default:
                break
            }
        }

        switch task.phase {

        case .queued:
            return "等待开始"

        case .importing:
            return "读取原图"

        case .metadataReady,
             .previewReady:
            return "整理信息"

        case .waitingForExport,
             .exporting:
            return "生成图片"

        case .savingToPhotoLibrary:
            return "写入图库"

        case .completed:
            return "已保存"

        case .failed:
            return "需要查看"

        case .cancelled:
            return "已取消"
        }
    }

    func remainingTimeText(
        for job: BatchJob
    ) -> String {

        let remainingTasks =
            job.tasks.filter {
                !$0.phase.isTerminal
            }
        let remainingCount =
            remainingTasks.count

        guard remainingCount > 0 else {
            return "即将完成"
        }

        let totalEstimatedSeconds =
            remainingTasks.reduce(
                0
            ) { partialResult, task in
                partialResult
                    + estimatedSeconds(
                        for: task
                    )
            }

        if totalEstimatedSeconds < 60 {
            return "约 \(totalEstimatedSeconds) 秒"
        }

        let minutes =
            max(
                Int(
                        ceil(
                            Double(totalEstimatedSeconds) / 60
                        )
                ),
                1
            )

        return "约 \(minutes) 分钟"
    }

    func estimatedSeconds(
        for task: BatchTask
    ) -> Int {

        if taskUsesRAWDisplayRepresentation(
            task
        ) {
            return 75
        }

        return 14
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
}
#endif
