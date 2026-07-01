#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Queue status projection engine")
struct QueueStatusProjectionEngineTests {

    @Test("Header projection surfaces corrupted persistence recovery when no queue snapshot exists")
    func headerProjectionSurfacesCorruptedPersistenceRecoveryWhenNoQueueSnapshotExists() {

        let diagnosticsSnapshot =
            PhotoMemoiOSProcessingDiagnosticsSnapshot(
                events: [],
                shareDiagnosticsAvailability:
                    .corrupted
            )

        let projection =
            PhotoMemoiOSQueueDiagnosticsProjectionEngine
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
            PhotoMemoShareDiagnosticEvent(
                timestamp:
                    Date(
                        timeIntervalSince1970: 200
                    ),
                stage: .extensionSourcePrepare,
                message: "prepare"
            )
        ]

        let projection =
            PhotoMemoiOSQueueDiagnosticsProjectionEngine
            .headerProjection(
                backgroundSnapshot:
                    backgroundSnapshot,
                processingDiagnosticsSnapshot:
                    PhotoMemoiOSProcessingDiagnosticsSnapshot(),
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
                progressFraction: 1.2,
                pipelineSteps: [
                    PhotoMemoBackgroundPipelineStep(
                        title: "读取原图",
                        state: .completed
                    ),
                    PhotoMemoBackgroundPipelineStep(
                        title: "生成图片",
                        state: .needsAttention
                    )
                ]
            )

        let projection =
            PhotoMemoiOSQueueDiagnosticsProjectionEngine
            .progressProjection(
                for: backgroundSnapshot
            )

        #expect(
            projection.title
            == "家庭相册 需要查看"
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

    @Test("Event display projection deduplicates repeated messaging, ignores unmapped stages, and limits output")
    func eventDisplayProjectionDeduplicatesRepeatedMessagingIgnoresUnmappedStagesAndLimitsOutput() {

        let events = [
            PhotoMemoShareDiagnosticEvent(
                timestamp:
                    Date(
                        timeIntervalSince1970: 10
                    ),
                stage: .extensionRequestPersisted,
                message: "persisted"
            ),
            PhotoMemoShareDiagnosticEvent(
                timestamp:
                    Date(
                        timeIntervalSince1970: 20
                    ),
                stage: .extensionRequestPersisted,
                message: "persisted again"
            ),
            PhotoMemoShareDiagnosticEvent(
                timestamp:
                    Date(
                        timeIntervalSince1970: 30
                    ),
                stage: .appEnqueueCreated,
                message: "queued"
            ),
            PhotoMemoShareDiagnosticEvent(
                timestamp:
                    Date(
                        timeIntervalSince1970: 40
                    ),
                stage: .extensionHandoffFailed,
                message: "handoff failed"
            ),
            PhotoMemoShareDiagnosticEvent(
                timestamp:
                    Date(
                        timeIntervalSince1970: 50
                    ),
                stage: .liveActivityPayloadTerminal,
                message: "done"
            ),
            PhotoMemoShareDiagnosticEvent(
                timestamp:
                    Date(
                        timeIntervalSince1970: 60
                    ),
                stage: .extensionInput,
                message: "ignored"
            )
        ]

        let projections =
            PhotoMemoiOSQueueDiagnosticsProjectionEngine
            .eventDisplayProjections(
                from: events
            )

        #expect(projections.count == 3)
        #expect(
            projections.map(\.title)
            == [
                "处理完成",
                "等待 PhotoMemo 接力",
                "进入处理队列"
            ]
        )
        #expect(
            projections.map(\.message)
            == [
                "已完成处理，结果会出现在目标相册。",
                "原图已接收，主程序会在可用时继续处理。",
                "照片会按当前默认风格生成并保存。"
            ]
        )
    }
}

private extension QueueStatusProjectionEngineTests {

    func makeBackgroundSnapshot(
        title: String = "今天 10:00（2张）",
        presentationState: PhotoMemoBackgroundPresentationState = .active,
        statusMessage: String = "正在处理 1 / 2",
        queueLines: [String] = ["队列中的照片"],
        overflowQueueCount: Int = 0,
        progressFraction: Double = 0.45,
        pipelineSteps: [PhotoMemoBackgroundPipelineStep] = [
            PhotoMemoBackgroundPipelineStep(
                title: "读取原图",
                state: .active
            )
        ],
        updatedAt: Date = Date(
            timeIntervalSince1970: 150
        )
    ) -> PhotoMemoBackgroundJobSnapshot {

        PhotoMemoBackgroundJobSnapshot(
            jobID: UUID(),
            title: title,
            launchSource: .shareExtension,
            presentationState: presentationState,
            jobState: .running,
            currentPhase: .exporting,
            currentPhaseTitle: "生成图片",
            currentFileName: "family.jpg",
            statusMessage: statusMessage,
            displayMode: .singleTask,
            pipelineSteps: pipelineSteps,
            activePipelineStepIndex: 0,
            queueLines: queueLines,
            overflowQueueCount: overflowQueueCount,
            completedCount: 1,
            failedCount: 0,
            totalCount: 2,
            progressFraction: progressFraction,
            canRetryFailures: false,
            updatedAt: updatedAt
        )
    }
}
#endif
