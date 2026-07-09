#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1SettingsPagePresentation:
    Equatable {

    let currentTask:
        V1SettingsCurrentTaskPresentation

    let historyRows:
        [V1SettingsHistoryRowPresentation]

    let canClearCompletedHistory: Bool
}

struct V1SettingsCurrentTaskPresentation:
    Equatable {

    let headline: String
    let subtitleText: String
    let statusText: String
    let itemCountText: String?
    let progressText: String?
    let detailText: String
    let symbolName: String
    let thumbnailSymbolName: String
    let tint:
        PhotoMemoiOSQueueDiagnosticsTint
    let updatedAt: Date?
    let progressFraction: Double?
}

struct V1SettingsHistoryRowPresentation:
    Identifiable,
    Equatable {

    let id: UUID
    let timestamp: Date
    let title: String
    let detailText: String
    let statusText: String
    let itemCountText: String?
    let symbolName: String
    let tint:
        PhotoMemoiOSQueueDiagnosticsTint
}

enum V1SettingsPagePresenter {

    static func presentation(
        header:
            PhotoMemoiOSQueueDiagnosticsHeaderProjection,
        snapshot:
            PhotoMemoBackgroundJobSnapshot?,
        recoveryMessage: String?,
        events:
            [PhotoMemoShareDiagnosticEvent]
    ) -> V1SettingsPagePresentation {
        V1SettingsPagePresentation(
            currentTask:
                currentTaskPresentation(
                    header: header,
                    snapshot: snapshot,
                    recoveryMessage: recoveryMessage
                ),
            historyRows:
                historyRows(
                    from: events
                ),
            canClearCompletedHistory:
                canClearHistory(snapshot)
        )
    }
}

private extension V1SettingsPagePresenter {

    static func currentTaskPresentation(
        header:
            PhotoMemoiOSQueueDiagnosticsHeaderProjection,
        snapshot:
            PhotoMemoBackgroundJobSnapshot?,
        recoveryMessage: String?
    ) -> V1SettingsCurrentTaskPresentation {
        if let snapshot {
            return V1SettingsCurrentTaskPresentation(
                headline:
                    PhotoMemoiOSQueueDiagnosticsProjectionEngine
                    .progressProjection(
                        for: snapshot
                    )
                    .title,
                subtitleText:
                    header.subheadline,
                statusText:
                    snapshotStatusText(
                        snapshot
                    ),
                itemCountText:
                    photoCountText(
                        count: snapshot.totalCount
                    ),
                progressText:
                    progressText(
                        snapshot
                    ),
                detailText:
                    snapshot.statusMessage,
                symbolName:
                    header.symbolName,
                thumbnailSymbolName:
                    thumbnailSymbolName(
                        snapshot.presentationState
                    ),
                tint:
                    header.tint,
                updatedAt:
                    snapshot.updatedAt,
                progressFraction:
                    min(
                        max(
                            snapshot.progressFraction,
                            0
                        ),
                        1
                    )
            )
        }

        return V1SettingsCurrentTaskPresentation(
            headline:
                header.headline,
            subtitleText:
                header.subheadline,
            statusText:
                headerStatusText(
                    header
                ),
            itemCountText: nil,
            progressText: nil,
            detailText:
                recoveryMessage
                ?? header.subheadline,
            symbolName:
                header.symbolName,
            thumbnailSymbolName:
                "square.stack.3d.down.forward.fill",
            tint:
                header.tint,
            updatedAt: nil,
            progressFraction: nil
        )
    }

    static func canClearHistory(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot?
    ) -> Bool {
        guard let snapshot else {
            return false
        }

        return snapshot.overflowQueueCount > 0
            || snapshot.presentationState != .active
    }

    static func progressText(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> String? {
        guard snapshot.totalCount > 0 else {
            return nil
        }

        let completedText =
            "已完成 \(snapshot.completedCount) / \(snapshot.totalCount)"

        guard snapshot.failedCount > 0 else {
            return completedText
        }

        if snapshot.completedCount > 0 {
            return "\(completedText) · 仍有 \(snapshot.failedCount) 张需处理"
        }

        if snapshot.hasOnlyUnsupportedFailures {
            return "\(snapshot.failedCount) 张暂不支持"
        }

        return "\(snapshot.failedCount) 张需要处理"
    }

    static func snapshotStatusText(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> String {
        snapshot.feedbackState
            .displayTitle
    }

    static func headerStatusText(
        _ header:
            PhotoMemoiOSQueueDiagnosticsHeaderProjection
    ) -> String {
        if header.headline.contains(
            "恢复"
        ) {
            return "需要恢复"
        }

        switch header.tint {
        case .blue:
            return "处理中"
        case .orange:
            return "需查看"
        case .green:
            return "已完成"
        case .secondary:
            return "等待中"
        }
    }

    static func thumbnailSymbolName(
        _ state:
            PhotoMemoBackgroundPresentationState
    ) -> String {
        switch state {
        case .active:
            return "photo.stack.fill"
        case .needsAttention:
            return "exclamationmark.bubble.fill"
        case .completed:
            return "checkmark.rectangle.stack.fill"
        }
    }

    static func historyRows(
        from events:
            [PhotoMemoShareDiagnosticEvent]
    ) -> [V1SettingsHistoryRowPresentation] {
        var seenKeys = Set<String>()

        return events
            .reversed()
            .compactMap { event in
                guard let title =
                    historyDisplayTitle(
                        for: event
                    )
                else {
                    return nil
                }

                let detailText =
                    historyDisplayMessage(
                        for: event
                    )
                let dedupeKey =
                    "\(title)|\(detailText)"

                guard !seenKeys.contains(
                    dedupeKey
                ) else {
                    return nil
                }

                seenKeys.insert(
                    dedupeKey
                )

                return V1SettingsHistoryRowPresentation(
                    id: event.id,
                    timestamp:
                        event.timestamp,
                    title: title,
                    detailText:
                        detailText,
                    statusText:
                        eventStatusText(
                            event.stage
                        ),
                    itemCountText:
                        photoCountText(
                            message:
                                event.message
                        ),
                    symbolName:
                        eventSymbolName(
                            event.stage
                        ),
                    tint:
                        eventTint(
                            event.stage
                        )
                )
            }
            .prefix(6)
            .map { $0 }
    }

    static func eventStatusText(
        _ stage:
            PhotoMemoShareDiagnosticStage
    ) -> String {
        switch stage {
        case .extensionSourcePrepare:
            return "准备中"
        case .extensionSourceReady,
             .extensionPersisted,
             .extensionRequestPersisted,
             .appDrain:
            return "处理中"
        case .appRequestValidated,
             .appEnqueueCreated:
            return "已入队"
        case .appRequestDropped:
            return "已跳过"
        case .extensionSourceUnavailable,
             .extensionHandoffFailed,
             .extensionHandoffUnconfirmed:
            return "需查看"
        case .liveActivityRequestCreated:
            return "已显示"
        case .liveActivityPayloadTerminal:
            return "已完成"
        default:
            if isFailureStage(
                stage
            ) {
                return "需查看"
            }

            return "处理中"
        }
    }

    static func eventSymbolName(
        _ stage:
            PhotoMemoShareDiagnosticStage
    ) -> String {
        switch stage {
        case .liveActivityPayloadTerminal:
            return "checkmark.circle.fill"
        case .extensionSourceUnavailable,
             .extensionHandoffFailed,
             .extensionHandoffUnconfirmed:
            return "exclamationmark.triangle.fill"
        case .extensionSourcePrepare:
            return "icloud.and.arrow.down"
        case .appEnqueueCreated:
            return "photo.stack"
        default:
            return "circle.fill"
        }
    }

    static func eventTint(
        _ stage:
            PhotoMemoShareDiagnosticStage
    ) -> PhotoMemoiOSQueueDiagnosticsTint {
        switch stage {
        case .liveActivityPayloadTerminal:
            return .green
        case .extensionSourceUnavailable,
             .extensionHandoffFailed,
             .extensionHandoffUnconfirmed:
            return .orange
        case .appRequestDropped:
            return .secondary
        default:
            return .blue
        }
    }

    static func photoCountText(
        count: Int
    ) -> String? {
        guard count > 0 else {
            return nil
        }

        return "\(count) 张照片"
    }

    static func photoCountText(
        message: String
    ) -> String? {
        if let count =
            intValue(
                after: "tasks=",
                in: message
            ) {
            return photoCountText(
                count: count
            )
        }

        if let count =
            intValue(
                after: "unique=",
                in: message
            ) {
            return photoCountText(
                count: count
            )
        }

        return nil
    }

    static func intValue(
        after token: String,
        in text: String
    ) -> Int? {
        guard let range =
            text.range(
                of: token
            ) else {
            return nil
        }

        let suffix =
            text[
                range.upperBound...
            ]
        let digits =
            suffix.prefix {
                $0.isNumber
            }

        guard !digits.isEmpty else {
            return nil
        }

        return Int(
            String(digits)
        )
    }

    static func historyDisplayTitle(
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
            return "等待时光记接力"
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

    static func historyDisplayMessage(
        for event:
            PhotoMemoShareDiagnosticEvent
    ) -> String {
        switch event.stage {
        case .extensionRequestPersisted,
             .extensionPersisted:
            return "原图已暂存，等待时光记处理。"
        case .extensionSourcePrepare:
            return "正在向系统请求原图数据，等待 iCloud 缓存到本地。"
        case .extensionSourceReady:
            return "原图已经可读取，正在继续交给时光记。"
        case .extensionSourceUnavailable:
            return "系统暂时没有提供完整原图，请稍后重试或先在相册打开原图。"
        case .extensionHandoffUnconfirmed,
             .extensionHandoffFailed:
            return "原图已接收，主程序会在可用时继续处理。"
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
