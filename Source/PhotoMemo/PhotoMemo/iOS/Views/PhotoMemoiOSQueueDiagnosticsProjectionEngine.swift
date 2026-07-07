#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

enum PhotoMemoiOSQueueDiagnosticsTint:
    Hashable {

    case blue

    case orange

    case green

    case secondary
}

#if canImport(SwiftUI)
extension PhotoMemoiOSQueueDiagnosticsTint {

    var color: Color {

        switch self {
        case .blue:
            return .blue
        case .orange:
            return .orange
        case .green:
            return .green
        case .secondary:
            return .secondary
        }
    }
}
#endif

struct PhotoMemoiOSQueueDiagnosticsHeaderProjection:
    Hashable {

    let headline: String

    let subheadline: String

    let symbolName: String

    let tint:
        PhotoMemoiOSQueueDiagnosticsTint
}

struct PhotoMemoiOSQueuePipelineStepProjection:
    Hashable {

    let title: String

    let symbolName: String

    let tint:
        PhotoMemoiOSQueueDiagnosticsTint

    let emphasizesTitle: Bool

    let usesSecondaryTitleStyle: Bool
}

struct PhotoMemoiOSQueueProgressProjection:
    Hashable {

    let title: String

    let symbolName: String

    let tint:
        PhotoMemoiOSQueueDiagnosticsTint

    let progressFraction: Double

    let progressPercentText: String

    let statusMessage: String

    let showsPipeline: Bool

    let queueLines: [String]

    let overflowQueueCount: Int

    let pipelineSteps:
        [PhotoMemoiOSQueuePipelineStepProjection]
}

struct PhotoMemoiOSQueueDiagnosticEventProjection:
    Identifiable,
    Hashable {

    let id: UUID

    let timestamp: Date

    let title: String

    let message: String
}

enum PhotoMemoiOSQueueDiagnosticsProjectionEngine {

    static func headerProjection(
        backgroundSnapshot:
            PhotoMemoBackgroundJobSnapshot?,
        processingDiagnosticsSnapshot:
            PhotoMemoiOSProcessingDiagnosticsSnapshot,
        events:
            [PhotoMemoShareDiagnosticEvent]
    ) -> PhotoMemoiOSQueueDiagnosticsHeaderProjection {

        if let backgroundSnapshot,
           !shouldPrioritizeLatestShareDiagnostic(
                events: events,
                over: backgroundSnapshot
           ) {
            let progressProjection =
                progressProjection(
                    for: backgroundSnapshot
                )

            return PhotoMemoiOSQueueDiagnosticsHeaderProjection(
                headline:
                    progressProjection.title,
                subheadline:
                    backgroundSnapshot.statusMessage,
                symbolName:
                    progressProjection.symbolName,
                tint:
                    progressProjection.tint
            )
        }

        guard let latestEvent =
            events.last else {
            if processingDiagnosticsSnapshot
                .hasCorruptedPersistence {
                return PhotoMemoiOSQueueDiagnosticsHeaderProjection(
                    headline:
                        "共享进度记录需要恢复",
                    subheadline:
                        processingDiagnosticsSnapshot
                        .recoveryMessage
                        ?? "共享一次照片后，这里会显示接收、入队和进度创建结果。",
                    symbolName:
                        "exclamationmark.triangle.fill",
                    tint:
                        .orange
                )
            }

            return PhotoMemoiOSQueueDiagnosticsHeaderProjection(
                headline:
                    "等待下一次分享",
                subheadline:
                    "分享一次照片后，这里会显示接收、入队和进度创建结果。",
                symbolName:
                    "square.stack.3d.down.forward",
                tint:
                    .secondary
            )
        }

        return PhotoMemoiOSQueueDiagnosticsHeaderProjection(
            headline:
                diagnosticsHeadline(
                    latestEvent: latestEvent,
                    events: events
                ),
            subheadline:
                diagnosticsSubheadline(
                    processingDiagnosticsSnapshot:
                        processingDiagnosticsSnapshot,
                    events: events
                ),
            symbolName:
                diagnosticsSymbolName(
                    latestEvent: latestEvent,
                    processingDiagnosticsSnapshot:
                        processingDiagnosticsSnapshot,
                    events: events
                ),
            tint:
                diagnosticsTint(
                    latestEvent: latestEvent,
                    processingDiagnosticsSnapshot:
                        processingDiagnosticsSnapshot,
                    events: events
                )
        )
    }

    static func progressProjection(
        for snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> PhotoMemoiOSQueueProgressProjection {

        let clampedProgress =
            min(
                max(
                    snapshot.progressFraction,
                    0
                ),
                1
            )

        return PhotoMemoiOSQueueProgressProjection(
            title:
                progressTitle(snapshot),
            symbolName:
                progressSymbolName(snapshot),
            tint:
                progressTint(snapshot),
            progressFraction:
                clampedProgress,
            progressPercentText:
                "\(Int(round(clampedProgress * 100)))%",
            statusMessage:
                snapshot.statusMessage,
            showsPipeline:
                snapshot.overflowQueueCount == 0
                && snapshot.queueLines.count <= 1,
            queueLines:
                snapshot.queueLines,
            overflowQueueCount:
                snapshot.overflowQueueCount,
            pipelineSteps:
                snapshot.pipelineSteps.map {
                    pipelineStepProjection(
                        for: $0
                    )
                }
        )
    }

    static func eventDisplayProjections(
        from events:
            [PhotoMemoShareDiagnosticEvent]
    ) -> [PhotoMemoiOSQueueDiagnosticEventProjection] {

        var seenKeys = Set<String>()

        return events
            .reversed()
            .compactMap { event in
                guard let title =
                    diagnosticDisplayTitle(
                        for: event
                    )
                else {
                    return nil
                }

                let message =
                    diagnosticDisplayMessage(
                        for: event
                    )
                let dedupeKey =
                    "\(title)|\(message)"

                guard !seenKeys.contains(dedupeKey) else {
                    return nil
                }

                seenKeys.insert(dedupeKey)

                return PhotoMemoiOSQueueDiagnosticEventProjection(
                    id: event.id,
                    timestamp:
                        event.timestamp,
                    title: title,
                    message: message
                )
            }
            .prefix(3)
            .map { $0 }
    }
}

private extension PhotoMemoiOSQueueDiagnosticsProjectionEngine {

    static func shouldPrioritizeLatestShareDiagnostic(
        events:
            [PhotoMemoShareDiagnosticEvent],
        over snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> Bool {

        guard let latestEvent =
            events.last else {
            return false
        }

        guard latestEvent.timestamp
            > snapshot.updatedAt else {
            return false
        }

        switch snapshot.presentationState {
        case .completed:
            return true
        case .active,
             .needsAttention:
            return false
        }
    }

    static func diagnosticsHeadline(
        latestEvent:
            PhotoMemoShareDiagnosticEvent,
        events:
            [PhotoMemoShareDiagnosticEvent]
    ) -> String {

        if containsStage(
            .extensionSourcePrepare,
            in: events
        ),
           !containsAnyStage(
                [
                    .extensionSourceReady,
                    .appEnqueueCreated
                ],
                in: events
           ) {
            return "正在准备 iCloud 原图"
        }

        if containsStage(
            .appEnqueueCreated,
            in: events
        ) {
            return "照片已进入处理队列"
        }

        if containsStage(
            .extensionSourceReady,
            in: events
        ) {
            return "原图可用，正在交给 PhotoMemo"
        }

        if containsStage(
            .appOpenURLShare,
            in: events
        ) {
            return "PhotoMemo 已被唤起"
        }

        if isFailureStage(
            latestEvent.stage
        ) {
            return "这次分享需要查看"
        }

        return "正在交给 PhotoMemo"
    }

    static func diagnosticsSubheadline(
        processingDiagnosticsSnapshot:
            PhotoMemoiOSProcessingDiagnosticsSnapshot,
        events:
            [PhotoMemoShareDiagnosticEvent]
    ) -> String {

        guard !events.isEmpty else {
            if let recoveryMessage =
                processingDiagnosticsSnapshot
                .recoveryMessage {
                return recoveryMessage
            }

            return "分享一次照片后，这里会显示接收、入队和进度创建结果。"
        }

        if containsStage(
            .appRequestDropped,
            in: events
        ) {
            return "重复或失效的照片已跳过，原图不会被修改。"
        }

        if containsStage(
            .extensionSourcePrepare,
            in: events
        ),
           !containsAnyStage(
                [
                    .extensionSourceReady,
                    .appEnqueueCreated
                ],
                in: events
           ) {
            return "已向系统请求原图数据，等 iCloud 缓存到本地后继续。"
        }

        if containsStage(
            .extensionSourceReady,
            in: events
        ),
           !containsStage(
                .appEnqueueCreated,
                in: events
           ) {
            return "原图已经可读取，正在交给 PhotoMemo 主程序。"
        }

        if containsAnyStage(
            [
                .extensionHandoffUnconfirmed,
                .extensionHandoffFailed
            ],
            in: events
        ),
           !containsStage(
                .appEnqueueCreated,
                in: events
           ) {
            return "原图已经接收，等待 PhotoMemo 接力处理。"
        }

        if containsStage(
            .appEnqueueCreated,
            in: events
        ) {
            return "照片已经进入后台队列，完成后会写回系统相册。"
        }

        return "PhotoMemo 正在接收这次分享。"
    }

    static func diagnosticsSymbolName(
        latestEvent:
            PhotoMemoShareDiagnosticEvent,
        processingDiagnosticsSnapshot:
            PhotoMemoiOSProcessingDiagnosticsSnapshot,
        events:
            [PhotoMemoShareDiagnosticEvent]
    ) -> String {

        if containsStage(
            .liveActivityRequestCreated,
            in: events
        ) {
            return "checkmark.circle.fill"
        }

        if containsStage(
            .extensionSourcePrepare,
            in: events
        ),
           !containsStage(
                .extensionSourceReady,
                in: events
           ) {
            return "icloud.and.arrow.down"
        }

        if isFailureStage(
            latestEvent.stage
        ) {
            return "exclamationmark.triangle.fill"
        }

        if processingDiagnosticsSnapshot
            .hasCorruptedPersistence {
            return "exclamationmark.triangle.fill"
        }

        if events.isEmpty {
            return "square.stack.3d.down.forward"
        }

        return "arrow.trianglehead.2.clockwise.circle.fill"
    }

    static func diagnosticsTint(
        latestEvent:
            PhotoMemoShareDiagnosticEvent,
        processingDiagnosticsSnapshot:
            PhotoMemoiOSProcessingDiagnosticsSnapshot,
        events:
            [PhotoMemoShareDiagnosticEvent]
    ) -> PhotoMemoiOSQueueDiagnosticsTint {

        if containsStage(
            .liveActivityRequestCreated,
            in: events
        ) {
            return .green
        }

        if containsStage(
            .extensionSourcePrepare,
            in: events
        ),
           !containsStage(
                .extensionSourceReady,
                in: events
           ) {
            return .blue
        }

        if isFailureStage(
            latestEvent.stage
        ) {
            return .orange
        }

        if processingDiagnosticsSnapshot
            .hasCorruptedPersistence {
            return .orange
        }

        if events.isEmpty {
            return .secondary
        }

        return .blue
    }

    static func progressTitle(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> String {

        switch snapshot.feedbackState {
        case .preparing:
            return "\(snapshot.title) 准备中"
        case .processing:
            return "\(snapshot.title) 处理中"
        case .completed:
            return "\(snapshot.title) 已完成"
        case .partialSuccess:
            return "\(snapshot.title) 部分完成"
        case .needsAttention:
            return "\(snapshot.title) 需处理"
        case .unsupported:
            return "\(snapshot.title) 暂不支持"
        }
    }

    static func progressSymbolName(
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

    static func progressTint(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> PhotoMemoiOSQueueDiagnosticsTint {

        switch snapshot.feedbackState {
        case .preparing,
             .processing:
            return .blue
        case .partialSuccess,
             .needsAttention,
             .unsupported:
            return .orange
        case .completed:
            return .green
        }
    }

    static func pipelineStepProjection(
        for step:
            PhotoMemoBackgroundPipelineStep
    ) -> PhotoMemoiOSQueuePipelineStepProjection {

        PhotoMemoiOSQueuePipelineStepProjection(
            title: step.title,
            symbolName:
                pipelineSymbolName(
                    for: step.state
                ),
            tint:
                pipelineTint(
                    for: step.state
                ),
            emphasizesTitle:
                step.state == .active,
            usesSecondaryTitleStyle:
                step.state == .pending
        )
    }

    static func pipelineSymbolName(
        for state:
            PhotoMemoBackgroundPipelineStepState
    ) -> String {

        switch state {
        case .pending:
            return "circle"
        case .active:
            return "arrow.trianglehead.2.clockwise.circle.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .needsAttention:
            return "exclamationmark.triangle.fill"
        }
    }

    static func pipelineTint(
        for state:
            PhotoMemoBackgroundPipelineStepState
    ) -> PhotoMemoiOSQueueDiagnosticsTint {

        switch state {
        case .pending:
            return .secondary
        case .active:
            return .blue
        case .completed:
            return .green
        case .needsAttention:
            return .orange
        }
    }

    static func diagnosticDisplayTitle(
        for event:
            PhotoMemoShareDiagnosticEvent
    ) -> String? {

        switch event.stage {
        case .extensionRequestPersisted,
             .extensionPersisted:
            return "照片已接收"
        case .extensionSourcePrepare:
            return "准备 iCloud 原图"
        case .extensionSourceReady:
            return "原图可读取"
        case .extensionSourceUnavailable:
            return "原图暂时不可读取"
        case .extensionHandoffUnconfirmed,
             .extensionHandoffFailed:
            return "等待 PhotoMemo 接手"
        case .appDrain:
            return "检查待处理照片"
        case .appRequestValidated:
            return "照片检查完成"
        case .appEnqueueCreated:
            return "进入处理队列"
        case .appRequestDropped:
            return "已跳过重复照片"
        case .liveActivityRequestCreated:
            return "系统进度已显示"
        case .liveActivityPayloadTerminal:
            return "处理完成"
        default:
            return nil
        }
    }

    static func diagnosticDisplayMessage(
        for event:
            PhotoMemoShareDiagnosticEvent
    ) -> String {

        switch event.stage {
        case .extensionRequestPersisted,
             .extensionPersisted:
            return "原图已暂存，PhotoMemo 会按当前配置继续处理。"
        case .extensionSourcePrepare:
            return "正在向系统请求原图数据，等待 iCloud 缓存到本地。"
        case .extensionSourceReady:
            return "原图已经可读取，正在继续交给 PhotoMemo。"
        case .extensionSourceUnavailable:
            return "系统暂时没有提供完整原图，请稍后重试或先在相册打开原图。"
        case .extensionHandoffUnconfirmed,
             .extensionHandoffFailed:
            return "照片已接收，如未自动切换，可手动打开 PhotoMemo 继续。"
        case .appDrain:
            return "正在读取刚接收的照片。"
        case .appRequestValidated:
            return "照片可处理，准备加入后台队列。"
        case .appEnqueueCreated:
            return "照片会按当前默认风格生成并保存。"
        case .appRequestDropped:
            return "同一张照片已经在队列中，本次不会重复生成。"
        case .liveActivityRequestCreated:
            return "可以在系统进度区域查看处理状态。"
        case .liveActivityPayloadTerminal:
            return "已完成处理，结果会出现在目标相册。"
        default:
            return event.message
        }
    }

    static func containsStage(
        _ stage:
            PhotoMemoShareDiagnosticStage,
        in events:
            [PhotoMemoShareDiagnosticEvent]
    ) -> Bool {

        events.contains {
            $0.stage == stage
        }
    }

    static func containsAnyStage(
        _ stages:
            [PhotoMemoShareDiagnosticStage],
        in events:
            [PhotoMemoShareDiagnosticEvent]
    ) -> Bool {

        events.contains { event in
            stages.contains(
                event.stage
            )
        }
    }

    static func isFailureStage(
        _ stage:
            PhotoMemoShareDiagnosticStage
    ) -> Bool {

        stage.rawValue.contains(
            "failed"
        )
        || stage.rawValue.contains(
            "error"
        )
    }
}
#endif
