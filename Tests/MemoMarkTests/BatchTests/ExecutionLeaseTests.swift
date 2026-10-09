import Foundation
import Testing
@testable import MemoMark

@Suite("Execution ownership")
struct ExecutionLeaseTests {
    @Test("one owner and stale release cannot revoke a successor")
    @MainActor func ownership() throws {
        let arbiter = BackgroundExecutionArbiter()
        let first = try #require(arbiter.acquire(owner: .foreground))
        #expect(arbiter.acquire(owner: .bgProcessing) == nil)
        #expect(arbiter.release(first))
        let second = try #require(arbiter.acquire(owner: .bgProcessing))
        #expect(!arbiter.release(first))
        #expect(arbiter.currentLease == second)
        #expect(arbiter.release(second))
    }
    @Test("lease transfer retains cross-process exclusion; stale release cannot unlock")
    @MainActor func fileOwnership() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("execution.lock")
        let first = BackgroundExecutionArbiter(fileLock: ProcessingExecutionFileLock(url: url))
        let second = BackgroundExecutionArbiter(fileLock: ProcessingExecutionFileLock(url: url))
        let lease = try #require(first.acquire(owner: .foreground))
        let successor = try #require(first.transfer(lease, to: .backgroundGrace))
        #expect(second.acquire(owner: .continuedProcessing) == nil)
        #expect(!first.release(lease))
        #expect(second.acquire(owner: .continuedProcessing) == nil)
        #expect(first.release(successor))
        let recovered = try #require(second.acquire(owner: .continuedProcessing))
        #expect(second.release(recovered))
    }

}
