import Foundation
import Testing
@testable import PhotoMemo

@Suite("Batch job history cover")
struct BatchJobHistoryCoverTests {

    @Test("History cover accepts only portable cache paths")
    func validatesPortablePath() {
        let taskID = UUID()
        #expect(BatchJobHistoryCover(
            sourceTaskID: taskID,
            relativePath: "TaskHistoryCovers/job.jpg"
        ) != nil)
        #expect(BatchJobHistoryCover(
            sourceTaskID: taskID,
            relativePath: "/private/job.jpg"
        ) == nil)
        #expect(BatchJobHistoryCover(
            sourceTaskID: taskID,
            relativePath: "TaskHistoryCovers/../job.jpg"
        ) == nil)
    }

    @Test("History cover survives persistence round trip")
    func roundTrip() throws {
        let cover = try #require(BatchJobHistoryCover(
            sourceTaskID: UUID(),
            relativePath: "TaskHistoryCovers/job.jpg"
        ))
        let decoded = try JSONDecoder().decode(
            BatchJobHistoryCover.self,
            from: JSONEncoder().encode(cover)
        )
        #expect(decoded == cover)
    }
}
