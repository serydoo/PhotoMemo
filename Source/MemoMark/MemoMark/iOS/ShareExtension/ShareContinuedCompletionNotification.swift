#if os(iOS) && MEMOMARK_SHARE_EXTENSION
import Foundation
import UserNotifications

/// Native result delivery after the existing ledger confirms committed saves.
@MainActor enum ShareContinuedCompletionNotification {
    static func deliver(_ message: ExecutionSessionCompletionNotification,
                        ledger: BatchQueueDurableLedger, requestID: UUID) async {
        await deliver(identifier: message.identifier, title: message.title, body: message.body,
                      completedCount: message.completedCount, jobIDs: message.jobIDs,
                      acknowledgeCompletion: true, needsAttention: false, ledger: ledger, requestID: requestID)
    }

    static func deliverSuspension(_ message: ExecutionSessionSuspensionNotification,
                                  ledger: BatchQueueDurableLedger, requestID: UUID) async {
        await deliver(identifier: message.identifier, title: message.title, body: message.body,
                      completedCount: message.completedCount, jobIDs: message.jobIDs,
                      acknowledgeCompletion: message.isFinalResult, needsAttention: true, ledger: ledger, requestID: requestID)
    }

    private static func deliver(identifier: String, title: String, body: String,
                                completedCount: Int, jobIDs: [UUID], acknowledgeCompletion: Bool,
                                needsAttention: Bool, ledger: BatchQueueDurableLedger, requestID: UUID) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus) else {
            ShareContinuedProcessingDiagnostics.record("extension.production.notificationUnavailable.\(requestID)")
            return
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.threadIdentifier = identifier
        content.interruptionLevel = .active
        content.sound = needsAttention ? .default : nil
        if let jobID = jobIDs.last {
            content.userInfo = [MemoMarkNotificationUserInfo.deepLinkURL:
                MemoMarkDeepLink.processing(jobID: jobID).url.absoluteString]
        } else {
            content.userInfo = [MemoMarkNotificationUserInfo.deepLinkURL: MemoMarkDeepLink.share.url.absoluteString]
        }
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        do {
            try await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: nil))
            let event = acknowledgeCompletion ? "notificationScheduled" : "suspensionNotificationScheduled"
            ShareContinuedProcessingDiagnostics.record("extension.production.\(event).\(requestID)",
                detail: "identifier=\(identifier);saved=\(completedCount)")
            guard acknowledgeCompletion else { return }
            for jobID in jobIDs {
                if case .failure = await ledger.markFinalNotificationSent(for: jobID) {
                    ShareContinuedProcessingDiagnostics.record("extension.production.notificationAcknowledgementBlocked.\(requestID)")
                    // A stable notification identifier makes later recovery a
                    // replacement even if delivery acknowledgement is interrupted.
                    break
                }
            }
        } catch {
            ShareContinuedProcessingDiagnostics.record("extension.production.notificationDeliveryFailed.\(requestID)",
                detail: "code=\((error as NSError).code)")
        }
    }
}
#endif
