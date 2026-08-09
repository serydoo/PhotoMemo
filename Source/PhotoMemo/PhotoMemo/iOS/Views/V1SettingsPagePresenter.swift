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

enum V1TaskDisplayMode: Equatable {

    case waiting

    case processing

    case completed

    case needsAttention
}

struct V1SettingsCurrentTaskPresentation:
    Equatable {

    let jobID: UUID?

    let displayMode: V1TaskDisplayMode

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
    let canRetryFailures: Bool
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

    let jobID: UUID?
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

    var actionTitle: String {
        "打开照片 App"
    }

    var saveDestinationText: String {
        guard let albumName,
              !albumName.isEmpty else {
            return "已保存到系统图库"
        }

        return "已保存到「\(albumName)」"
    }

    var accessibilityHint: String {
        guard let albumName,
              !albumName.isEmpty else {
            return "打开照片 App 查看已保存的回忆"
        }

        return "打开照片 App；请在照片 App 中查看「\(albumName)」"
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
        let currentTask = currentTaskPresentation(
            header: header,
            snapshot: snapshot,
            recoveryMessage: recoveryMessage,
            fallbackConfigurationName:
                fallbackConfigurationName
        )
        let historyRows = historyRows(
            from: events,
            recentJobs: recentJobs
        )

        return V1SettingsPagePresentation(
            overviewItems:
                overviewItems(
                    from: overview
                ),
            currentTask: currentTask,
            historyRows:
                historyRows.filter { row in
                    guard currentTask.displayMode == .completed,
                          let currentJobID = currentTask.jobID else {
                        return true
                    }

                    return row.jobID != currentJobID
                }
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
                jobID: snapshot.jobID,
                displayMode:
                    displayMode(
                        for: snapshot.presentationState
                    ),
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
                canRetryFailures:
                    snapshot.canRetryFailures,
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
            jobID: nil,
            displayMode: displayMode(for: header),
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
            canRetryFailures: false,
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

    static func displayMode(
        for state: PhotoMemoBackgroundPresentationState
    ) -> V1TaskDisplayMode {
        switch state {
        case .active:
            return .processing
        case .completed:
            return .completed
        case .needsAttention:
            return .needsAttention
        }
    }

    static func displayMode(
        for header: PhotoMemoiOSQueueDiagnosticsHeaderProjection
    ) -> V1TaskDisplayMode {
        header.tint == .orange
            ? .needsAttention
            : .waiting
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
                        userFacingStepTitle(step.title),
                    statusText:
                        stepStatusText(
                            for: step.state
                        ),
                    timeText:
                        nil,
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
            "已完成 \(snapshot.completedCount) 张"
        let remainingCount = max(
            snapshot.totalCount - snapshot.completedCount,
            0
        )

        guard remainingCount > 0 else {
            return completedText
        }

        if snapshot.hasOnlyUnsupportedFailures {
            return "\(completedText) · 剩余 \(remainingCount) 张暂不支持"
        }

        return "\(completedText) · 剩余 \(remainingCount) 张"
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
            return "需要处理"
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
        from _:
            [PhotoMemoShareDiagnosticEvent],
        recentJobs:
            [PhotoMemoBackgroundJobSummary]
    ) -> [V1SettingsHistoryRowPresentation] {
        recentJobs
            .filter { summary in
                isSavedRecentJob(summary)
            }
            .map {
                recentJobRow(
                    from: $0
                )
            }
    }

    static func isSavedRecentJob(
        _ summary:
            PhotoMemoBackgroundJobSummary
    ) -> Bool {
        guard summary.presentationState == .completed else {
            return false
        }

        return summary.savedAssetIdentifier?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty == false
    }

    static func recentJobRow(
        from summary:
            PhotoMemoBackgroundJobSummary
    ) -> V1SettingsHistoryRowPresentation {
        V1SettingsHistoryRowPresentation(
            id: summary.jobID,
            jobID: summary.jobID,
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
                ? "需要处理"
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
            return "处理中"
        case .completed:
            return "已完成"
        case .needsAttention:
            return "需要处理"
        }
    }

    static func userFacingStepTitle(
        _ title: String
    ) -> String {
        let normalized = title.lowercased()

        if normalized.contains("renderer")
            || normalized.contains("render") {
            return "生成记忆照片"
        }

        if normalized.contains("pipeline")
            || normalized.contains("queue")
            || normalized.contains("队列") {
            return "处理照片"
        }

        return title
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
            return .secondary
        case .needsAttention:
            return .orange
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
}
#endif
