#if os(iOS) && DEBUG
import BackgroundTasks
import Foundation
import Darwin

/// Construct and submit requests away from the main actor as required by the SDK.
/// Only value parameters cross executors; scheduler requests remain local.
@available(iOS 26.0, *)
nonisolated enum ContinuedProcessingSubmission {
    @concurrent
    static func submit(identifier: String, title: String, subtitle: String,
                       immediate: Bool, legacy: Bool = false) async throws -> Bool {
        let submittedOnMainThread = pthread_main_np() != 0
        let request = BGContinuedProcessingTaskRequest(identifier: identifier,
            title: title, subtitle: subtitle)
        request.strategy = immediate ? .fail : .queue
        NSLog("continuedSubmissionThread %@ main=%@", identifier,
              submittedOnMainThread ? "true" : "false")
        if #available(iOS 27.0, *), !legacy {
            try await BGTaskScheduler.shared.submitTaskRequest(request)
        } else {
            try BGTaskScheduler.shared.submit(request)
        }
        return submittedOnMainThread
    }
}
#endif
