#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 settings page presenter")
struct V1SettingsPagePresenterTests {

    @Test("builds a current-task card from the active snapshot and derives compact history rows from diagnostics events")
    func presentationReflectsActiveSnapshotAndHistoryRows() {
        let snapshot =
            PhotoMemoBackgroundJobSnapshot(
                jobID: UUID(),
                title: "家庭周末记录",
                launchSource: .shareExtension,
                presentationState: .active,
                jobState: .running,
                currentPhase: .exporting,
                currentPhaseTitle: "正在生成记忆卡",
                currentFileName: "family.jpg",
                statusMessage: "正在保留元数据并生成新图片。",
                displayMode: .singleTask,
                pipelineSteps: [
                    PhotoMemoBackgroundPipelineStep(
                        title: "接收照片",
                        state: .completed
                    ),
                    PhotoMemoBackgroundPipelineStep(
                        title: "生成卡片",
                        state: .active
                    ),
                    PhotoMemoBackgroundPipelineStep(
                        title: "写入图库",
                        state: .pending
                    )
                ],
                activePipelineStepIndex: 2,
                queueLines: [],
                overflowQueueCount: 2,
                completedCount: 2,
                failedCount: 0,
                totalCount: 3,
                progressFraction: 0.67,
                canRetryFailures: false,
                hasOnlyUnsupportedFailures: false,
                updatedAt: Date(
                    timeIntervalSince1970: 1_720_000_000
                ),
                configurationName: "成长记录",
                templateName: "Classic White",
                previewSourceURL:
                    URL(fileURLWithPath: "/tmp/family.jpg")
            )
        let header =
            PhotoMemoiOSQueueDiagnosticsHeaderProjection(
                headline: "家庭周末记录 正在处理",
                subheadline: "照片已经进入后台队列，完成后会写回系统相册。",
                symbolName: "arrow.trianglehead.2.clockwise.circle.fill",
                tint: .blue
            )
        let events = [
            PhotoMemoShareDiagnosticEvent(
                timestamp: Date(timeIntervalSince1970: 1_720_000_030),
                stage: .appEnqueueCreated,
                message: "tasks=3"
            ),
            PhotoMemoShareDiagnosticEvent(
                timestamp: Date(timeIntervalSince1970: 1_720_000_060),
                stage: .liveActivityPayloadTerminal,
                message: "terminal"
            )
        ]

        let presentation =
            V1SettingsPagePresenter
            .presentation(
                header: header,
                snapshot: snapshot,
                recoveryMessage: nil,
                events: events
            )

        #expect(
            presentation.currentTask.headline
            == "成长记录"
        )
        #expect(
            presentation.currentTask.subtitleText
            == "基础白 预设"
        )
        #expect(
            presentation.currentTask.statusText
            == "处理中"
        )
        #expect(
            presentation.currentTask.itemCountText
            == "3 张照片"
        )
        #expect(
            presentation.currentTask.progressText
            == "已完成 2 / 3"
        )
        #expect(
            presentation.currentTask.detailText
            == "正在保留元数据并生成新图片。"
        )
        #expect(
            presentation.currentTask.stepRows.map(\.statusText)
            == [
                "已完成",
                "处理中...",
                "等待中"
            ]
        )
        #expect(
            presentation.historyRows.count
            == 2
        )
        #expect(
            presentation.historyRows[0].title
            == "处理完成"
        )
        #expect(
            presentation.historyRows[0].statusText
            == "已完成"
        )
        #expect(
            presentation.historyRows[1].title
            == "进入处理队列"
        )
        #expect(
            presentation.historyRows[1].itemCountText
            == "3 张照片"
        )
    }

    @Test("falls back to a recovery-oriented current-task card without an active snapshot")
    func presentationFallsBackWithoutSnapshot() {
        let header =
            PhotoMemoiOSQueueDiagnosticsHeaderProjection(
                headline: "共享进度记录需要恢复",
                subheadline: "重新分享后会生成新的本地记录。",
                symbolName: "exclamationmark.triangle.fill",
                tint: .orange
            )
        let events = [
            PhotoMemoShareDiagnosticEvent(
                timestamp: Date(timeIntervalSince1970: 1_720_000_090),
                stage: .extensionSourcePrepare,
                message: "loading"
            )
        ]

        let presentation =
            V1SettingsPagePresenter
            .presentation(
                header: header,
                snapshot: nil,
                recoveryMessage: "共享接单记录不可读取。",
                events: events
            )

        #expect(
            presentation.currentTask.headline
            == "共享进度记录需要恢复"
        )
        #expect(
            presentation.currentTask.statusText
            == "需要恢复"
        )
        #expect(
            presentation.currentTask.itemCountText
            == nil
        )
        #expect(
            presentation.currentTask.detailText
            == "共享接单记录不可读取。"
        )
        #expect(
            presentation.historyRows.count
            == 1
        )
        #expect(
            presentation.historyRows[0].statusText
            == "准备中"
        )
    }

    @Test("surfaces unsupported batches as calm unsupported status instead of generic failure")
    func presentationSurfacesUnsupportedBatchState() {
        let snapshot =
            PhotoMemoBackgroundJobSnapshot(
                jobID: UUID(),
                title: "超长截图",
                launchSource: .shareExtension,
                presentationState: .needsAttention,
                jobState: .failed,
                currentPhase: .failed,
                currentPhaseTitle: "处理失败",
                currentFileName: "panorama.png",
                statusMessage: "这批照片当前暂不支持处理",
                displayMode: .singleTask,
                pipelineSteps: [],
                activePipelineStepIndex: 2,
                queueLines: [],
                overflowQueueCount: 0,
                completedCount: 0,
                failedCount: 1,
                totalCount: 1,
                progressFraction: 1,
                canRetryFailures: false,
                hasOnlyUnsupportedFailures: true,
                updatedAt: Date(
                    timeIntervalSince1970: 1_720_000_120
                )
            )
        let header =
            PhotoMemoiOSQueueDiagnosticsHeaderProjection(
                headline: "超长截图 暂不支持",
                subheadline: "当前版本更适合支持的静态照片格式。",
                symbolName: "exclamationmark.triangle.fill",
                tint: .orange
            )

        let presentation =
            V1SettingsPagePresenter
            .presentation(
                header: header,
                snapshot: snapshot,
                recoveryMessage: nil,
                events: []
            )

        #expect(
            presentation.currentTask.statusText
            == "暂不支持"
        )
        #expect(
            presentation.currentTask.progressText
            == "1 张暂不支持"
        )
    }

    @Test("builds task overview and recent rows from queue job summaries")
    func presentationUsesQueueSummariesForTaskPage() {
        let presentation =
            V1SettingsPagePresenter
            .presentation(
                header:
                    PhotoMemoiOSQueueDiagnosticsHeaderProjection(
                        headline: "等待下一次分享",
                        subheadline: "分享一次照片后会显示处理状态。",
                        symbolName: "square.stack.3d.down.forward",
                        tint: .secondary
                    ),
                snapshot: nil,
                recoveryMessage: nil,
                events: [
                    PhotoMemoShareDiagnosticEvent(
                        timestamp: Date(timeIntervalSince1970: 1),
                        stage: .appEnqueueCreated,
                        message: "tasks=9"
                    )
                ],
                overview:
                    PhotoMemoBackgroundTaskOverview(
                        activeJobCount: 1,
                        completedPhotoCount: 28,
                        failedPhotoCount: 0,
                        todayProcessingCount: 12
                    ),
                recentJobs: [
                    PhotoMemoBackgroundJobSummary(
                        jobID: UUID(
                            uuidString:
                                "11111111-1111-1111-1111-111111111111"
                        )!,
                        configurationName: "旅行记录",
                        templateName: "Classic White",
                        presentationState: .completed,
                        jobState: .completed,
                        completedCount: 8,
                        failedCount: 0,
                        totalCount: 8,
                        previewSourceURL:
                            URL(fileURLWithPath: "/tmp/travel.jpg"),
                        savedAlbumName: "时光记",
                        savedAssetIdentifier: "asset-local-id",
                        updatedAt:
                            Date(timeIntervalSince1970: 1_720_000_000)
                    )
                ],
                fallbackConfigurationName: "成长记录"
            )

        #expect(
            presentation.overviewItems.map(\.value)
            == [
                "1",
                "28",
                "0",
                "12"
            ]
        )
        #expect(
            presentation.historyRows.count
            == 1
        )
        #expect(
            presentation.historyRows[0].title
            == "旅行记录"
        )
        #expect(
            presentation.historyRows[0].detailText
            == "基础白 预设 · 8 张照片"
        )
        #expect(
            presentation.historyRows[0].statusText
            == "已完成"
        )
        #expect(
            presentation.historyRows[0]
                .photoLibraryLink?
                .displayTitle
            == "时光记"
        )
    }
}
#endif
