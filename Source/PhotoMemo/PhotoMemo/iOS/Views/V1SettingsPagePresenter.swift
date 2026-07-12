#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1SettingsPagePresentation:
    Equatable {

    let overviewItems:
        [V1TaskOverviewItemPresentation]

    let currentTask:
        V1SettingsCurrentTaskPresentation

    let historyRows:
        [V1SettingsHistoryRowPresentation]
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
    let configurationName: String
    let templateName: String
    let previewSourceURL: URL?
    let stepRows:
        [V1TaskPipelineStepPresentation]
    let photoLibraryLink:
        V1TaskPhotoLibraryLink?
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
    let templateName: String?
    let previewSourceURL: URL?
    let photoLibraryLink:
        V1TaskPhotoLibraryLink?
}

struct V1TaskPhotoLibraryLink:
    Equatable,
    Hashable {

    let albumName: String?
    let assetIdentifier: String?

    var displayTitle: String {
        guard let albumName,
              !albumName.isEmpty else {
            return "系统图库"
        }

        return albumName
    }
}

struct V1TaskOverviewItemPresentation:
    Identifiable,
    Equatable {

    let id: String
    let title: String
    let value: String
    let unit: String
    let symbolName: String
    let tint:
        PhotoMemoiOSQueueDiagnosticsTint
}

struct V1TaskPipelineStepPresentation:
    Identifiable,
    Equatable {

    let id: String
    let title: String
    let statusText: String
    let timeText: String?
    let symbolName: String
    let tint:
        PhotoMemoiOSQueueDiagnosticsTint
    let emphasizesTitle: Bool
}

enum V1SettingsPagePresenter {

    static func presentation(
        header:
            PhotoMemoiOSQueueDiagnosticsHeaderProjection,
        snapshot:
            PhotoMemoBackgroundJobSnapshot?,
        recoveryMessage: String?,
        events:
            [PhotoMemoShareDiagnosticEvent],
        overview:
            PhotoMemoBackgroundTaskOverview = .empty,
        recentJobs:
            [PhotoMemoBackgroundJobSummary] = [],
        fallbackConfigurationName: String = "当前配置"
    ) -> V1SettingsPagePresentation {
        V1SettingsPagePresentation(
            overviewItems:
                overviewItems(
                    from: overview
                ),
            currentTask:
                currentTaskPresentation(
                    header: header,
                    snapshot: snapshot,
                    recoveryMessage: recoveryMessage,
                    fallbackConfigurationName:
                        fallbackConfigurationName
                ),
            historyRows:
                historyRows(
                    from: events,
                    recentJobs:
                        recentJobs
                )
        )
    }
}

private extension V1SettingsPagePresenter {

    static func currentTaskPresentation(
        header:
            PhotoMemoiOSQueueDiagnosticsHeaderProjection,
        snapshot:
            PhotoMemoBackgroundJobSnapshot?,
        recoveryMessage: String?,
        fallbackConfigurationName: String
    ) -> V1SettingsCurrentTaskPresentation {
        if let snapshot {
            let progressProjection =
                PhotoMemoiOSQueueDiagnosticsProjectionEngine
                .progressProjection(
                    for: snapshot
                )

            return V1SettingsCurrentTaskPresentation(
                headline:
                    snapshot.configurationName,
                subtitleText:
                    "\(displayTemplateName(snapshot.templateName)) 预设",
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
                    progressProjection.tint,
                updatedAt:
                    snapshot.updatedAt,
                progressFraction:
                    min(
                        max(
                            snapshot.progressFraction,
                            0
                        ),
                        1
                    ),
                configurationName:
                    snapshot.configurationName,
                templateName:
                    displayTemplateName(
                        snapshot.templateName
                    ),
                previewSourceURL:
                    snapshot.previewSourceURL,
                stepRows:
                    stepRows(
                        from: snapshot
                    ),
                photoLibraryLink:
                    photoLibraryLink(
                        albumName:
                            snapshot.savedAlbumName,
                        assetIdentifier:
                            snapshot
                            .savedAssetIdentifier
                    )
            )
        }

        return V1SettingsCurrentTaskPresentation(
            headline:
                header.headline,
            subtitleText:
                "等待 Apple Photos 分享照片",
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
            progressFraction: nil,
            configurationName:
                fallbackConfigurationName,
            templateName:
                "Classic White",
            previewSourceURL: nil,
            stepRows:
                waitingStepRows,
            photoLibraryLink: nil
        )
    }

    static func overviewItems(
        from overview:
            PhotoMemoBackgroundTaskOverview
    ) -> [V1TaskOverviewItemPresentation] {
        [
            V1TaskOverviewItemPresentation(
                id: "active",
                title: "进行中",
                value:
                    "\(overview.activeJobCount)",
                unit: "任务",
                symbolName:
                    "arrow.trianglehead.2.clockwise.circle.fill",
                tint: .blue
            ),
            V1TaskOverviewItemPresentation(
                id: "completed",
                title: "已完成",
                value:
                    "\(overview.completedPhotoCount)",
                unit: "张照片",
                symbolName:
                    "checkmark.circle.fill",
                tint: .green
            ),
            V1TaskOverviewItemPresentation(
                id: "failed",
                title: "失败",
                value:
                    "\(overview.failedPhotoCount)",
                unit: "张照片",
                symbolName:
                    "xmark.circle.fill",
                tint: .secondary
            ),
            V1TaskOverviewItemPresentation(
                id: "today",
                title: "今天",
                value:
                    "\(overview.todayProcessingCount)",
                unit: "次处理",
                symbolName:
                    "clock.fill",
                tint: .orange
            )
        ]
    }

    static var waitingStepRows:
        [V1TaskPipelineStepPresentation] {
        [
            V1TaskPipelineStepPresentation(
                id: "waiting",
                title: "等待照片",
                statusText: "等待中",
                timeText: nil,
                symbolName: "circle",
                tint: .secondary,
                emphasizesTitle: false
            )
        ]
    }

    static func stepRows(
        from snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> [V1TaskPipelineStepPresentation] {
        snapshot.pipelineSteps
            .enumerated()
            .map { index, step in
                V1TaskPipelineStepPresentation(
                    id:
                        "\(index)-\(step.title)",
                    title:
                        step.title,
                    statusText:
                        stepStatusText(
                            for: step.state
                        ),
                    timeText:
                        stepTimeText(
                            for: step.state,
                            updatedAt:
                                snapshot.updatedAt
                        ),
                    symbolName:
                        stepSymbolName(
                            for: step.state
                        ),
                    tint:
                        stepTint(
                            for: step.state
                        ),
                    emphasizesTitle:
                        step.state == .active
                )
            }
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
            [PhotoMemoShareDiagnosticEvent],
        recentJobs:
            [PhotoMemoBackgroundJobSummary]
    ) -> [V1SettingsHistoryRowPresentation] {
        if !recentJobs.isEmpty {
            return recentJobs.map {
                recentJobRow(
                    from: $0
                )
            }
        }

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
                        ),
                    templateName: nil,
                    previewSourceURL: nil,
                    photoLibraryLink: nil
                )
            }
            .prefix(6)
            .map { $0 }
    }

    static func recentJobRow(
        from summary:
            PhotoMemoBackgroundJobSummary
    ) -> V1SettingsHistoryRowPresentation {
        V1SettingsHistoryRowPresentation(
            id: summary.jobID,
            timestamp:
                summary.updatedAt,
            title:
                summary.configurationName,
            detailText:
                "\(displayTemplateName(summary.templateName)) 预设 · \(summary.totalCount) 张照片",
            statusText:
                summaryStatusText(
                    summary
                ),
            itemCountText:
                photoCountText(
                    count: summary.totalCount
                ),
            symbolName:
                summarySymbolName(
                    summary
                ),
            tint:
                summaryTint(
                    summary
                ),
            templateName:
                displayTemplateName(
                    summary.templateName
                ),
            previewSourceURL:
                summary.previewSourceURL,
            photoLibraryLink:
                photoLibraryLink(
                    albumName:
                        summary.savedAlbumName,
                    assetIdentifier:
                        summary
                        .savedAssetIdentifier,
                    allowsRecentFallback: true
                )
        )
    }

    static func photoLibraryLink(
        albumName: String?,
        assetIdentifier: String?,
        allowsRecentFallback: Bool = false
    ) -> V1TaskPhotoLibraryLink? {
        let trimmedAlbumName =
            albumName?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        let trimmedAssetIdentifier =
            assetIdentifier?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard allowsRecentFallback
            || trimmedAlbumName?.isEmpty == false
            || trimmedAssetIdentifier?.isEmpty == false else {
            return nil
        }

        return V1TaskPhotoLibraryLink(
            albumName:
                trimmedAlbumName?.isEmpty == false
                ? trimmedAlbumName
                : nil,
            assetIdentifier:
                trimmedAssetIdentifier?.isEmpty == false
                ? trimmedAssetIdentifier
                : nil
        )
    }

    static func displayTemplateName(
        _ templateName: String
    ) -> String {
        let trimmedName =
            templateName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        switch trimmedName {
        case "Classic White":
            return "基础白"
        default:
            return trimmedName.isEmpty
                ? "基础白"
                : trimmedName
        }
    }

    static func summaryStatusText(
        _ summary:
            PhotoMemoBackgroundJobSummary
    ) -> String {
        switch summary.presentationState {
        case .active:
            return "处理中"
        case .needsAttention:
            return summary.failedCount > 0
                ? "需查看"
                : "已中断"
        case .completed:
            return "已完成"
        }
    }

    static func summarySymbolName(
        _ summary:
            PhotoMemoBackgroundJobSummary
    ) -> String {
        switch summary.presentationState {
        case .active:
            return "arrow.trianglehead.2.clockwise.circle.fill"
        case .needsAttention:
            return "exclamationmark.triangle.fill"
        case .completed:
            return "checkmark.circle.fill"
        }
    }

    static func summaryTint(
        _ summary:
            PhotoMemoBackgroundJobSummary
    ) -> PhotoMemoiOSQueueDiagnosticsTint {
        switch summary.presentationState {
        case .active:
            return .blue
        case .needsAttention:
            return .orange
        case .completed:
            return .green
        }
    }

    static func stepStatusText(
        for state:
            PhotoMemoBackgroundPipelineStepState
    ) -> String {
        switch state {
        case .pending:
            return "等待中"
        case .active:
            return "处理中..."
        case .completed:
            return "已完成"
        case .needsAttention:
            return "需查看"
        }
    }

    static func stepTimeText(
        for state:
            PhotoMemoBackgroundPipelineStepState,
        updatedAt: Date
    ) -> String? {
        switch state {
        case .pending:
            return nil
        case .active,
             .completed,
             .needsAttention:
            return updatedAt.formatted(
                date: .omitted,
                time: .shortened
            )
        }
    }

    static func stepSymbolName(
        for state:
            PhotoMemoBackgroundPipelineStepState
    ) -> String {
        switch state {
        case .pending:
            return "circle.fill"
        case .active:
            return "arrow.trianglehead.2.clockwise.circle.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .needsAttention:
            return "exclamationmark.triangle.fill"
        }
    }

    static func stepTint(
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
