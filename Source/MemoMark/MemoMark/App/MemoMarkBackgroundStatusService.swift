#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Combine

enum MemoMarkBackgroundPresentationState: Hashable {

    case active

    case needsAttention

    case completed
}

enum MemoMarkBackgroundDisplayMode: String, Hashable {

    case singleTask

    case queueLines

    case aggregate
}

enum MemoMarkBackgroundFeedbackState:
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

enum MemoMarkBackgroundPipelineStepState: Hashable {

    case pending

    case active

    case completed

    case needsAttention
}

struct MemoMarkBackgroundPipelineStep: Hashable {

    let title: String

    let state: MemoMarkBackgroundPipelineStepState
}

struct MemoMarkBackgroundTaskOverview: Hashable {

    let activeJobCount: Int

    let completedPhotoCount: Int

    let failedPhotoCount: Int

    let todayProcessingCount: Int

    static let empty =
        MemoMarkBackgroundTaskOverview(
            activeJobCount: 0,
            completedPhotoCount: 0,
            failedPhotoCount: 0,
            todayProcessingCount: 0
        )
}

struct MemoMarkBackgroundJobSummary:
    Identifiable,
    Hashable {

    var id: UUID {
        jobID
    }

    let jobID: UUID

    let configurationName: String

    let templateName: String

    let presentationState:
        MemoMarkBackgroundPresentationState

    let jobState: BatchJobState

    let completedCount: Int

    let failedCount: Int

    let totalCount: Int

    let previewSourceURL: URL?

    let savedAlbumName: String?

    let savedAssetIdentifier: String?

    let updatedAt: Date

    init(
        jobID: UUID,
        configurationName: String,
        templateName: String,
        presentationState:
            MemoMarkBackgroundPresentationState,
        jobState: BatchJobState,
        completedCount: Int,
        failedCount: Int,
        totalCount: Int,
        previewSourceURL: URL?,
        savedAlbumName: String? = nil,
        savedAssetIdentifier: String? = nil,
        updatedAt: Date
    ) {
        self.jobID = jobID
        self.configurationName =
            configurationName
        self.templateName = templateName
        self.presentationState =
            presentationState
        self.jobState = jobState
        self.completedCount =
            completedCount
        self.failedCount = failedCount
        self.totalCount = totalCount
        self.previewSourceURL =
            previewSourceURL
        self.savedAlbumName =
            savedAlbumName
        self.savedAssetIdentifier =
            savedAssetIdentifier
        self.updatedAt = updatedAt
    }
}

struct MemoMarkBackgroundJobSnapshot: Hashable {

    let jobID: UUID

    let title: String

    let launchSource: BatchJobLaunchSource

    let presentationState: MemoMarkBackgroundPresentationState

    let jobState: BatchJobState

    let currentPhase: BatchTaskPhase?

    let currentPhaseTitle: String?

    let currentFileName: String?

    let statusMessage: String

    let progressStage: BatchTaskProgressStage?

    let displayMode: MemoMarkBackgroundDisplayMode

    let pipelineSteps: [MemoMarkBackgroundPipelineStep]

    let activePipelineStepIndex: Int

    let queueLines: [String]

    let overflowQueueCount: Int

    let queuedJobCount: Int

    let completedCount: Int

    let failedCount: Int

    let totalCount: Int

    let progressFraction: Double

    let canRetryFailures: Bool

    let hasOnlyUnsupportedFailures: Bool

    let updatedAt: Date

    let configurationName: String

    let templateName: String

    let previewSourceURL: URL?

    let savedAlbumName: String?

    let savedAssetIdentifier: String?

    let isPaused: Bool

    init(
        jobID: UUID,
        title: String,
        launchSource: BatchJobLaunchSource,
        presentationState:
            MemoMarkBackgroundPresentationState,
        jobState: BatchJobState,
        currentPhase: BatchTaskPhase?,
        currentPhaseTitle: String?,
        currentFileName: String?,
        statusMessage: String,
        progressStage: BatchTaskProgressStage? = nil,
        displayMode: MemoMarkBackgroundDisplayMode,
        pipelineSteps:
            [MemoMarkBackgroundPipelineStep],
        activePipelineStepIndex: Int,
        queueLines: [String],
        overflowQueueCount: Int,
        queuedJobCount: Int = 0,
        completedCount: Int,
        failedCount: Int,
        totalCount: Int,
        progressFraction: Double,
        canRetryFailures: Bool,
        hasOnlyUnsupportedFailures: Bool,
        updatedAt: Date,
        configurationName: String = "",
        templateName: String = "Classic White",
        previewSourceURL: URL? = nil,
        savedAlbumName: String? = nil,
        savedAssetIdentifier: String? = nil,
        isPaused: Bool = false
    ) {
        self.jobID = jobID
        self.title = title
        self.launchSource = launchSource
        self.presentationState =
            presentationState
        self.jobState = jobState
        self.currentPhase = currentPhase
        self.currentPhaseTitle =
            currentPhaseTitle
        self.currentFileName =
            currentFileName
        self.statusMessage =
            statusMessage
        self.progressStage =
            progressStage
        self.displayMode = displayMode
        self.pipelineSteps =
            pipelineSteps
        self.activePipelineStepIndex =
            activePipelineStepIndex
        self.queueLines = queueLines
        self.overflowQueueCount =
            overflowQueueCount
        self.queuedJobCount =
            queuedJobCount
        self.completedCount =
            completedCount
        self.failedCount = failedCount
        self.totalCount = totalCount
        self.progressFraction =
            progressFraction
        self.canRetryFailures =
            canRetryFailures
        self.hasOnlyUnsupportedFailures =
            hasOnlyUnsupportedFailures
        self.updatedAt = updatedAt
        let trimmedConfigurationName =
            configurationName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        self.configurationName =
            trimmedConfigurationName.isEmpty
            ? title
            : trimmedConfigurationName
        self.templateName = templateName
        self.previewSourceURL =
            previewSourceURL
        self.savedAlbumName =
            savedAlbumName
        self.savedAssetIdentifier =
            savedAssetIdentifier
        self.isPaused = isPaused
    }

    func localizedStatusMessage(
        for language: MemoMarkLanguage
    ) -> String {
        guard let progressStage else {
            return statusMessage
        }

        let baseMessage =
            progressStage.localizedStatusMessage(
                for: language
            )
        let trimmedFileName =
            currentFileName?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        guard !trimmedFileName.isEmpty else {
            return baseMessage
        }

        return "\(baseMessage) · \(trimmedFileName)"
    }

    var feedbackState:
        MemoMarkBackgroundFeedbackState {

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
final class MemoMarkBackgroundStatusService:
    ObservableObject {

    @Published private(set)
    var currentSnapshot:
        MemoMarkBackgroundJobSnapshot?

    @Published private(set) var currentExecutionSession: ExecutionSession?

    @Published private(set)
    var taskOverview =
        MemoMarkBackgroundTaskOverview.empty

    @Published private(set)
    var recentJobSummaries:
        [MemoMarkBackgroundJobSummary] = []

    @Published private(set)
    var hasProcessingRecord = false

    private var focusedJobID: UUID?

    private let batchQueueStore:
        BatchQueueStore

    private let interfaceLanguageProvider:
        @MainActor () -> MemoMarkLanguage

    private var cancellables:
        Set<AnyCancellable> = []

    init(
        batchQueueStore: BatchQueueStore,
        interfaceLanguageProvider:
            @escaping @MainActor () -> MemoMarkLanguage = {
                .interfaceStored
            }
    ) {
        self.batchQueueStore =
            batchQueueStore
        self.interfaceLanguageProvider =
            interfaceLanguageProvider

        bind()
        refreshSnapshot()
    }

    func deleteExecutionSessionHistory(_ sessionID: UUID) async {
        _ = await batchQueueStore.deleteExecutionSessionHistory(sessionID)
        refreshSnapshot()
    }

    func clearCompletedHistory(
        preservingCurrentJob: Bool = true
    ) async {

        let preservedJobID =
            preservingCurrentJob
            && currentSnapshot?
                .presentationState == .active
            ? currentSnapshot?.jobID
            : nil

        await batchQueueStore
            .clearTerminalExternalJobHistory(
                preserving: preservedJobID
            )

        refreshSnapshot()
    }

    func focus(jobID: UUID) {
        focusedJobID = jobID
        refreshSnapshot()
    }

    func refreshPresentation() {
        refreshSnapshot()
    }
}
private extension MemoMarkBackgroundStatusService {

    func bind() {

        Publishers.CombineLatest4(
            batchQueueStore.$jobs,
            batchQueueStore.$isProcessing,
            batchQueueStore.$activeJobID,
            batchQueueStore.$activeTaskID
        )
        .combineLatest(batchQueueStore.$processingPaused)
        .sink { [weak self] state, _ in
            let (jobs, _, activeJobID, activeTaskID) = state
            self?.refreshSnapshot(jobs: jobs, activeJobID: activeJobID, activeTaskID: activeTaskID)
        }
        .store(in: &cancellables)
    }

    func refreshSnapshot() {
        refreshSnapshot(jobs: batchQueueStore.jobs, activeJobID: batchQueueStore.activeJobID,
            activeTaskID: batchQueueStore.activeTaskID)
    }

    func refreshSnapshot(jobs: [BatchJob], activeJobID: UUID?, activeTaskID: UUID?) {
        let externalJobs =
            resolvedExternalJobs(
                from: jobs
            )

        hasProcessingRecord = !externalJobs.isEmpty

        let nextSnapshot =
            projection.resolvedSnapshot(
                externalJobs: externalJobs,
                activeJobID:
                    activeJobID,
                activeTaskID:
                    activeTaskID,
                focusedJobID:
                    focusedJobID,
                isPaused: batchQueueStore.processingPaused
            )

        if let jobID = nextSnapshot?.jobID,
           let job = externalJobs.first(where: { $0.id == jobID }) {
            currentExecutionSession = ExecutionSession(
                id: job.executionSessionID ?? job.id, jobs: externalJobs
            )
        } else {
            currentExecutionSession = nil
        }

        currentSnapshot = nextSnapshot

        taskOverview =
            projection.taskOverview(
                from: externalJobs
            )

        recentJobSummaries =
            externalJobs
            .prefix(10)
            .map {
                projection.summary(
                    for: $0
                )
            }
    }

    func resolvedExternalJobs(
        from jobs: [BatchJob]
    ) -> [BatchJob] {
        jobs
            .filter {
                $0.launchSource != .inAppPreview && $0.historyDeletedAt == nil
            }
            .sorted {
                $0.updatedAt > $1.updatedAt
            }
    }

    var interfaceLanguage: MemoMarkLanguage {
        interfaceLanguageProvider()
    }

    var textCatalog: MemoMarkBackgroundStatusTextCatalog {
        MemoMarkBackgroundStatusTextCatalog(
            language: interfaceLanguage
        )
    }

    var projection: MemoMarkBackgroundStatusProjection {
        MemoMarkBackgroundStatusProjection(
            textCatalog: textCatalog
        )
    }

}
#endif
