import Foundation
import Testing
@testable import MemoMark

@Suite("Background probe retention")
@MainActor
struct BackgroundProbeRetentionTests {
    @Test("probe history is bounded without touching queue or configuration truth")
    func boundedOwnedRecords() throws {
        let name = "BackgroundProbeRetentionTests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set("keep-config", forKey: "photomemo.frozenShareConfiguration")
        defaults.set("keep-receipt", forKey: "continuedProcessingSpike.evidence.saved")
        for index in 0..<520 {
            defaults.set(["event": "old", "timestamp": Double(index)],
                forKey: "processingBackgroundProbe.\(index)")
        }
        MemoMarkBackgroundProbe.record("latest", defaults: defaults, now: Date(timeIntervalSince1970: 1000))
        let records = defaults.dictionaryRepresentation().filter { $0.key.hasPrefix("processingBackgroundProbe.") }
        #expect(records.count == 512)
        #expect(defaults.object(forKey: "processingBackgroundProbe.0") == nil)
        #expect(defaults.dictionary(forKey: "processingBackgroundProbe.519") != nil)
        #expect(records.values.contains { ($0 as? [String: Any])?["event"] as? String == "latest" })
        #expect(defaults.string(forKey: "photomemo.frozenShareConfiguration") == "keep-config")
        #expect(defaults.string(forKey: "continuedProcessingSpike.evidence.saved") == "keep-receipt")
        MemoMarkBackgroundProbe.record("clock-reset", defaults: defaults, now: Date(timeIntervalSince1970: -1))
        let afterClockReset = defaults.dictionaryRepresentation().filter { $0.key.hasPrefix("processingBackgroundProbe.") }
        #expect(afterClockReset.count == 512)
        #expect(afterClockReset.values.contains { ($0 as? [String: Any])?["event"] as? String == "clock-reset" })
    }
}
