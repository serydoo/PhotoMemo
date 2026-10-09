import Foundation
import Darwin

/// Kernel-owned execution exclusion shared by the app and its extension.
/// Never persist a boolean lease: process death closes the descriptor and
/// permits recovery. This lock does not replace ledger transaction locking.
nonisolated final class ProcessingExecutionFileLock: @unchecked Sendable {
    private let url: URL
    private let mutex = NSLock()
    private var descriptor: Int32 = -1

    init(url: URL) {
        self.url = url.standardizedFileURL
    }

    func acquire(waitForAvailability: Bool = false) throws -> Bool {
        mutex.lock()
        defer { mutex.unlock() }
        guard descriptor == -1 else { return false }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let candidate = open(url.path, O_CREAT | O_RDWR | O_CLOEXEC, S_IRUSR | S_IWUSR)
        guard candidate >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        guard flock(candidate, waitForAvailability ? LOCK_EX : LOCK_EX | LOCK_NB) == 0 else {
            let code = errno
            close(candidate)
            if code == EWOULDBLOCK || code == EAGAIN { return false }
            throw POSIXError(POSIXErrorCode(rawValue: code) ?? .EIO)
        }
        descriptor = candidate
        return true
    }

    func release() {
        mutex.lock()
        defer { mutex.unlock() }
        guard descriptor >= 0 else { return }
        close(descriptor)
        descriptor = -1
    }

    deinit {
        if descriptor >= 0 { close(descriptor) }
    }
}
