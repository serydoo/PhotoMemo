#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("V1 iOS home recent processing presenter")
struct V1IOSHomeRecentProcessingPresenterTests {

    @Test("home activity card is mounted before its entry animation")
    func homeActivityCardIsMountedBeforeItsEntryAnimation() {
        let state = V1IOSHomeActivityPresentationState()

        #expect(state.isMounted)
        #expect(!state.isVisible)
    }

    @Test("home activity projection shows the current processing position")
    func homeActivityProjectionShowsCurrentProcessingPosition() {
        let snapshot = makeSnapshot(
            presentationState: .active,
            jobState: .running,
            completedCount: 5,
            failedCount: 0,
            totalCount: 10,
            progressFraction: 0.56
        )

        let projection =
            V1IOSHomeActivityPresenter
            .projection(from: snapshot)

        #expect(projection?.state == .processing)
        #expect(projection?.countText == "任务 6 / 10 张")
        #expect(projection?.statusText == "进行中")
        #expect(projection?.progressFraction == 0.56)
    }

    @Test("home activity projection appends queued job count in its title")
    func homeActivityProjectionAppendsQueuedJobCountInItsTitle() {
        let snapshot = makeSnapshot(
            presentationState: .active,
            jobState: .running,
            completedCount: 5,
            failedCount: 0,
            totalCount: 10,
            progressFraction: 0.56,
            queuedJobCount: 2
        )

        let projection =
            V1IOSHomeActivityPresenter
            .projection(from: snapshot)

        #expect(projection?.countText == "任务 6 / 10 张 · 后续 2 个")
    }

    @Test("home activity projection keeps the failed position")
    func homeActivityProjectionKeepsFailedPosition() {
        let snapshot = makeSnapshot(
            presentationState: .needsAttention,
            jobState: .failed,
            completedCount: 3,
            failedCount: 1,
            totalCount: 10,
            progressFraction: 0.4
        )

        let projection =
            V1IOSHomeActivityPresenter
            .projection(from: snapshot)

        #expect(projection?.state == .failed)
        #expect(projection?.countText == "任务 4 / 10 张")
        #expect(projection?.statusText == "失败")
        #expect(projection?.progressFraction == 0.4)
    }

    @Test("home activity projection formats count and status in every interface language")
    func homeActivityProjectionFormatsEveryInterfaceLanguage() throws {
        let snapshot = makeSnapshot(
            presentationState: .active,
            jobState: .running,
            completedCount: 5,
            failedCount: 0,
            totalCount: 10,
            progressFraction: 0.56,
            queuedJobCount: 2
        )
        let projection = try #require(
            V1IOSHomeActivityPresenter.projection(from: snapshot)
        )

        #expect(
            projection.countText(language: .simplifiedChinese)
            == "任务 6 / 10 张 · 后续 2 个"
        )
        #expect(
            projection.statusText(language: .simplifiedChinese)
            == "进行中"
        )
        #expect(
            projection.countText(language: .english)
            == "Task 6 / 10 photos · 2 more queued"
        )
        #expect(
            projection.statusText(language: .english)
            == "Processing"
        )
        #expect(
            projection.countText(language: .japanese)
            == "写真 6 / 10枚・次に2件"
        )
        #expect(
            projection.statusText(language: .japanese)
            == "処理中"
        )
        #expect(
            projection.countText(language: .korean)
            == "사진 6 / 10장 · 다음 2개"
        )
        #expect(
            projection.statusText(language: .korean)
            == "처리 중"
        )
    }

    @Test("completed home activity expires after ten minutes")
    func completedHomeActivityExpiresAfterTenMinutes() {
        let completedAt = Date(timeIntervalSince1970: 100)
        let snapshot = makeSnapshot(
            presentationState: .completed,
            jobState: .completed,
            completedCount: 10,
            failedCount: 0,
            totalCount: 10,
            progressFraction: 1,
            updatedAt: completedAt
        )

        let projection =
            V1IOSHomeActivityPresenter
            .projection(from: snapshot)

        #expect(
            projection.map {
                V1IOSHomeActivityPresenter
                    .shouldShow(
                        $0,
                        now: Date(timeIntervalSince1970: 699)
                    )
            } == true
        )
        #expect(
            projection.map {
                V1IOSHomeActivityPresenter
                    .shouldShow(
                        $0,
                        now: Date(timeIntervalSince1970: 701)
                    )
            } == false
        )
    }

    @Test("home activity projection is absent without a task snapshot")
    func homeActivityProjectionIsAbsentWithoutATaskSnapshot() {
        #expect(
            V1IOSHomeActivityPresenter
                .projection(from: nil)
            == nil
        )
    }

    @Test("presentation reflects latest snapshot state for home summary")
    func presentationReflectsLatestSnapshotStateForHomeSummary() {
        let snapshot =
            MemoMarkBackgroundJobSnapshot(
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
                hasOnlyUnsupportedFailures: false,
                updatedAt: Date(
                    timeIntervalSince1970: 1_720_000_000
                )
            )
        let header =
            MemoMarkiOSQueueDiagnosticsHeaderProjection(
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

    @Test("home recent processing chrome follows the interface language")
    func homeRecentProcessingChromeFollowsTheInterfaceLanguage() {
        let header = MemoMarkiOSQueueDiagnosticsHeaderProjection(
            headline: "Waiting",
            subheadline: "Waiting",
            symbolName: "clock",
            tint: .secondary
        )

        let presentation = V1IOSHomeRecentProcessingPresenter.presentation(
            header: header,
            snapshot: nil,
            recoveryMessage: nil,
            language: .japanese
        )

        #expect(presentation.viewAllTitle == "すべて見る")
        #expect(presentation.statusLabel == "状態")
        #expect(presentation.sourceLabel == "ソース")
        #expect(presentation.updatedLabel == "最終更新")
        #expect(presentation.updatedDetail == "最近のバックグラウンド進行時刻を保持")
    }

    @Test("presentation falls back to recovery-oriented home copy without snapshot")
    func presentationFallsBackToRecoveryOrientedHomeCopyWithoutSnapshot() {
        let header =
            MemoMarkiOSQueueDiagnosticsHeaderProjection(
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

    private func makeSnapshot(
        presentationState: MemoMarkBackgroundPresentationState,
        jobState: BatchJobState,
        completedCount: Int,
        failedCount: Int,
        totalCount: Int,
        progressFraction: Double,
        queuedJobCount: Int = 0,
        updatedAt: Date = Date(timeIntervalSince1970: 1_720_000_000)
    ) -> MemoMarkBackgroundJobSnapshot {
        MemoMarkBackgroundJobSnapshot(
            jobID: UUID(),
            title: "最近处理",
            launchSource: .shareExtension,
            presentationState: presentationState,
            jobState: jobState,
            currentPhase: .exporting,
            currentPhaseTitle: "生成图片",
            currentFileName: "family.jpg",
            statusMessage: "正在生成图片",
            displayMode: .queueLines,
            pipelineSteps: [],
            activePipelineStepIndex: 2,
            queueLines: [],
            overflowQueueCount: 0,
            queuedJobCount: queuedJobCount,
            completedCount: completedCount,
            failedCount: failedCount,
            totalCount: totalCount,
            progressFraction: progressFraction,
            canRetryFailures: false,
            hasOnlyUnsupportedFailures: false,
            updatedAt: updatedAt
        )
    }
}
#endif
