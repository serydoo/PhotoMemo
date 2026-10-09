import Foundation
import Testing
@testable import MemoMark

@Suite("Cross-process execution lock")
struct ProcessingExecutionFileLockTests {
    @Test("independent handles exclude each other and release permits recovery")
    func exclusion() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("execution.lock")
        let first = ProcessingExecutionFileLock(url: url)
        let second = ProcessingExecutionFileLock(url: url)
        #expect(try first.acquire())
        #expect(try !second.acquire())
        first.release()
        #expect(try second.acquire())
        second.release()
    }

    @Test("process lifetime owns the lock; releasing a different handle cannot revoke it")
    func lifetime() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("execution.lock")
        let other = ProcessingExecutionFileLock(url: url)
        do {
            let owner = ProcessingExecutionFileLock(url: url)
            #expect(try owner.acquire())
            other.release()
            #expect(try !other.acquire())
        }
        #expect(try other.acquire())
        other.release()
    }
#if os(macOS)
    @Test("a separate process owns exclusion and termination permits recovery")
    func processRecovery() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("execution.lock")
        let child = Process()
        let output = Pipe()
        let errors = Pipe()
        // The system Python shim invokes xcrun, which cannot run in the app sandbox.
        // Perl provides flock directly without launching a developer-tool shim.
        child.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        child.arguments = ["-e", "use Fcntl qw(:flock); open(my $f, '>', $ARGV[0]) or die $!; flock($f, LOCK_EX) or die $!; $| = 1; print 'R'; sleep 120;", url.path]
        child.standardOutput = output
        child.standardError = errors
        try child.run()
        defer { if child.isRunning { child.terminate(); child.waitUntilExit() } }
        let ready = output.fileHandleForReading.readData(ofLength: 1)
        guard ready == Data("R".utf8) else {
            child.waitUntilExit()
            let reason = String(data: errors.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            Issue.record("Lock helper failed before readiness: status=\(child.terminationStatus), stderr=\(reason)")
            return
        }
        let contender = ProcessingExecutionFileLock(url: url)
        #expect(try !contender.acquire())
        child.terminate()
        child.waitUntilExit()
        #expect(try contender.acquire())
        contender.release()
    }
#endif

}
