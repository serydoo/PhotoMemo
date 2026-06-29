import Foundation
import UserNotifications

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
            finishedTitle(
                completedCount: completedCount,
                failedCount: failedCount
            )
        content.body =
            finishedMessage(
                for: job,
                completedCount: completedCount,
                failedCount: failedCount,
                totalCount: totalCount
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

    func queuedMessage(
        for job: BatchJob
    ) -> String {

        let templateName =
            job.configuration.template.name
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let anchorName =
            job.configuration.anchor?.title
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        let summary =
            "已接收 \(job.totalTaskCount) 张照片，会按当前风格在后台自动处理。"

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
            return "\(enrichedSummary) 风格：\(templateName)，时间点：\(anchorName)。"
        }

        if !templateName.isEmpty {
            return "\(enrichedSummary) 模板：\(templateName)。"
        }

        if !anchorName.isEmpty {
            return "\(enrichedSummary) 时间点：\(anchorName)。"
        }

        return enrichedSummary
    }

    func finishedTitle(
        completedCount: Int,
        failedCount: Int
    ) -> String {

        if failedCount == 0 {
            return "PhotoMemo 已保存 \(completedCount) 张照片"
        }

        if completedCount == 0 {
            return "\(failedCount) 张照片需要处理"
        }

        if Double(completedCount)
            / Double(max(1, completedCount + failedCount))
            >= 0.8 {
            return "PhotoMemo 基本处理完成"
        }

        return "PhotoMemo 已完成部分任务"
    }

    func finishedMessage(
        for job: BatchJob,
        completedCount: Int,
        failedCount: Int,
        totalCount: Int
    ) -> String {

        let albumName =
            job.tasks
            .compactMap(\.savedAlbumName)
            .last?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        if failedCount == 0 {
            if !albumName.isEmpty {
                return "已存入“\(albumName)”相册。"
            }

            return "已写入系统图库。"
        }

        if completedCount == 0 {
            return "可以回到 PhotoMemo 查看原因并重试。"
        }

        if Double(completedCount)
            / Double(max(1, totalCount))
            >= 0.8 {

            if !albumName.isEmpty {
                return "已保存 \(completedCount) 张到“\(albumName)”，另有 \(failedCount) 张需要处理。"
            }

            return "已保存 \(completedCount) 张，另有 \(failedCount) 张需要处理。"
        }

        if !albumName.isEmpty {
            return "已保存 \(completedCount) 张到“\(albumName)”，\(failedCount) 张需要处理。"
        }

        return "已保存 \(completedCount) 张，\(failedCount) 张需要处理。"
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
