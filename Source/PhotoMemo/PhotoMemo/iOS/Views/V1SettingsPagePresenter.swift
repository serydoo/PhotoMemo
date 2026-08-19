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
    let totalCount: Int
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
    let totalCount: Int
    let photoLibraryLink:
        V1TaskPhotoLibraryLink?
}

struct V1TaskPhotoLibraryLink:
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
            fallback: "Open Photos"
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
            fallback: "Open Photos to view \"%@\"."
        )
        return String(format: format, locale: language.locale, albumName)
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
        fallbackConfigurationName: String = "当前配置",
        language: MemoMarkLanguage = .simplifiedChinese
    ) -> V1SettingsPagePresentation {
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

        return V1SettingsPagePresentation(
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

private extension V1SettingsPagePresenter {

    static func currentTaskPresentation(
        header:
            PhotoMemoiOSQueueDiagnosticsHeaderProjection,
        snapshot:
            PhotoMemoBackgroundJobSnapshot?,
        recoveryMessage: String?,
        fallbackConfigurationName: String,
        language: MemoMarkLanguage
    ) -> V1SettingsCurrentTaskPresentation {
        if let snapshot {
            let progressProjection =
                PhotoMemoiOSQueueDiagnosticsProjectionEngine
                .progressProjection(
                    for: snapshot,
                    language: language
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

        return V1SettingsCurrentTaskPresentation(
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
            PhotoMemoBackgroundTaskOverview,
        language: MemoMarkLanguage
    ) -> [V1TaskOverviewItemPresentation] {
        [
            V1TaskOverviewItemPresentation(
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
            V1TaskOverviewItemPresentation(
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
            V1TaskOverviewItemPresentation(
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
            V1TaskOverviewItemPresentation(
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

    static func waitingStepRows(
        language: MemoMarkLanguage
    ) -> [V1TaskPipelineStepPresentation] {
        [
            V1TaskPipelineStepPresentation(
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
            PhotoMemoBackgroundJobSnapshot,
        language: MemoMarkLanguage
    ) -> [V1TaskPipelineStepPresentation] {
        snapshot.pipelineSteps
            .enumerated()
            .map { index, step in
                V1TaskPipelineStepPresentation(
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
            PhotoMemoBackgroundJobSnapshot,
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
            PhotoMemoBackgroundJobSnapshot,
        language: MemoMarkLanguage
    ) -> String {
        feedbackStateText(
            snapshot.feedbackState,
            language: language
        )
    }

    static func headerStatusText(
        _ header:
            PhotoMemoiOSQueueDiagnosticsHeaderProjection,
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
            [PhotoMemoBackgroundJobSummary],
        language: MemoMarkLanguage
    ) -> [V1SettingsHistoryRowPresentation] {
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
            PhotoMemoBackgroundJobSummary,
        language: MemoMarkLanguage
    ) -> V1SettingsHistoryRowPresentation {
        V1SettingsHistoryRowPresentation(
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
        _ templateName: String,
        language: MemoMarkLanguage = .simplifiedChinese
    ) -> String {
        let trimmedName =
            templateName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        switch trimmedName {
        case "Classic White":
            return language.localized(
                key: "task.template.classic_white",
                fallback: "Classic White"
            )
        default:
            return trimmedName.isEmpty
                ? language.localized(
                    key: "task.template.classic_white",
                    fallback: "Classic White"
                )
                : trimmedName
        }
    }

    static func summaryStatusText(
        _ summary:
            PhotoMemoBackgroundJobSummary,
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
        _ state: PhotoMemoBackgroundFeedbackState,
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
            PhotoMemoBackgroundPipelineStepState,
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
