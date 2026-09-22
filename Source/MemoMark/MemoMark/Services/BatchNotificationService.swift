import Foundation
import UserNotifications

enum BatchNotificationMessageFormatter {

    nonisolated
    static func finishedTitle(
        completedCount: Int,
        failedCount: Int,
        finishedAt: Date,
        calendar: Calendar = .current,
        language: MemoMarkLanguage = .simplifiedChinese
    ) -> String {

        finishedTitle(
            completedCount: completedCount,
            needsAttentionCount: failedCount,
            finishedAt: finishedAt,
            calendar: calendar,
            language: language
        )
    }

    nonisolated
    static func finishedTitle(
        completedCount: Int,
        needsAttentionCount: Int,
        finishedAt: Date,
        calendar: Calendar = .current,
        language: MemoMarkLanguage = .simplifiedChinese
    ) -> String {

        let timeText =
            shortTimeText(
                for: finishedAt,
                calendar: calendar
            )

        if needsAttentionCount == 0 {
            return String(
                format: language.localized(
                    key: "notification.batch.finished.complete",
                    fallback: "%@ Processed %d Photos"
                ),
                locale: language.locale,
                timeText,
                completedCount
            )
        }

        if completedCount == 0 {
            return String(
                format: language.localized(
                    key: "notification.batch.finished.attention_only",
                    fallback: "%@ %d Photos Need Attention"
                ),
                locale: language.locale,
                timeText,
                needsAttentionCount
            )
        }

        return String(
            format: language.localized(
                key: "notification.batch.finished.partial",
                fallback: "%@ %d Complete, %d Need Attention"
            ),
            locale: language.locale,
            timeText,
            completedCount,
            needsAttentionCount
        )
    }

    nonisolated
    static func finishedMessage(
        completedCount: Int,
        failedCount: Int,
        totalCount: Int,
        savedAlbumName: String? = nil,
        language: MemoMarkLanguage = .simplifiedChinese
    ) -> String {

        finishedMessage(
            completedCount: completedCount,
            needsAttentionCount: failedCount,
            totalCount: totalCount,
            savedAlbumName: savedAlbumName,
            language: language
        )
    }

    nonisolated
    static func finishedMessage(
        completedCount: Int,
        needsAttentionCount: Int,
        totalCount: Int,
        savedAlbumName: String? = nil,
        language: MemoMarkLanguage = .simplifiedChinese
    ) -> String {

        if needsAttentionCount == 0 {
            return savedAlbumName
                .flatMap(normalizedAlbumName)
                .map {
                    String(
                        format: language.localized(
                            key: "notification.batch.finished.saved_to_album",
                            fallback: "Saved to \"%@\"."
                        ),
                        locale: language.locale,
                        $0
                    )
                }
                ?? language.localized(
                    key: "notification.batch.finished.generated",
                    fallback: "MemoMark generated new photos."
                )
        }

        if completedCount == 0 {
            return language.localized(
                key: "notification.batch.finished.return_to_app",
                fallback: "Return to MemoMark to review the reason and continue."
            )
        }

        if Double(completedCount)
            / Double(max(1, totalCount))
            >= 0.8 {
            if let albumName =
                savedAlbumName
                .flatMap(normalizedAlbumName) {
                return String(
                    format: language.localized(
                        key: "notification.batch.finished.mostly_saved_to_album",
                        fallback: "Most results were saved to \"%@\". %d still need attention in MemoMark."
                    ),
                    locale: language.locale,
                    albumName,
                    needsAttentionCount
                )
            }

            return String(
                format: language.localized(
                    key: "notification.batch.finished.mostly_saved",
                    fallback: "Most results are complete. %d still need attention in MemoMark."
                ),
                locale: language.locale,
                needsAttentionCount
            )
        }

        if let albumName =
            savedAlbumName
            .flatMap(normalizedAlbumName) {
            return String(
                format: language.localized(
                    key: "notification.batch.finished.partial_saved_to_album",
                    fallback: "%d saved to \"%@\". %d still need attention."
                ),
                locale: language.locale,
                completedCount,
                albumName,
                needsAttentionCount
            )
        }

        return String(
            format: language.localized(
                key: "notification.batch.finished.partial_saved",
                fallback: "%d complete. %d still need attention."
            ),
            locale: language.locale,
            completedCount,
            needsAttentionCount
        )
    }

    nonisolated
    static func normalizedAlbumName(
        _ value: String
    ) -> String? {

        let trimmed =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty
            ? nil
            : trimmed
    }

    nonisolated
    private static func shortTimeText(
        for date: Date,
        calendar: Calendar
    ) -> String {

        let hour =
            calendar.component(
                .hour,
                from: date
            )
        let minute =
            calendar.component(
                .minute,
                from: date
            )

        return String(
            format: "%02d:%02d",
            hour,
            minute
        )
    }
}

@MainActor
final class BatchNotificationService:
    NSObject,
    UNUserNotificationCenterDelegate {

    private let center =
        UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    func notifyJobQueued(
        _ job: BatchJob
    ) async -> Bool {

        guard shouldNotify(
            for: job.launchSource
        ) else {
            return false
        }

        guard await ensureAuthorization() else {
            return false
        }

        let content =
            UNMutableNotificationContent()

        content.title =
            MemoMarkLanguage.interfaceStored.localized(
                key: "notification.batch.queued.title",
                fallback: "MemoMark received a task"
            )
        content.body =
            queuedMessage(
                for: job
            )
        content.sound = .default
        configureNotificationRoute(
            content,
            for: job
        )
        configureStatusPresentation(
            content,
            for: job,
            isProgressUpdate: false
        )

        return await schedule(
            content: content,
            identifier:
                notificationIdentifier(
                    for: job,
                    suffix: "status"
                ),
            replacingIdentifiers:
                legacyNotificationIdentifiers(
                    for: job
                )
        )
    }

    func notifyJobFinished(
        _ job: BatchJob
    ) async -> Bool {

        guard shouldNotify(
            for: job.launchSource
        ) else {
            return false
        }

        guard await ensureAuthorization() else {
            return false
        }

        let deliverySummary = job.deliverySummary

        guard deliverySummary.completedCount
                + deliverySummary.needsAttentionCount > 0 else {
            return false
        }

        let content =
            UNMutableNotificationContent()

        content.title =
            BatchNotificationMessageFormatter
            .finishedTitle(
                completedCount:
                    deliverySummary.completedCount,
                needsAttentionCount:
                    deliverySummary.needsAttentionCount,
                finishedAt:
                    job.updatedAt
            )
        content.body =
            BatchNotificationMessageFormatter
            .finishedMessage(
                completedCount:
                    deliverySummary.completedCount,
                needsAttentionCount:
                    deliverySummary.needsAttentionCount,
                totalCount:
                    deliverySummary.requestedCount,
                savedAlbumName:
                    savedAlbumName(
                        for: job
                    ),
                language: MemoMarkLanguage.interfaceStored
            )
        content.sound = .default
        content.attachments =
            notificationAttachments(
                for: job
            )
        configureNotificationRoute(
            content,
            for: job
        )
        configureStatusPresentation(
            content,
            for: job,
            isProgressUpdate: false
        )

        return await schedule(
            content: content,
            identifier:
                notificationIdentifier(
                    for: job,
                    suffix: "status"
                ),
            replacingIdentifiers:
                legacyNotificationIdentifiers(
                    for: job
                )
        )
    }

    func notifyJobProgress(
        _ job: BatchJob,
        stage: String
    ) async -> Bool {

        guard shouldNotify(
            for: job.launchSource
        ) else {
            return false
        }

        guard await ensureAuthorization() else {
            return false
        }

        let content =
            UNMutableNotificationContent()

        content.title =
            MemoMarkLanguage.interfaceStored.localized(
                key: "notification.batch.progress.title",
                fallback: "MemoMark is processing in the background"
            )
        content.body =
            progressMessage(
                for: job,
                stage: stage
            )
        content.sound = nil
        configureNotificationRoute(
            content,
            for: job
        )
        configureStatusPresentation(
            content,
            for: job,
            isProgressUpdate: true
        )

        return await schedule(
            content: content,
            identifier:
                notificationIdentifier(
                    for: job,
                    suffix: "status"
                ),
            replacingIdentifiers:
                legacyNotificationIdentifiers(
                    for: job
                )
        )
    }

    nonisolated
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {

        [
            .banner,
            .list,
            .sound
        ]
    }

    nonisolated
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler:
            @escaping () -> Void
    ) {
        defer {
            completionHandler()
        }

        guard
            let rawURL = response.notification.request.content
                .userInfo[MemoMarkNotificationUserInfo.deepLinkURL]
                as? String,
            let url = URL(string: rawURL),
            let deepLink = MemoMarkDeepLink(url: url)
        else {
            return
        }

        NotificationCenter.default.post(
            name: .photoMemoNotificationOpened,
            object: nil,
            userInfo: [
                MemoMarkNotificationUserInfo.deepLinkURL:
                    deepLink.url.absoluteString
            ]
        )
    }
}

private extension BatchNotificationService {

    func shouldNotify(
        for source: BatchJobLaunchSource
    ) -> Bool {

        switch source {

        case .inAppPreview:
            return false

        case .shareExtension,
             .fileOpen,
             .quickAction,
             .automation:
            return true
        }
    }

    func ensureAuthorization() async -> Bool {

        let settings =
            await center.notificationSettings()

        switch settings.authorizationStatus {

        case .authorized,
             .provisional,
             .ephemeral:
            return true

        case .notDetermined:
            return false

        case .denied:
            return false

        @unknown default:
            return false
        }
    }

    func schedule(
        content: UNMutableNotificationContent,
        identifier: String,
        replacingIdentifiers: [String]
    ) async -> Bool {

        do {
            let identifiersToRemove =
                Array(
                    Set(
                        replacingIdentifiers + [
                            identifier
                        ]
                    )
                )

            center.removePendingNotificationRequests(
                withIdentifiers:
                    identifiersToRemove
            )
            center.removeDeliveredNotifications(
                withIdentifiers:
                    identifiersToRemove
            )

            let request =
                UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: nil
                )

            try await center.add(request)
            return true
        } catch {
            return false
        }
    }

    func notificationIdentifier(
        for job: BatchJob,
        suffix: String
    ) -> String {

        "photomemo.batch.\(job.id.uuidString).\(suffix)"
    }

    func configureStatusPresentation(
        _ content: UNMutableNotificationContent,
        for job: BatchJob,
        isProgressUpdate: Bool
    ) {
        content.threadIdentifier =
            notificationIdentifier(
                for: job,
                suffix: "thread"
            )

        if isProgressUpdate {
            content.badge = nil
        }

        if #available(iOS 15.0, macOS 12.0, *) {
            content.interruptionLevel =
                isProgressUpdate ? .passive : .active
        }
    }

    func configureNotificationRoute(
        _ content: UNMutableNotificationContent,
        for job: BatchJob
    ) {
        content.userInfo = [
            MemoMarkNotificationUserInfo.deepLinkURL:
                MemoMarkDeepLink
                .processing(jobID: job.id)
                .url
                .absoluteString
        ]
    }

    func legacyNotificationIdentifiers(
        for job: BatchJob
    ) -> [String] {

        [
            "start",
            "final",
            "progress.raw",
            "progress.imported",
            "progress.rendering",
            "progress.saving"
        ]
        .map {
            notificationIdentifier(
                for: job,
                suffix: $0
            )
        }
    }

    func notificationAttachments(
        for job: BatchJob
    ) -> [UNNotificationAttachment] {

        guard let attachmentURL =
            job.tasks
            .first(where: {
                $0.phase == .completed
                && $0.notificationAttachmentURL != nil
            })?
            .notificationAttachmentURL
        else {
            return []
        }

        guard FileManager.default.fileExists(
            atPath:
                attachmentURL
                .standardizedFileURL
                .path
        ) else {
            return []
        }

        guard let attachment =
            try? UNNotificationAttachment(
                identifier:
                    "photomemo-result",
                url: attachmentURL,
                options: nil
            )
        else {
            return []
        }

        return [attachment]
    }

    func savedAlbumName(
        for job: BatchJob
    ) -> String? {

        let albumNames =
            Set(
                job.tasks
                    .filter {
                        $0.phase == .completed
                    }
                    .compactMap {
                        BatchNotificationMessageFormatter
                            .normalizedAlbumName(
                                $0.savedAlbumName ?? ""
                            )
                    }
            )

        if albumNames.count == 1 {
            return albumNames.first
        }

        if albumNames.count > 1 {
            return MemoMarkLanguage.interfaceStored.localized(
                key: "notification.batch.multiple_albums",
                fallback: "Multiple Albums"
            )
        }

        return nil
    }

    func queuedMessage(
        for job: BatchJob
    ) -> String {

        let language = MemoMarkLanguage.interfaceStored

        let templateName =
            job.configuration.template.displayName(
                for: job.configuration.language
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let anchorName =
            job.configuration
            .resolvedProductionAnchorTitle
            ?? ""

        let summary =
            String(
                format: language.localized(
                    key: "notification.batch.queued.message",
                    fallback: "Received %d photos. MemoMark will continue with the current configuration."
                ),
                locale: language.locale,
                job.totalTaskCount
            )

        let intakeWarningSummary =
            intakeWarningSummary(
                for: job
            )

        let enrichedSummary =
            intakeWarningSummary
            .map {
                "\(summary)\($0)"
            } ?? summary

        if !templateName.isEmpty,
           !anchorName.isEmpty {
            return "\(enrichedSummary) " + String(
                format: language.localized(
                    key: "notification.batch.queued.preset_and_anchor",
                    fallback: "Preset: %@. Time anchor: %@."
                ),
                locale: language.locale,
                templateName,
                anchorName
            )
        }

        if !templateName.isEmpty {
            return "\(enrichedSummary) \(String(format: language.localized(key: "notification.batch.queued.preset", fallback: "Preset: %@."), locale: language.locale, templateName))"
        }

        if !anchorName.isEmpty {
            return "\(enrichedSummary) \(String(format: language.localized(key: "notification.batch.queued.anchor", fallback: "Time anchor: %@."), locale: language.locale, anchorName))"
        }

        return enrichedSummary
    }

    func intakeWarningSummary(
        for job: BatchJob
    ) -> String? {

        guard let intakeSummary =
            job.intakeSummary,
              intakeSummary.hasWarnings else {
            return nil
        }

        var parts: [String] = []

        if intakeSummary.skippedCount > 0 {
            parts.append(
                String(
                    format: MemoMarkLanguage.interfaceStored.localized(
                        key: "notification.batch.intake_skipped",
                        fallback: "%d skipped"
                    ),
                    locale: MemoMarkLanguage.interfaceStored.locale,
                    intakeSummary.skippedCount
                )
            )
        }

        if intakeSummary.failedCount > 0 {
            parts.append(
                String(
                    format: MemoMarkLanguage.interfaceStored.localized(
                        key: "notification.batch.intake_failed",
                        fallback: "%d could not be imported"
                    ),
                    locale: MemoMarkLanguage.interfaceStored.locale,
                    intakeSummary.failedCount
                )
            )
        }

        guard !parts.isEmpty else {
            return nil
        }

        let language = MemoMarkLanguage.interfaceStored
        return " " + String(
            format: language.localized(
                key: "notification.batch.intake_warning",
                fallback: "In this share, %@."
            ),
            locale: language.locale,
            parts.joined(separator: language.localized(
                key: "notification.batch.list_separator",
                fallback: ", "
            ))
        )
    }

    func progressMessage(
        for job: BatchJob,
        stage: String
    ) -> String {

        let completedCount =
            job.completedTaskCount
        let failedCount =
            job.failedTaskCount
        let totalCount =
            job.totalTaskCount
        let runningCount =
            job.runningTaskCount

        let stageTitle: String
        let language = MemoMarkLanguage.interfaceStored

        switch stage {

        case "raw":
            stageTitle = language.localized(
                key: "notification.batch.progress.raw",
                fallback: "preparing RAW photos"
            )

        case "imported":
            stageTitle = language.localized(
                key: "notification.batch.progress.imported",
                fallback: "reading originals and EXIF"
            )

        case "rendering":
            stageTitle = language.localized(
                key: "notification.batch.progress.rendering",
                fallback: "rendering memory cards"
            )

        case "saving":
            stageTitle = language.localized(
                key: "notification.batch.progress.saving",
                fallback: "saving to Photos"
            )

        default:
            stageTitle = language.localized(
                key: "notification.batch.progress.default",
                fallback: "processing in the background"
            )
        }

        var summary =
            String(
                format: language.localized(
                    key: "notification.batch.progress.summary",
                    fallback: "%d photos: %@."
                ),
                locale: language.locale,
                totalCount,
                stageTitle
            )

        if completedCount > 0
            || failedCount > 0 {
            summary += " " + String(
                format: language.localized(
                    key: "notification.batch.progress.completed",
                    fallback: "%d complete"
                ),
                locale: language.locale,
                completedCount
            )

            if failedCount > 0 {
                summary += " " + String(
                    format: language.localized(
                        key: "notification.batch.progress.failed",
                        fallback: "%d failed"
                    ),
                    locale: language.locale,
                    failedCount
                )
            }

            summary += language.localized(
                key: "notification.batch.progress.full_stop",
                fallback: "."
            )
        } else if runningCount > 0 {
            summary += " " + String(
                format: language.localized(
                    key: "notification.batch.progress.queued",
                    fallback: "%d remain in the queue."
                ),
                locale: language.locale,
                runningCount
            )
        }

        return summary
    }
}
