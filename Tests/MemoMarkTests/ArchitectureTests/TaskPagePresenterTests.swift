#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("V1 settings page presenter")
struct TaskPagePresenterTests {

    @Test("task presentation uses the explicit interface language")
    func presentationUsesExplicitInterfaceLanguage() {
        let header = MemoMarkiOSQueueDiagnosticsHeaderProjection(
            headline: "Waiting",
            subheadline: "Waiting",
            symbolName: "clock",
            tint: .secondary
        )
        let expected: [
            (MemoMarkLanguage, String, String, String)
        ] = [
            (.simplifiedChinese, "等待中", "等待新的照片", "进行中"),
            (.english, "Waiting", "Waiting for new photos", "Processing"),
            (.japanese, "待機中", "新しい写真を待っています", "処理中"),
            (.korean, "대기 중", "새 사진을 기다리는 중", "처리 중")
        ]

        for (language, status, subtitle, overviewTitle) in expected {
            let presentation = TaskPagePresenter.presentation(
                header: header,
                snapshot: nil,
                recoveryMessage: nil,
                events: [],
                overview: MemoMarkBackgroundTaskOverview(
                    activeJobCount: 1,
                    completedPhotoCount: 0,
                    failedPhotoCount: 0,
                    todayProcessingCount: 0
                ),
                language: language
            )

            #expect(presentation.currentTask.statusText == status)
            #expect(presentation.currentTask.subtitleText == subtitle)
            #expect(presentation.overviewItems[0].title == overviewTitle)
        }
    }

    @Test("photo library task actions use the explicit interface language")
    func photoLibraryActionsUseExplicitInterfaceLanguage() {
        let link = TaskPhotoLibraryLink(
            albumName: "最近的日子",
            assetIdentifier: "asset-id"
        )

        #expect(link.actionTitle(language: .japanese) == "写真アプリで見る")
        #expect(
            link.saveDestinationText(language: .japanese)
            == "「最近的日子」に保存"
        )
        #expect(
            link.accessibilityHint(language: .korean)
            == "사진 앱을 열어 ‘最近的日子’을(를) 확인하세요."
        )
    }

    @Test("builds a current-task card from the active snapshot and derives compact history rows from diagnostics events")
    func presentationReflectsActiveSnapshotAndHistoryRows() {
        let snapshot =
            MemoMarkBackgroundJobSnapshot(
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
                    MemoMarkBackgroundPipelineStep(
                        title: "接收照片",
                        state: .completed
                    ),
                    MemoMarkBackgroundPipelineStep(
                        title: "生成卡片",
                        state: .active
                    ),
                    MemoMarkBackgroundPipelineStep(
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
            MemoMarkiOSQueueDiagnosticsHeaderProjection(
                headline: "家庭周末记录 正在处理",
                subheadline: "照片已经进入后台队列，完成后会写回系统相册。",
                symbolName: "arrow.trianglehead.2.clockwise.circle.fill",
                tint: .blue
            )
        let events = [
            MemoMarkShareDiagnosticEvent(
                timestamp: Date(timeIntervalSince1970: 1_720_000_030),
                stage: .appEnqueueCreated,
                message: "tasks=3"
            ),
            MemoMarkShareDiagnosticEvent(
                timestamp: Date(timeIntervalSince1970: 1_720_000_060),
                stage: .liveActivityPayloadTerminal,
                message: "terminal"
            )
        ]

        let presentation =
            TaskPagePresenter
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
            == "经典白 预设"
        )
        #expect(
            presentation.currentTask.statusText
            == "处理中"
        )
        #expect(
            presentation.currentTask.displayMode
            == .processing
        )
        #expect(
            presentation.currentTask.itemCountText
            == "3 张照片"
        )
        #expect(
            presentation.currentTask.progressText
            == "已完成 2 张 · 剩余 1 张"
        )
        #expect(
            presentation.currentTask.detailText
            == "正在保留元数据并生成新图片。"
        )
        #expect(
            presentation.currentTask.stepRows.map(\.statusText)
            == [
                "已完成",
                "处理中",
                "等待中"
            ]
        )
        #expect(
            presentation.currentTask.stepRows.map(\.tint)
            == [
                .secondary,
                .blue,
                .secondary
            ]
        )
        #expect(presentation.historyRows.isEmpty)
    }

    @Test("falls back to a recovery-oriented current-task card without an active snapshot")
    func presentationFallsBackWithoutSnapshot() {
        let header =
            MemoMarkiOSQueueDiagnosticsHeaderProjection(
                headline: "共享进度记录需要恢复",
                subheadline: "重新分享后会生成新的本地记录。",
                symbolName: "exclamationmark.triangle.fill",
                tint: .orange,
                isRecovery: true
            )
        let events = [
            MemoMarkShareDiagnosticEvent(
                timestamp: Date(timeIntervalSince1970: 1_720_000_090),
                stage: .extensionSourcePrepare,
                message: "loading"
            )
        ]

        let presentation =
            TaskPagePresenter
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
            presentation.currentTask.displayMode
            == .needsAttention
        )
        #expect(
            presentation.currentTask.itemCountText
            == nil
        )
        #expect(
            presentation.currentTask.detailText
            == "共享接单记录不可读取。"
        )
        #expect(presentation.historyRows.isEmpty)
    }

    @Test("surfaces unsupported batches as calm unsupported status instead of generic failure")
    func presentationSurfacesUnsupportedBatchState() {
        let snapshot =
            MemoMarkBackgroundJobSnapshot(
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
            MemoMarkiOSQueueDiagnosticsHeaderProjection(
                headline: "超长截图 暂不支持",
                subheadline: "当前版本更适合支持的静态照片格式。",
                symbolName: "exclamationmark.triangle.fill",
                tint: .orange
            )

        let presentation =
            TaskPagePresenter
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
            presentation.currentTask.displayMode
            == .needsAttention
        )
        #expect(
            presentation.currentTask.progressText
            == "已完成 0 张 · 剩余 1 张暂不支持"
        )
    }

    @Test("maps engineering step names and progress into user language")
    func presentationUsesUserFacingProcessingLanguage() {
        let snapshot = MemoMarkBackgroundJobSnapshot(
            jobID: UUID(),
            title: "处理照片",
            launchSource: .shareExtension,
            presentationState: .active,
            jobState: .running,
            currentPhase: .exporting,
            currentPhaseTitle: "处理中",
            currentFileName: "photo.jpg",
            statusMessage: "正在处理照片。",
            displayMode: .singleTask,
            pipelineSteps: [
                MemoMarkBackgroundPipelineStep(
                    title: "Renderer Pipeline",
                    state: .active
                ),
                MemoMarkBackgroundPipelineStep(
                    title: "Queue",
                    state: .pending
                )
            ],
            activePipelineStepIndex: 0,
            queueLines: [],
            overflowQueueCount: 0,
            completedCount: 1,
            failedCount: 0,
            totalCount: 4,
            progressFraction: 0.25,
            canRetryFailures: false,
            hasOnlyUnsupportedFailures: false,
            updatedAt: Date(timeIntervalSince1970: 1_720_000_000)
        )

        let presentation = TaskPagePresenter.presentation(
            header: MemoMarkiOSQueueDiagnosticsHeaderProjection(
                headline: "处理中",
                subheadline: "正在处理照片。",
                symbolName: "photo.stack.fill",
                tint: .blue
            ),
            snapshot: snapshot,
            recoveryMessage: nil,
            events: []
        )

        #expect(
            presentation.currentTask.progressText
            == "已完成 1 张 · 剩余 3 张"
        )
        #expect(presentation.currentTask.totalCount == 4)
        #expect(
            presentation.currentTask.stepRows.map(\.title)
            == ["生成记忆照片", "处理照片"]
        )
        #expect(
            presentation.currentTask.stepRows
                .allSatisfy { $0.timeText == nil }
        )
    }

    @Test("builds task overview and recent rows from queue job summaries")
    func presentationUsesQueueSummariesForTaskPage() {
        let presentation =
            TaskPagePresenter
            .presentation(
                header:
                    MemoMarkiOSQueueDiagnosticsHeaderProjection(
                        headline: "等待下一次分享",
                        subheadline: "分享一次照片后会显示处理状态。",
                        symbolName: "square.stack.3d.down.forward",
                        tint: .secondary
                    ),
                snapshot: nil,
                recoveryMessage: nil,
                events: [
                    MemoMarkShareDiagnosticEvent(
                        timestamp: Date(timeIntervalSince1970: 1),
                        stage: .appEnqueueCreated,
                        message: "tasks=9"
                    )
                ],
                overview:
                    MemoMarkBackgroundTaskOverview(
                        activeJobCount: 1,
                        completedPhotoCount: 28,
                        failedPhotoCount: 0,
                        todayProcessingCount: 12
                    ),
                recentJobs: [
                    MemoMarkBackgroundJobSummary(
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
            == "经典白样式 · 处理 8 张照片"
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
        #expect(
            presentation.currentTask.displayMode
            == .waiting
        )
    }

    @Test("recent saves include only completed jobs with a persisted Photos asset")
    func recentSavesExcludeUnfinishedFailedAndUnpersistedJobs() {
        let savedJobID = UUID(
            uuidString: "44444444-4444-4444-4444-444444444444"
        )!
        let summaries = [
            MemoMarkBackgroundJobSummary(
                jobID: UUID(),
                configurationName: "正在处理",
                templateName: "Classic White",
                presentationState: .active,
                jobState: .running,
                completedCount: 1,
                failedCount: 0,
                totalCount: 2,
                previewSourceURL: nil,
                savedAssetIdentifier: "partial-asset",
                updatedAt: Date(timeIntervalSince1970: 4)
            ),
            MemoMarkBackgroundJobSummary(
                jobID: UUID(),
                configurationName: "需要处理",
                templateName: "Classic White",
                presentationState: .needsAttention,
                jobState: .failed,
                completedCount: 1,
                failedCount: 1,
                totalCount: 2,
                previewSourceURL: nil,
                savedAssetIdentifier: "failed-job-asset",
                updatedAt: Date(timeIntervalSince1970: 3)
            ),
            MemoMarkBackgroundJobSummary(
                jobID: UUID(),
                configurationName: "缺少保存凭据",
                templateName: "Classic White",
                presentationState: .completed,
                jobState: .completed,
                completedCount: 1,
                failedCount: 0,
                totalCount: 1,
                previewSourceURL: nil,
                savedAlbumName: "时光记",
                savedAssetIdentifier: "  ",
                updatedAt: Date(timeIntervalSince1970: 2)
            ),
            MemoMarkBackgroundJobSummary(
                jobID: savedJobID,
                configurationName: "已经保存",
                templateName: "Classic White",
                presentationState: .completed,
                jobState: .completed,
                completedCount: 1,
                failedCount: 0,
                totalCount: 1,
                previewSourceURL: nil,
                savedAlbumName: "时光记",
                savedAssetIdentifier: "saved-asset",
                updatedAt: Date(timeIntervalSince1970: 1)
            )
        ]

        let presentation = TaskPagePresenter.presentation(
            header: MemoMarkiOSQueueDiagnosticsHeaderProjection(
                headline: "等待下一次分享",
                subheadline: "分享一次照片后会显示处理状态。",
                symbolName: "square.stack.3d.down.forward",
                tint: .secondary
            ),
            snapshot: nil,
            recoveryMessage: nil,
            events: [
                MemoMarkShareDiagnosticEvent(
                    timestamp: Date(timeIntervalSince1970: 5),
                    stage: .liveActivityPayloadTerminal,
                    message: "failed, progress=100"
                )
            ],
            recentJobs: summaries
        )

        #expect(presentation.historyRows.map(\.jobID) == [savedJobID])
    }

    @Test("presents a completed snapshot as the latest result and removes the same job from recent history")
    func presentationSeparatesCompletedResultFromRecentHistory() {
        let completedJobID = UUID(
            uuidString: "11111111-1111-1111-1111-111111111111"
        )!
        let olderJobID = UUID(
            uuidString: "22222222-2222-2222-2222-222222222222"
        )!
        let snapshot = MemoMarkBackgroundJobSnapshot(
            jobID: completedJobID,
            title: "生日回顾",
            launchSource: .shareExtension,
            presentationState: .completed,
            jobState: .completed,
            currentPhase: .completed,
            currentPhaseTitle: "已保存到照片图库",
            currentFileName: "birthday.jpg",
            statusMessage: "已保存到时光记。",
            displayMode: .singleTask,
            pipelineSteps: [
                MemoMarkBackgroundPipelineStep(
                    title: "写入图库",
                    state: .completed
                )
            ],
            activePipelineStepIndex: 1,
            queueLines: [],
            overflowQueueCount: 0,
            completedCount: 1,
            failedCount: 0,
            totalCount: 1,
            progressFraction: 1,
            canRetryFailures: false,
            hasOnlyUnsupportedFailures: false,
            updatedAt: Date(timeIntervalSince1970: 1_720_000_180),
            configurationName: "生日回顾",
            templateName: "Classic White",
            savedAlbumName: "时光记",
            savedAssetIdentifier: "birthday-asset"
        )
        let recentJobs = [
            MemoMarkBackgroundJobSummary(
                jobID: completedJobID,
                configurationName: "生日回顾",
                templateName: "Classic White",
                presentationState: .completed,
                jobState: .completed,
                completedCount: 1,
                failedCount: 0,
                totalCount: 1,
                previewSourceURL: nil,
                savedAlbumName: "时光记",
                savedAssetIdentifier: "birthday-asset",
                updatedAt: Date(timeIntervalSince1970: 1_720_000_180)
            ),
            MemoMarkBackgroundJobSummary(
                jobID: olderJobID,
                configurationName: "旅行记录",
                templateName: "Classic White",
                presentationState: .completed,
                jobState: .completed,
                completedCount: 3,
                failedCount: 0,
                totalCount: 3,
                previewSourceURL: nil,
                savedAlbumName: "时光记",
                savedAssetIdentifier: "travel-asset",
                updatedAt: Date(timeIntervalSince1970: 1_720_000_120)
            )
        ]

        let presentation = TaskPagePresenter.presentation(
            header: MemoMarkiOSQueueDiagnosticsHeaderProjection(
                headline: "生日回顾 已完成",
                subheadline: "已保存到照片图库。",
                symbolName: "checkmark.circle.fill",
                tint: .green
            ),
            snapshot: snapshot,
            recoveryMessage: nil,
            events: [],
            recentJobs: recentJobs
        )

        #expect(presentation.currentTask.displayMode == .completed)
        #expect(presentation.currentTask.jobID == completedJobID)
        #expect(presentation.historyRows.map(\.jobID) == [olderJobID])
    }
}
#endif
