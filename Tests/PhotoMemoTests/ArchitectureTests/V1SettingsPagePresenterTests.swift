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
                pipelineSteps: [],
                activePipelineStepIndex: 2,
                queueLines: [],
                overflowQueueCount: 2,
                completedCount: 2,
                failedCount: 0,
                totalCount: 3,
                progressFraction: 0.67,
                canRetryFailures: false,
                updatedAt: Date(
                    timeIntervalSince1970: 1_720_000_000
                )
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
            == "家庭周末记录 正在处理"
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
            presentation.canClearCompletedHistory
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
}
#endif
