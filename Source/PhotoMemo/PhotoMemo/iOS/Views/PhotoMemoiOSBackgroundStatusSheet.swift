#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct PhotoMemoiOSBackgroundStatusSheet:
    View {

    @ObservedObject
    var backgroundStatusService:
        PhotoMemoBackgroundStatusService

    @ObservedObject
    var batchQueueStore:
        BatchQueueStore

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {

        NavigationStack {

            Group {
                if let snapshot =
                    backgroundStatusService
                    .currentSnapshot {
                    content(
                        for: snapshot
                    )
                } else {
                    emptyState
                }
            }
            .navigationTitle("处理进度")
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([
            .medium,
            .large
        ])
    }
}

private extension PhotoMemoiOSBackgroundStatusSheet {

    var currentJob: BatchJob? {

        guard let jobID =
            backgroundStatusService
            .currentSnapshot?
            .jobID
        else {
            return nil
        }

        return batchQueueStore.jobs.first {
            $0.id == jobID
        }
    }

    func content(
        for snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> some View {

        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                statusHero(
                    snapshot
                )

                if snapshot.displayMode
                    == .singleTask {
                    pipelineCard(snapshot)
                }

                if let job = currentJob {
                    processingFocusCard(
                        snapshot,
                        job: job
                    )
                }

                if snapshot.canRetryFailures {
                    Button("重试失败项") {
                        batchQueueStore
                            .retryFailedTasks(
                        in:
                            snapshot.jobID
                        )
                    }
                    .buttonStyle(.borderedProminent)
                }

                if let latestFailureSummary =
                    batchQueueStore
                    .latestFailureSummary {
                    latestFailureCard(
                        latestFailureSummary
                    )
                }
            }
            .padding(20)
        }
    }

    var emptyState: some View {

        ContentUnavailableView(
            "暂时没有后台任务",
            systemImage:
                "square.stack.3d.down.forward",
            description: Text(
                "这里只保留当前处理、失败重试和最近一次失败。"
            )
        )
    }

    func statusHero(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> some View {

        PhotoMemoiOSBackgroundStatusHeroCard(
            title:
                heroTitle(
                    snapshot
                ),
            symbolName:
                heroSymbol(
                    snapshot
                ),
            snapshotTitle:
                snapshot.title,
            statusMessage:
                snapshot.statusMessage,
            displayMode:
                snapshot.displayMode,
            queueLines:
                snapshot.queueLines,
            overflowQueueCount:
                snapshot.overflowQueueCount,
            progressFraction:
                snapshot.progressFraction,
            progressSummary:
                progressSummary(
                    snapshot
                ),
            launchSourceTitle:
                launchSourceTitle(
                    snapshot.launchSource
                ),
            phaseTitle:
                snapshot.currentPhaseTitle
                ?? snapshot.jobState.displayTitle
        )
    }

    func pipelineCard(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> some View {

        PhotoMemoiOSBackgroundPipelineCard(
            steps:
                snapshot.pipelineSteps
        )
    }

    func processingFocusCard(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot,
        job: BatchJob
    ) -> some View {

        let trimmedCurrentFileName =
            snapshot.currentFileName?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let resolvedCurrentFileName:
            String?

        if let trimmedCurrentFileName,
           !trimmedCurrentFileName.isEmpty {
            resolvedCurrentFileName =
                trimmedCurrentFileName
        } else {
            resolvedCurrentFileName =
                nil
        }

        return PhotoMemoiOSBackgroundProcessingFocusCard(
            currentFileName:
                resolvedCurrentFileName,
            jobStateTitle:
                snapshot.jobState
                .displayTitle,
            updatedAt:
                snapshot.updatedAt,
            attentionSummary:
                snapshot.failedCount > 0
                ? attentionSummary(
                    snapshot
                )
                : nil
        )
    }

    func latestFailureCard(
        _ summary:
            BatchFailureSummary
    ) -> some View {

        PhotoMemoiOSBackgroundLatestFailureCard(
            phaseTitle:
                summary.latestFailure.phaseTitle,
            message:
                summary.latestFailure.message,
            updatedAt:
                summary.updatedAt
        )
    }

    func heroTitle(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> String {

        switch snapshot.feedbackState {
        case .preparing:
            return "正在准备处理"
        case .processing:
            return "正在后台处理"
        case .completed:
            return "最近后台任务已完成"
        case .partialSuccess:
            return "部分照片已完成"
        case .needsAttention:
            return "有照片需要处理"
        case .unsupported:
            return "有照片暂不支持"
        }
    }

    func heroSymbol(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> String {

        switch snapshot.feedbackState {
        case .preparing,
             .processing:
            return "arrow.trianglehead.2.clockwise.circle.fill"
        case .partialSuccess,
             .needsAttention,
             .unsupported:
            return "exclamationmark.triangle.fill"
        case .completed:
            return "checkmark.circle.fill"
        }
    }

    func launchSourceTitle(
        _ source:
            BatchJobLaunchSource
    ) -> String {
        source.displayTitle
    }

    func progressSummary(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> String {

        let percent =
            Int(
                (
                    snapshot.progressFraction
                * 100
                )
                .rounded()
            )

        switch snapshot.feedbackState {
        case .preparing,
             .processing:
            return "整体进度 \(percent)% · 已完成 \(snapshot.completedCount)/\(snapshot.totalCount)"
        case .completed:
            return "已完成 \(snapshot.completedCount) 张，结果已写回系统相册"
        case .partialSuccess:
            return "已完成 \(snapshot.completedCount) 张，仍有 \(snapshot.failedCount) 张需处理"
        case .needsAttention:
            return "\(snapshot.failedCount) 张需要回到时光记查看"
        case .unsupported:
            return "这批照片当前不在支持范围内"
        }
    }

    func attentionSummary(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> String {

        if snapshot.feedbackState == .unsupported {
            return "这批照片当前不在支持范围内，建议改用支持的照片格式再试。"
        }

        if snapshot.canRetryFailures {
            return "本批次有 \(snapshot.failedCount) 张未成功，可直接在这里重试失败项。"
        }

        return "本批次有 \(snapshot.failedCount) 张未成功，当前更适合先查看失败原因。"
    }
}
#endif
