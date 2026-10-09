import Foundation
import Testing
@testable import MemoMark

@Suite("Processing progress freshness")
struct ProcessingProgressFreshnessTests {
    @Test("reprojection cannot renew an old task's freshness window")
    func oldProgress() {
        let update = Date(timeIntervalSince1970: 1000)
        let date = ProcessingProgressFreshness.staleDate(updatedAt: update, isTerminal: false)
        #expect(date == Date(timeIntervalSince1970: 1300))
        #expect(date! < Date(timeIntervalSince1970: 2000))
    }
    @Test("confirmed terminal results do not become uncertain through age")
    func terminal() {
        #expect(ProcessingProgressFreshness.staleDate(updatedAt: .distantPast, isTerminal: true) == nil)
    }
}
