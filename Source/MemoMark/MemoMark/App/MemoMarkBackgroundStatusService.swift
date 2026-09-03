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
        savedAssetIdentifier: String? = nil
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
        .sink { [weak self] _, _, _, _ in
            self?.refreshSnapshot()
        }
        .store(in: &cancellables)
    }

    func refreshSnapshot() {

        let externalJobs =
            resolvedExternalJobs(
                from: batchQueueStore.jobs
            )

        hasProcessingRecord = !externalJobs.isEmpty

        currentSnapshot =
            projection.resolvedSnapshot(
                externalJobs: externalJobs,
                activeJobID:
                    batchQueueStore.activeJobID,
                activeTaskID:
                    batchQueueStore.activeTaskID,
                focusedJobID:
                    focusedJobID
            )

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
                $0.launchSource != .inAppPreview
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
