#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Minimal queue capability surface required by the system background worker.
/// It deliberately excludes observable jobs, configuration, and UI state.
@MainActor
protocol BackgroundQueueRuntime: AnyObject {

    var isProcessing: Bool { get }
    var pendingTaskCount: Int { get }
    var executablePendingTaskCount: Int { get }
    var isProcessingPaused: Bool { get }
    var canProcessPhotoLibraryDestinations: Bool { get }
    var backgroundExecutionSession: ExecutionSession? { get }

    func reserveSystemExecution(owner: BackgroundExecutionOwner) -> ExecutionLease?
    func finishSystemExecution(_ lease: ExecutionLease) async
    func stopProcessingForBackgroundExpiration(lease: ExecutionLease) async
    func startProcessingIfNeeded() async
    func stopProcessingForBackgroundExpiration() async
}

extension BackgroundQueueRuntime {
    var executablePendingTaskCount: Int { pendingTaskCount }
    var backgroundExecutionSession: ExecutionSession? { nil }
}

extension BatchQueueStore: BackgroundQueueRuntime {
    var isProcessingPaused: Bool { processingPaused }
    var backgroundExecutionSession: ExecutionSession? {
        let current = jobs.first { $0.id == activeJobID && $0.historyDeletedAt == nil }
            ?? jobs.first { $0.historyDeletedAt == nil && $0.executionSuspendedAt == nil && $0.tasks.contains { !$0.phase.isTerminal } }
            ?? jobs.first { $0.historyDeletedAt == nil }
        guard let current else { return nil }
        return ExecutionSession(id: current.executionSessionID ?? current.id, jobs: jobs)
    }

    var canProcessPhotoLibraryDestinations: Bool {
        let capability = PhotoLibraryCapability.current
        return jobs.filter { $0.executionSuspendedAt == nil && $0.historyDeletedAt == nil && $0.tasks.contains { $0.phase.isPending } }.allSatisfy {
            capability.albumDisposition(preferredIdentifier: $0.configuration.selectedAlbumIdentifier) != .requiresFullAccess
        }
    }
}
#endif
