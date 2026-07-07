import Foundation
import UserNotifications

enum BatchNotificationMessageFormatter {

    nonisolated
    static func finishedTitle(
        completedCount: Int,
        failedCount: Int,
        finishedAt: Date,
        calendar: Calendar = .current
    ) -> String {

        let timeText =
            shortTimeText(
                for: finishedAt,
                calendar: calendar
            )

        if failedCount == 0 {
            return "\(timeText) 处理 \(completedCount) 张照片已完成"
        }

        if completedCount == 0 {
            return "\(timeText) \(failedCount) 张照片需处理"
        }

        return "\(timeText) 已完成 \(completedCount) 张，\(failedCount) 张需处理"
    }

    nonisolated
    static func finishedMessage(
        completedCount: Int,
        failedCount: Int,
        totalCount: Int,
        savedAlbumName: String? = nil
    ) -> String {

        if failedCount == 0 {
            return savedAlbumName
                .flatMap(normalizedAlbumName)
                .map {
                    "已保存到「\($0)」。"
                }
                ?? "PhotoMemo 已生成新的照片。"
        }

        if completedCount == 0 {
            return "请回到 PhotoMemo 查看原因，并按提示继续处理。"
        }

        if Double(completedCount)
            / Double(max(1, totalCount))
            >= 0.8 {
            if let albumName =
                savedAlbumName
                .flatMap(normalizedAlbumName) {
                return "大部分结果已保存到「\(albumName)」，剩余 \(failedCount) 张可回到 PhotoMemo 查看。"
            }

            return "大部分结果已经完成，剩余 \(failedCount) 张可回到 PhotoMemo 查看。"
        }

        if let albumName =
            savedAlbumName
            .flatMap(normalizedAlbumName) {
            return "已保存 \(completedCount) 张到「\(albumName)」，另有 \(failedCount) 张需处理。"
        }

        return "已完成 \(completedCount) 张，仍有 \(failedCount) 张需处理。"
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
            "PhotoMemo 已接收任务"
        content.body =
            queuedMessage(
                for: job
            )
        content.sound = .default
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

        let completedCount =
            job.completedTaskCount
        let failedCount =
            job.failedTaskCount
        let totalCount =
            job.totalTaskCount

        guard completedCount + failedCount > 0 else {
            return false
        }

        let content =
            UNMutableNotificationContent()

        content.title =
            BatchNotificationMessageFormatter
            .finishedTitle(
                completedCount: completedCount,
                failedCount: failedCount,
                finishedAt:
                    job.updatedAt
            )
        content.body =
            BatchNotificationMessageFormatter
            .finishedMessage(
                completedCount: completedCount,
                failedCount: failedCount,
                totalCount: totalCount,
                savedAlbumName:
                    savedAlbumName(
                        for: job
                    )
            )
        content.sound = .default
        content.attachments =
            notificationAttachments(
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
            "PhotoMemo 正在后台处理"
        content.body =
            progressMessage(
                for: job,
                stage: stage
            )
        content.sound = nil
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
            do {
                return try await center
                    .requestAuthorization(
                        options: [
                            .alert,
                            .sound,
                            .badge
                        ]
                    )
            } catch {
                return false
            }

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
            return "多个相册"
        }

        return nil
    }

    func queuedMessage(
        for job: BatchJob
    ) -> String {

        let templateName =
            job.configuration.template.name
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let anchorName =
            job.configuration
            .resolvedProductionAnchorTitle
            ?? ""

        let summary =
            "已接收 \(job.totalTaskCount) 张照片，PhotoMemo 会按当前配置继续处理。"

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
            return "\(enrichedSummary) 当前预设：\(templateName)，时间点：\(anchorName)。"
        }

        if !templateName.isEmpty {
            return "\(enrichedSummary) 当前预设：\(templateName)。"
        }

        if !anchorName.isEmpty {
            return "\(enrichedSummary) 时间点：\(anchorName)。"
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
                "另有 \(intakeSummary.skippedCount) 张已跳过"
            )
        }

        if intakeSummary.failedCount > 0 {
            parts.append(
                "\(intakeSummary.failedCount) 张未能导入"
            )
        }

        guard !parts.isEmpty else {
            return nil
        }

        return " 本次分享中，\(parts.joined(separator: "，"))。"
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

        switch stage {

        case "raw":
            stageTitle = "正在准备 RAW 照片"

        case "imported":
            stageTitle = "已开始读取原图和 EXIF"

        case "rendering":
            stageTitle = "正在生成记忆卡片图片"

        case "saving":
            stageTitle = "正在写入系统相册"

        default:
            stageTitle = "正在后台处理"
        }

        var summary =
            "\(totalCount) 张照片\(stageTitle)。"

        if completedCount > 0
            || failedCount > 0 {
            summary += " 已完成 \(completedCount) 张"

            if failedCount > 0 {
                summary += "，失败 \(failedCount) 张"
            }

            summary += "。"
        } else if runningCount > 0 {
            summary += " 当前还有 \(runningCount) 张在队列中。"
        }

        return summary
    }
}
