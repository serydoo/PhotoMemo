#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 iOS home recent processing presenter")
struct V1IOSHomeRecentProcessingPresenterTests {

    @Test("presentation reflects latest snapshot state for home summary")
    func presentationReflectsLatestSnapshotStateForHomeSummary() {
        let snapshot =
            PhotoMemoBackgroundJobSnapshot(
                jobID: UUID(),
                title: "最近处理",
                launchSource: .shareExtension,
                presentationState: .active,
                jobState: .running,
                currentPhase: .exporting,
                currentPhaseTitle: "生成图片",
                currentFileName: "family.jpg",
                statusMessage: "正在生成图片",
                displayMode: .singleTask,
                pipelineSteps: [],
                activePipelineStepIndex: 2,
                queueLines: [],
                overflowQueueCount: 0,
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
                headline: "处理中",
                subheadline: "最近一批照片正在继续生成。",
                symbolName: "arrow.trianglehead.2.clockwise.circle.fill",
                tint: .blue
            )

        let presentation =
            V1IOSHomeRecentProcessingPresenter
            .presentation(
                header: header,
                snapshot: snapshot,
                recoveryMessage: nil
            )

        #expect(
            presentation.headline
            == "处理中"
        )
        #expect(
            presentation.statusValue
            == "处理中"
        )
        #expect(
            presentation.sourceValue
            == "分享进入"
        )
        #expect(
            presentation.updatedAtValue
            != "暂无"
        )
        #expect(
            presentation.recoveryMessage
            == nil
        )
    }

    @Test("presentation falls back to recovery-oriented home copy without snapshot")
    func presentationFallsBackToRecoveryOrientedHomeCopyWithoutSnapshot() {
        let header =
            PhotoMemoiOSQueueDiagnosticsHeaderProjection(
                headline: "共享进度记录需要恢复",
                subheadline: "重新分享后会生成新的本地记录。",
                symbolName: "exclamationmark.triangle.fill",
                tint: .orange
            )

        let presentation =
            V1IOSHomeRecentProcessingPresenter
            .presentation(
                header: header,
                snapshot: nil,
                recoveryMessage: "共享接单记录不可读取。"
            )

        #expect(
            presentation.statusValue
            == "需要恢复"
        )
        #expect(
            presentation.sourceValue
            == "Apple Photos 分享"
        )
        #expect(
            presentation.updatedAtValue
            == "暂无"
        )
        #expect(
            presentation.recoveryMessage
            == "共享接单记录不可读取。"
        )
    }
}
#endif
