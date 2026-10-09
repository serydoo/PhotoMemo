#if os(iOS) && DEBUG && MEMOMARK_HOST_HANDOFF_MINIMAL
import BackgroundTasks
import Foundation
import UIKit
import Darwin

/// Isolated device experiment: no application runtime, media, configuration or queue.
@available(iOS 26.0, *)
@MainActor
enum HostHandoffMinimalProbe {
    private static let prefix = "isolatedHostHandoff"
    private static let identifierPrefix = "com.serydoo.PhotoMemo.iOS.continued-spike.isolated."
    private static var defaults: UserDefaults { MemoMarkSharedContainer.sharedUserDefaults }

    static func prepareHost() {
        let arguments = ProcessInfo.processInfo.arguments
        defaults.set(arguments.contains("-isolatedExtensionOwner"), forKey: prefix + ".extensionOwner")
        defaults.set(arguments.contains("-isolatedLegacySubmission"), forKey: prefix + ".legacy")
        let identifier = arguments.contains("-isolatedPrepare")
            ? identifierPrefix + UUID().uuidString
            : defaults.string(forKey: prefix + ".identifier") ?? identifierPrefix + UUID().uuidString
        defaults.set(identifier, forKey: prefix + ".identifier")
        defaults.synchronize()
        record("hostPrepared", identifier: identifier)
        register(identifier: identifier, side: "host")
        if arguments.contains("-isolatedSelfSubmit") {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                _ = await submit(identifier: identifier)
            }
        }
    }

    static func submitFromExtension(itemCount: Int) async -> Bool {
        let extensionOwner = defaults.bool(forKey: prefix + ".extensionOwner")
        let identifier: String
        if extensionOwner {
            identifier = identifierPrefix + UUID().uuidString
            defaults.set(identifier, forKey: prefix + ".identifier")
            register(identifier: identifier, side: "extension")
        } else {
            guard let prepared = defaults.string(forKey: prefix + ".identifier"),
                  prepared.hasPrefix(identifierPrefix) else { return false }
            identifier = prepared
        }
        record("extensionItems", identifier: identifier, detail: "count=\(itemCount)")
        return await submit(identifier: identifier)
    }

    static func recordDismissal() {
        record("extensionCompleteRequest", identifier: defaults.string(forKey: prefix + ".identifier") ?? "missing")
    }

    private static func register(identifier: String, side: String) {
        let registered = BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            Task { @MainActor in
                record(side + "Callback", identifier: task.identifier)
                guard let continued = task as? BGContinuedProcessingTask else {
                    task.setTaskCompleted(success: false)
                    return
                }
                continued.expirationHandler = {
                    Task { @MainActor in record(side + "Expired", identifier: continued.identifier) }
                }
                continued.progress.totalUnitCount = 1
                defaults.set("verified", forKey: prefix + ".ack." + continued.identifier)
                defaults.synchronize()
                let verified = defaults.string(forKey: prefix + ".ack." + continued.identifier) == "verified"
                if verified { continued.progress.completedUnitCount = 1 }
                record(side + (verified ? "MarkerCompleted" : "MarkerFailed"), identifier: continued.identifier)
                continued.setTaskCompleted(success: verified)
            }
        }
        record(side + (registered ? "Registered" : "RegistrationRejected"), identifier: identifier)
    }

    private static func submit(identifier: String) async -> Bool {
        let legacy = defaults.bool(forKey: prefix + ".legacy")
        record("submitting", identifier: identifier, detail: legacy ? "legacy" : "async")
        do {
            let submittedOnMainThread = try await ContinuedProcessingSubmission.submit(
                identifier: identifier, title: "MemoMark", subtitle: "接管验证",
                immediate: true, legacy: legacy)
            record("submissionThread", identifier: identifier, detail: "main=\(submittedOnMainThread)")
            if #available(iOS 27.0, *), !legacy {
                record("submissionConfirmed", identifier: identifier)
            } else {
                record("legacyReturned", identifier: identifier)
            }
            return true
        } catch {
            record("submissionRejected", identifier: identifier, detail: String(describing: error))
            return false
        }
    }

    private static func record(_ event: String, identifier: String, detail: String = "") {
        let value: [String: Any] = ["event": event, "identifier": identifier,
            "timestamp": Date().timeIntervalSince1970, "pid": Int(getpid()),
            "bundle": Bundle.main.bundleIdentifier ?? "unknown", "detail": detail]
        defaults.set(value, forKey: prefix + ".evidence." + identifier + "." + event)
        defaults.synchronize()
        NSLog("isolatedHostHandoff %@ %@ pid=%d %@", event, identifier, getpid(), detail)
    }
}
#endif
