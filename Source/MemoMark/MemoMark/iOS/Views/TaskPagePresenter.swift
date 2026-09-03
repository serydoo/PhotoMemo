#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct TaskPagePresentation:
    Equatable {

    let overviewItems:
        [TaskOverviewItemPresentation]

    let currentTask:
        TaskCurrentPresentation

    let historyRows:
        [TaskHistoryRowPresentation]
}

enum TaskDisplayMode: Equatable {

    case waiting

    case processing

    case completed

    case needsAttention
}

struct TaskCurrentPresentation:
    Equatable {

    let jobID: UUID?

    let displayMode: TaskDisplayMode

    let headline: String
    let subtitleText: String
    let statusText: String
    let itemCountText: String?
    let totalCount: Int
    let progressText: String?
    let detailText: String
    let symbolName: String
    let thumbnailSymbolName: String
    let tint:
        MemoMarkiOSQueueDiagnosticsTint
    let updatedAt: Date?
    let progressFraction: Double?
    let canRetryFailures: Bool
    let configurationName: String
    let templateName: String
    let previewSourceURL: URL?
    let stepRows:
        [TaskPipelineStepPresentation]
    let photoLibraryLink:
        TaskPhotoLibraryLink?
}

struct TaskHistoryRowPresentation:
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
        MemoMarkiOSQueueDiagnosticsTint
    let templateName: String?
    let previewSourceURL: URL?
    let totalCount: Int
    let photoLibraryLink:
        TaskPhotoLibraryLink?
}

struct TaskPhotoLibraryLink:
    Equatable,
    Hashable {

    let albumName: String?
    let assetIdentifier: String?

    var displayTitle: String {
        displayTitle(language: .simplifiedChinese)
    }

    func displayTitle(language: MemoMarkLanguage) -> String {
        guard let albumName,
              !albumName.isEmpty else {
            return language.localized(
                key: "task.photoLibrary.library_title",
                fallback: "Photo Library"
            )
        }

        return albumName
    }

    var actionTitle: String {
        actionTitle(language: .simplifiedChinese)
    }

    func actionTitle(language: MemoMarkLanguage) -> String {
        language.localized(
            key: "task.photoLibrary.open",
            fallback: "View in Photos"
        )
    }

    var saveDestinationText: String {
        saveDestinationText(language: .simplifiedChinese)
    }

    func saveDestinationText(language: MemoMarkLanguage) -> String {
        guard let albumName,
              !albumName.isEmpty else {
            return language.localized(
                key: "task.photoLibrary.saved",
                fallback: "Saved to your photo library"
            )
        }

        let format = language.localized(
            key: "task.photoLibrary.saved_album_format",
            fallback: "Saved to \"%@\""
        )
        return String(format: format, locale: language.locale, albumName)
    }

    var accessibilityHint: String {
        accessibilityHint(language: .simplifiedChinese)
    }

    func accessibilityHint(language: MemoMarkLanguage) -> String {
        guard let albumName,
              !albumName.isEmpty else {
            return language.localized(
                key: "task.photoLibrary.hint",
                fallback: "Open Photos to view the saved memory."
            )
        }

        let format = language.localized(
            key: "task.photoLibrary.hint_album_format",
                fallback: "Open Photos, then view \"%@\"."
        )
        return String(format: format, locale: language.locale, albumName)
    }
}

struct TaskOverviewItemPresentation:
    Identifiable,
    Equatable {

    let id: String
    let title: String
    let value: String
    let unit: String
    let symbolName: String
    let tint:
        MemoMarkiOSQueueDiagnosticsTint
}

struct TaskPipelineStepPresentation:
    Identifiable,
    Equatable {

    let id: String
    let title: String
    let statusText: String
    let timeText: String?
    let symbolName: String
    let tint:
        MemoMarkiOSQueueDiagnosticsTint
    let emphasizesTitle: Bool
}

enum TaskPagePresenter {

    static func presentation(
        header:
            MemoMarkiOSQueueDiagnosticsHeaderProjection,
        snapshot:
            MemoMarkBackgroundJobSnapshot?,
        recoveryMessage: String?,
        events:
            [MemoMarkShareDiagnosticEvent],
        overview:
            MemoMarkBackgroundTaskOverview = .empty,
        recentJobs:
            [MemoMarkBackgroundJobSummary] = [],
        fallbackConfigurationName: String = "当前配置",
        language: MemoMarkLanguage = .simplifiedChinese
    ) -> TaskPagePresentation {
        let currentTask = currentTaskPresentation(
            header: header,
            snapshot: snapshot,
            recoveryMessage: recoveryMessage,
            fallbackConfigurationName: fallbackConfigurationName,
            language: language
        )
        let historyRows = historyRows(
            from: events,
            recentJobs: recentJobs,
            language: language
        )

        return TaskPagePresentation(
            overviewItems:
                overviewItems(
                    from: overview,
                    language: language
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

private extension TaskPagePresenter {

    static func currentTaskPresentation(
        header:
            MemoMarkiOSQueueDiagnosticsHeaderProjection,
        snapshot:
            MemoMarkBackgroundJobSnapshot?,
        recoveryMessage: String?,
        fallbackConfigurationName: String,
        language: MemoMarkLanguage
    ) -> TaskCurrentPresentation {
        if let snapshot {
            let progressProjection =
                MemoMarkiOSQueueDiagnosticsProjectionEngine
                .progressProjection(
                    for: snapshot,
                    language: language
                )

            return TaskCurrentPresentation(
                jobID: snapshot.jobID,
                displayMode:
                    displayMode(
                        for: snapshot.presentationState
                    ),
                headline:
                    snapshot.configurationName,
                subtitleText:
                    presetText(
                        displayTemplateName(
                            snapshot.templateName,
                            language: language
                        ),
                        language: language
                    ),
                statusText:
                    snapshotStatusText(
                        snapshot,
                        language: language
                    ),
                itemCountText:
                    photoCountText(
                        count: snapshot.totalCount,
                        language: language
                    ),
                totalCount: snapshot.totalCount,
                progressText:
                    progressText(
                        snapshot,
                        language: language
                    ),
                detailText:
                    progressProjection
                    .statusMessage,
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
                        snapshot.templateName,
                        language: language
                    ),
                previewSourceURL:
                    snapshot.previewSourceURL,
                stepRows:
                    stepRows(
                        from: snapshot,
                        language: language
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

        return TaskCurrentPresentation(
            jobID: nil,
            displayMode: displayMode(for: header),
            headline:
                header.headline,
            subtitleText:
                language.localized(
                    key: "task.waiting.share_subtitle",
                    fallback: "Waiting for a photo shared from Apple Photos"
                ),
            statusText:
                headerStatusText(
                    header,
                    language: language
                ),
            itemCountText: nil,
            totalCount: 0,
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
                waitingStepRows(language: language),
            photoLibraryLink: nil
        )
    }

    static func overviewItems(
        from overview:
            MemoMarkBackgroundTaskOverview,
        language: MemoMarkLanguage
    ) -> [TaskOverviewItemPresentation] {
        [
            TaskOverviewItemPresentation(
                id: "active",
                title: language.localized(
                    key: "task.overview.active.title",
                    fallback: "Processing"
                ),
                value:
                    "\(overview.activeJobCount)",
                unit: language.localized(
                    key: "task.overview.active.unit",
                    fallback: "tasks"
                ),
                symbolName:
                    "arrow.trianglehead.2.clockwise.circle.fill",
                tint: .blue
            ),
            TaskOverviewItemPresentation(
                id: "completed",
                title: language.localized(
                    key: "task.overview.completed.title",
                    fallback: "Completed"
                ),
                value:
                    "\(overview.completedPhotoCount)",
                unit: language.localized(
                    key: "task.overview.completed.unit",
                    fallback: "photos"
                ),
                symbolName:
                    "checkmark.circle.fill",
                tint: .green
            ),
            TaskOverviewItemPresentation(
                id: "failed",
                title: language.localized(
                    key: "task.overview.failed.title",
                    fallback: "Failed"
                ),
                value:
                    "\(overview.failedPhotoCount)",
                unit: language.localized(
                    key: "task.overview.failed.unit",
                    fallback: "photos"
                ),
                symbolName:
                    "xmark.circle.fill",
                tint: .secondary
            ),
            TaskOverviewItemPresentation(
                id: "today",
                title: language.localized(
                    key: "task.overview.today.title",
                    fallback: "Today"
                ),
                value:
                    "\(overview.todayProcessingCount)",
                unit: language.localized(
                    key: "task.overview.today.unit",
                    fallback: "runs"
                ),
                symbolName:
                    "clock.fill",
                tint: .orange
            )
        ]
    }

    static func displayMode(
        for state: MemoMarkBackgroundPresentationState
    ) -> TaskDisplayMode {
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
        for header: MemoMarkiOSQueueDiagnosticsHeaderProjection
    ) -> TaskDisplayMode {
        header.tint == .orange
            ? .needsAttention
            : .waiting
    }

    static func waitingStepRows(
        language: MemoMarkLanguage
    ) -> [TaskPipelineStepPresentation] {
        [
            TaskPipelineStepPresentation(
                id: "waiting",
                title: language.localized(
                    key: "task.pipeline.waiting.title",
                    fallback: "Waiting for photos"
                ),
                statusText: language.localized(
                    key: "task.pipeline.waiting.status",
                    fallback: "Waiting"
                ),
                timeText: nil,
                symbolName: "circle",
                tint: .secondary,
                emphasizesTitle: false
            )
        ]
    }

    static func stepRows(
        from snapshot:
            MemoMarkBackgroundJobSnapshot,
        language: MemoMarkLanguage
    ) -> [TaskPipelineStepPresentation] {
        snapshot.pipelineSteps
            .enumerated()
            .map { index, step in
                TaskPipelineStepPresentation(
                    id:
                        "\(index)-\(step.title)",
                    title:
                        userFacingStepTitle(
                            step.title,
                            language: language
                        ),
                    statusText:
                        stepStatusText(
                            for: step.state,
                            language: language
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
            MemoMarkBackgroundJobSnapshot,
        language: MemoMarkLanguage
    ) -> String? {
        guard snapshot.totalCount > 0 else {
            return nil
        }

        let completedText = String(
            format: language.localized(
                key: "task.progress.completed_format",
                fallback: "%d photos completed"
            ),
            locale: language.locale,
            snapshot.completedCount
        )
        let remainingCount = max(
            snapshot.totalCount - snapshot.completedCount,
            0
        )

        guard remainingCount > 0 else {
            return completedText
        }

        if snapshot.hasOnlyUnsupportedFailures {
            return completedText
                + " · "
                + String(
                    format: language.localized(
                        key: "task.progress.remaining_unsupported_format",
                        fallback: "%d photos unsupported"
                    ),
                    locale: language.locale,
                    remainingCount
                )
        }

        return completedText
            + " · "
            + String(
                format: language.localized(
                    key: "task.progress.remaining_format",
                    fallback: "%d photos remaining"
                ),
                locale: language.locale,
                remainingCount
            )
    }

    static func snapshotStatusText(
        _ snapshot:
            MemoMarkBackgroundJobSnapshot,
        language: MemoMarkLanguage
    ) -> String {
        feedbackStateText(
            snapshot.feedbackState,
            language: language
        )
    }

    static func headerStatusText(
        _ header:
            MemoMarkiOSQueueDiagnosticsHeaderProjection,
        language: MemoMarkLanguage
    ) -> String {
        if header.isRecovery {
            return language.localized(
                key: "task.status.recovery",
                fallback: "Needs recovery"
            )
        }

        switch header.tint {
        case .blue:
            return language.localized(
                key: "task.status.processing",
                fallback: "Processing"
            )
        case .orange:
            return language.localized(
                key: "task.status.needs_attention",
                fallback: "Needs attention"
            )
        case .green:
            return language.localized(
                key: "task.status.completed",
                fallback: "Completed"
            )
        case .secondary:
            return language.localized(
                key: "task.status.waiting",
                fallback: "Waiting"
            )
        }
    }

    static func thumbnailSymbolName(
        _ state:
            MemoMarkBackgroundPresentationState
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
            [MemoMarkShareDiagnosticEvent],
        recentJobs:
            [MemoMarkBackgroundJobSummary],
        language: MemoMarkLanguage
    ) -> [TaskHistoryRowPresentation] {
        recentJobs
            .filter { summary in
                isSavedRecentJob(summary)
            }
            .map {
                recentJobRow(
                    from: $0,
                    language: language
                )
            }
    }

    static func isSavedRecentJob(
        _ summary:
            MemoMarkBackgroundJobSummary
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
            MemoMarkBackgroundJobSummary,
        language: MemoMarkLanguage
    ) -> TaskHistoryRowPresentation {
        TaskHistoryRowPresentation(
            id: summary.jobID,
            jobID: summary.jobID,
            timestamp:
                summary.updatedAt,
            title:
                summary.configurationName,
            detailText:
                String(
                    format: language.localized(
                        key: "task.recent.detail_format",
                        fallback: "%@ Preset · %d photos"
                    ),
                    locale: language.locale,
                    displayTemplateName(
                        summary.templateName,
                        language: language
                    ),
                    summary.totalCount
                ),
            statusText:
                summaryStatusText(
                    summary,
                    language: language
                ),
            itemCountText:
                photoCountText(
                    count: summary.totalCount,
                    language: language
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
                    summary.templateName,
                    language: language
                ),
            previewSourceURL:
                summary.previewSourceURL,
            totalCount: summary.totalCount,
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
    ) -> TaskPhotoLibraryLink? {
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

        return TaskPhotoLibraryLink(
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
        _ templateName: String,
        language: MemoMarkLanguage = .simplifiedChinese
    ) -> String {
        let trimmedName =
            templateName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        switch trimmedName.lowercased() {
        case "classic white",
             "basic white",
             "基础白",
             "ベーシックホワイト",
             "クラシックホワイト",
             "베이직 화이트",
             "클래식 화이트":
            return TemplatePreset.classicWhite.displayName(
                for: language
            )
        default:
            return trimmedName.isEmpty
                ? TemplatePreset.classicWhite.displayName(
                    for: language
                )
                : trimmedName
        }
    }

    static func summaryStatusText(
        _ summary:
            MemoMarkBackgroundJobSummary,
        language: MemoMarkLanguage
    ) -> String {
        switch summary.presentationState {
        case .active:
            return language.localized(
                key: "task.status.processing",
                fallback: "Processing"
            )
        case .needsAttention:
            return summary.failedCount > 0
                ? language.localized(
                    key: "task.status.needs_attention",
                    fallback: "Needs attention"
                )
                : language.localized(
                    key: "task.status.interrupted",
                    fallback: "Interrupted"
                )
        case .completed:
            return language.localized(
                key: "task.status.completed",
                fallback: "Completed"
            )
        }
    }

    static func feedbackStateText(
        _ state: MemoMarkBackgroundFeedbackState,
        language: MemoMarkLanguage
    ) -> String {
        let key: String
        switch state {
        case .preparing:
            key = "task.status.preparing"
        case .processing:
            key = "task.status.processing"
        case .completed:
            key = "task.status.completed"
        case .partialSuccess:
            key = "task.status.partial_success"
        case .needsAttention:
            key = "task.status.needs_attention"
        case .unsupported:
            key = "task.status.unsupported"
        }

        return language.localized(
            key: key,
            fallback: state.displayTitle
        )
    }

    static func presetText(
        _ templateName: String,
        language: MemoMarkLanguage
    ) -> String {
        let format = language.localized(
            key: "task.preset.format",
            fallback: "%@ Preset"
        )
        return String(format: format, locale: language.locale, templateName)
    }

    static func summarySymbolName(
        _ summary:
            MemoMarkBackgroundJobSummary
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
            MemoMarkBackgroundJobSummary
    ) -> MemoMarkiOSQueueDiagnosticsTint {
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
            MemoMarkBackgroundPipelineStepState,
        language: MemoMarkLanguage
    ) -> String {
        switch state {
        case .pending:
            return language.localized(
                key: "task.pipeline.waiting.status",
                fallback: "Waiting"
            )
        case .active:
            return language.localized(
                key: "task.status.processing",
                fallback: "Processing"
            )
        case .completed:
            return language.localized(
                key: "task.status.completed",
                fallback: "Completed"
            )
        case .needsAttention:
            return language.localized(
                key: "task.status.needs_attention",
                fallback: "Needs attention"
            )
        }
    }

    static func userFacingStepTitle(
        _ title: String,
        language: MemoMarkLanguage
    ) -> String {
        let normalized = title.lowercased()

        if normalized.contains("renderer")
            || normalized.contains("render") {
            return language.localized(
                key: "task.pipeline.render",
                fallback: "Create memory photo"
            )
        }

        if normalized.contains("pipeline")
            || normalized.contains("queue")
            || normalized.contains("队列") {
            return language.localized(
                key: "task.pipeline.process",
                fallback: "Process photos"
            )
        }

        return title
    }

    static func stepSymbolName(
        for state:
            MemoMarkBackgroundPipelineStepState
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
            MemoMarkBackgroundPipelineStepState
    ) -> MemoMarkiOSQueueDiagnosticsTint {
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
        count: Int,
        language: MemoMarkLanguage
    ) -> String? {
        guard count > 0 else {
            return nil
        }

        return String(
            format: language.localized(
                key: "task.photo_count_format",
                fallback: "%d photos"
            ),
            locale: language.locale,
            count
        )
    }
}
#endif
