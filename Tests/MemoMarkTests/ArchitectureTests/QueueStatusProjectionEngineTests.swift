#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Queue status projection engine")
struct QueueStatusProjectionEngineTests {

    @Test("Header projection surfaces corrupted persistence recovery when no queue snapshot exists")
    func headerProjectionSurfacesCorruptedPersistenceRecoveryWhenNoQueueSnapshotExists() {

        let diagnosticsSnapshot =
            MemoMarkiOSProcessingDiagnosticsSnapshot(
                events: [],
                shareDiagnosticsAvailability:
                    .corrupted
            )

        let projection =
            MemoMarkiOSQueueDiagnosticsProjectionEngine
            .headerProjection(
                backgroundSnapshot: nil,
                processingDiagnosticsSnapshot:
                    diagnosticsSnapshot,
                events: []
            )

        #expect(
            projection.headline
            == "共享进度记录需要恢复"
        )
        #expect(projection.isRecovery)
        #expect(
            projection.subheadline
            == "共享进度记录 不可读取，当前已按空状态继续。重新分享后会生成新的本地记录。"
        )
        #expect(
            projection.symbolName
            == "exclamationmark.triangle.fill"
        )
        #expect(
            projection.tint
            == .orange
        )
    }

    @Test("Header status uses explicit recovery semantics instead of headline wording")
    func headerStatusUsesExplicitRecoverySemanticsInsteadOfHeadlineWording() {
        let header = MemoMarkiOSQueueDiagnosticsHeaderProjection(
            headline: "共享进度记录需要恢复",
            subheadline: "recovery",
            symbolName: "exclamationmark.triangle.fill",
            tint: .orange,
            isRecovery: false
        )

        let presentation = TaskPagePresenter.presentation(
            header: header,
            snapshot: nil,
            recoveryMessage: nil,
            events: [],
            language: .english
        )

        #expect(presentation.currentTask.statusText == "Needs attention")
    }

    @Test("Header projection prefers a newer share diagnostic over a completed queue snapshot")
    func headerProjectionPrefersANewerShareDiagnosticOverACompletedQueueSnapshot() {

        let backgroundSnapshot =
            makeBackgroundSnapshot(
                presentationState: .completed,
                updatedAt:
                    Date(
                        timeIntervalSince1970: 100
                    )
            )
        let events = [
            MemoMarkShareDiagnosticEvent(
                timestamp:
                    Date(
                        timeIntervalSince1970: 200
                    ),
                stage: .extensionSourcePrepare,
                message: "prepare"
            )
        ]

        let projection =
            MemoMarkiOSQueueDiagnosticsProjectionEngine
            .headerProjection(
                backgroundSnapshot:
                    backgroundSnapshot,
                processingDiagnosticsSnapshot:
                    MemoMarkiOSProcessingDiagnosticsSnapshot(),
                events: events
            )

        #expect(
            projection.headline
            == "正在准备 iCloud 原图"
        )
        #expect(
            projection.subheadline
            == "已向系统请求原图数据，等 iCloud 缓存到本地后继续。"
        )
        #expect(
            projection.symbolName
            == "icloud.and.arrow.down"
        )
        #expect(
            projection.tint
            == .blue
        )
    }

    @Test("Progress projection keeps title, tint, clamped progress, and pipeline step mapping identical")
    func progressProjectionKeepsTitleTintClampedProgressAndPipelineStepMappingIdentical() {

        let backgroundSnapshot =
            makeBackgroundSnapshot(
                title: "家庭相册",
                presentationState: .needsAttention,
                statusMessage: "还有 1 张需要查看",
                queueLines: ["队列中的照片"],
                failedCount: 1,
                progressFraction: 1.2,
                pipelineSteps: [
                    MemoMarkBackgroundPipelineStep(
                        title: "读取原图",
                        state: .completed
                    ),
                    MemoMarkBackgroundPipelineStep(
                        title: "生成图片",
                        state: .needsAttention
                    )
                ]
            )

        let projection =
            MemoMarkiOSQueueDiagnosticsProjectionEngine
            .progressProjection(
                for: backgroundSnapshot
            )

        #expect(
            projection.title
            == "家庭相册 部分完成"
        )
        #expect(
            projection.symbolName
            == "exclamationmark.triangle.fill"
        )
        #expect(
            projection.tint
            == .orange
        )
        #expect(
            projection.progressFraction
            == 1
        )
        #expect(
            projection.progressPercentText
            == "100%"
        )
        #expect(
            projection.showsPipeline
        )
        #expect(
            projection.pipelineSteps.map(\.symbolName)
            == [
                "checkmark.circle.fill",
                "exclamationmark.triangle.fill"
            ]
        )
        #expect(
            projection.pipelineSteps.map(\.tint)
            == [
                .green,
                .orange
            ]
        )
    }

    @Test("Progress projection localizes a semantic stage using the requested interface language")
    func progressProjectionLocalizesSemanticStageUsingRequestedLanguage() {
        let backgroundSnapshot =
            makeBackgroundSnapshot(
                statusMessage: "正在生成图片",
                progressStage: .renderingImage
            )

        let projection =
            MemoMarkiOSQueueDiagnosticsProjectionEngine
            .progressProjection(
                for: backgroundSnapshot,
                language: .english
            )

        #expect(
            projection.statusMessage
            == "Creating image · family.jpg"
        )
    }

    @Test("Event display projection deduplicates repeated messaging, ignores unmapped stages, and limits output")
    func eventDisplayProjectionDeduplicatesRepeatedMessagingIgnoresUnmappedStagesAndLimitsOutput() {

        let events = [
            MemoMarkShareDiagnosticEvent(
                timestamp:
                    Date(
                        timeIntervalSince1970: 10
                    ),
                stage: .extensionRequestPersisted,
                message: "persisted"
            ),
            MemoMarkShareDiagnosticEvent(
                timestamp:
                    Date(
                        timeIntervalSince1970: 20
                    ),
                stage: .extensionRequestPersisted,
                message: "persisted again"
            ),
            MemoMarkShareDiagnosticEvent(
                timestamp:
                    Date(
                        timeIntervalSince1970: 30
                    ),
                stage: .appEnqueueCreated,
                message: "queued"
            ),
            MemoMarkShareDiagnosticEvent(
                timestamp:
                    Date(
                        timeIntervalSince1970: 40
                    ),
                stage: .extensionHandoffFailed,
                message: "handoff failed"
            ),
            MemoMarkShareDiagnosticEvent(
                timestamp:
                    Date(
                        timeIntervalSince1970: 50
                    ),
                stage: .liveActivityPayloadTerminal,
                message: "done"
            ),
            MemoMarkShareDiagnosticEvent(
                timestamp:
                    Date(
                        timeIntervalSince1970: 60
                    ),
                stage: .extensionInput,
                message: "ignored"
            )
        ]

        let projections =
            MemoMarkiOSQueueDiagnosticsProjectionEngine
            .eventDisplayProjections(
                from: events
            )

        #expect(projections.count == 3)
        #expect(
            projections.map(\.title)
            == [
                "处理完成",
                "等待时光记接手",
                "进入处理队列"
            ]
        )
        #expect(
            projections.map(\.message)
            == [
                "已完成处理，结果会出现在目标相册。",
                "照片已接收，如未自动切换，可手动打开时光记继续。",
                "照片会按当前默认风格生成并保存。"
            ]
        )
    }

    @Test("Event display projection uses the explicit interface language")
    func eventDisplayProjectionUsesExplicitInterfaceLanguage() {

        let events = [
            MemoMarkShareDiagnosticEvent(
                timestamp: Date(timeIntervalSince1970: 10),
                stage: .liveActivityPayloadTerminal,
                message: "done"
            ),
            MemoMarkShareDiagnosticEvent(
                timestamp: Date(timeIntervalSince1970: 20),
                stage: .appEnqueueCreated,
                message: "queued"
            )
        ]

        let projections =
            MemoMarkiOSQueueDiagnosticsProjectionEngine
            .eventDisplayProjections(
                from: events,
                language: .japanese
            )

        #expect(
            projections.map(\.title)
            == [
                "処理キューに追加しました",
                "処理が完了しました"
            ]
        )
        #expect(
            projections.map(\.message)
            == [
                "現在のデフォルト設定で写真を作成して保存します。",
                "処理が完了しました。結果は指定したアルバムに保存されます。"
            ]
        )
    }
}

private extension QueueStatusProjectionEngineTests {

    func makeBackgroundSnapshot(
        title: String = "今天 10:00（2张）",
        presentationState: MemoMarkBackgroundPresentationState = .active,
        statusMessage: String = "正在处理 1 / 2",
        progressStage: BatchTaskProgressStage? = nil,
        queueLines: [String] = ["队列中的照片"],
        overflowQueueCount: Int = 0,
        failedCount: Int = 0,
        progressFraction: Double = 0.45,
        pipelineSteps: [MemoMarkBackgroundPipelineStep] = [
            MemoMarkBackgroundPipelineStep(
                title: "读取原图",
                state: .active
            )
        ],
        updatedAt: Date = Date(
            timeIntervalSince1970: 150
        )
    ) -> MemoMarkBackgroundJobSnapshot {

        MemoMarkBackgroundJobSnapshot(
            jobID: UUID(),
            title: title,
            launchSource: .shareExtension,
            presentationState: presentationState,
            jobState: .running,
            currentPhase: .exporting,
            currentPhaseTitle: "生成图片",
            currentFileName: "family.jpg",
            statusMessage: statusMessage,
            progressStage: progressStage,
            displayMode: .singleTask,
            pipelineSteps: pipelineSteps,
            activePipelineStepIndex: 0,
            queueLines: queueLines,
            overflowQueueCount: overflowQueueCount,
            completedCount: 1,
            failedCount: failedCount,
            totalCount: 2,
            progressFraction: progressFraction,
            canRetryFailures: false,
            hasOnlyUnsupportedFailures: false,
            updatedAt: updatedAt
        )
    }
}
#endif
