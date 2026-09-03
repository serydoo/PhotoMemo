#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Read-only queue state needed to classify an external-intake drain result.
/// Queue mutation remains behind `ShareCoordinator` and the durable queue
/// facade, so this projection cannot create a second admission path.
@MainActor
protocol ExternalIntakeQueueProjection: AnyObject {

    var pendingTaskCount: Int { get }
    var defaultConfigurationSnapshot: BatchConfigurationSnapshot { get }
}

extension BatchQueueStore: ExternalIntakeQueueProjection {}
#endif
