#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Minimal queue capability surface required by the system background worker.
/// It deliberately excludes observable jobs, configuration, and UI state.
@MainActor
protocol BackgroundQueueRuntime: AnyObject {

    var isProcessing: Bool { get }
    var pendingTaskCount: Int { get }

    func startProcessingIfNeeded() async
    func stopProcessingForBackgroundExpiration() async
}

extension BatchQueueStore: BackgroundQueueRuntime {}
#endif
