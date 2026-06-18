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

        return await schedule(
            content: content,
            identifier:
                notificationIdentifier(
                    for: job,
                    suffix: "start"
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

        return await schedule(
            content: content,
            identifier:
                notificationIdentifier(
                    for: job,
                    suffix: "final"
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
        identifier: String
    ) async -> Bool {

        do {
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
            "已接收 \(job.totalTaskCount) 张照片，会按当前模板在后台自动处理。"

        if !templateName.isEmpty,
           !anchorName.isEmpty {
            return "\(summary) 模板：\(templateName)，时间点：\(anchorName)。"
        }

        if !templateName.isEmpty {
            return "\(summary) 模板：\(templateName)。"
        }

        if !anchorName.isEmpty {
            return "\(summary) 时间点：\(anchorName)。"
        }

        return summary
    }

    func finishedTitle(
        completedCount: Int,
        failedCount: Int
    ) -> String {

        if failedCount == 0 {
            return "PhotoMemo 处理完成"
        }

        if completedCount == 0 {
            return "PhotoMemo 处理失败"
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
                return "\(totalCount) 张照片已全部处理完成，已经存入“\(albumName)”相册。"
            }

            return "\(totalCount) 张照片已全部处理完成，并已写入系统图库。"
        }

        if completedCount == 0 {
            return "\(totalCount) 张照片暂未处理成功，可以回到 PhotoMemo 查看失败原因并重试。"
        }

        if !albumName.isEmpty {
            return "本批共 \(totalCount) 张，已完成 \(completedCount) 张、失败 \(failedCount) 张；成功结果已存入“\(albumName)”。"
        }

        return "本批共 \(totalCount) 张，已完成 \(completedCount) 张、失败 \(failedCount) 张；成功结果已写入系统图库。"
    }
}
