import Foundation
import Testing
@testable import MemoMark

struct ProcessingPresentationAuthorityTests {
    @Test("A stale owner cannot release a newer presentation lease; expired ownership restores fallback")
    func staleOwnerAndExpiry() throws {
        let suite = "MemoMark.presentation.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let date = Date(timeIntervalSince1970: 1_000)
        let old = UUID(), current = UUID()
        #expect(ProcessingPresentationAuthority.current(defaults: defaults, now: date) == .activityKit)
        ProcessingPresentationAuthority.renew(leaseID: old, defaults: defaults, now: date)
        ProcessingPresentationAuthority.renew(leaseID: current, defaults: defaults, now: date)
        ProcessingPresentationAuthority.release(leaseID: old, defaults: defaults)
        #expect(ProcessingPresentationAuthority.current(defaults: defaults, now: date) == .systemContinuedProcessing)
        #expect(ProcessingPresentationAuthority.current(defaults: defaults, now: date.addingTimeInterval(61)) == .activityKit)
        ProcessingPresentationAuthority.release(leaseID: current, defaults: defaults)
        #expect(ProcessingPresentationAuthority.current(defaults: defaults, now: date) == .activityKit)
    }
}
