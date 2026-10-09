import Foundation

nonisolated enum BackgroundExecutionOwner: String, Codable, Sendable {
    case foreground
    case backgroundGrace
    case bgProcessing
    case continuedProcessing
}

nonisolated struct ExecutionLease: Equatable, Sendable {
    let id: UUID
    let owner: BackgroundExecutionOwner
}

/// Process-local execution authority. Durable receipts, not a persisted lease,
/// decide recovery after process death. Release requires the exact generation.
@MainActor
final class BackgroundExecutionArbiter {
    private(set) var currentLease: ExecutionLease?
    private(set) var lastAcquisitionError: String?
    private let fileLock: ProcessingExecutionFileLock?

    init(fileLock: ProcessingExecutionFileLock? = nil) {
        self.fileLock = fileLock
    }

    func acquire(owner: BackgroundExecutionOwner) -> ExecutionLease? {
        guard currentLease == nil else { return nil }
        do {
            if let fileLock, try !fileLock.acquire() { return nil }
            lastAcquisitionError = nil
        } catch {
            lastAcquisitionError = String(describing: error)
            return nil
        }
        let lease = ExecutionLease(id: UUID(), owner: owner)
        currentLease = lease
        return lease
    }

    @discardableResult
    func release(_ lease: ExecutionLease) -> Bool {
        guard currentLease == lease else { return false }
        currentLease = nil
        fileLock?.release()
        return true
    }

    func transfer(_ lease: ExecutionLease, to owner: BackgroundExecutionOwner) -> ExecutionLease? {
        guard currentLease == lease else { return nil }
        let successor = ExecutionLease(id: UUID(), owner: owner)
        currentLease = successor
        return successor
    }
}
