#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("Background queue presentation projection responsibility contract")
struct MemoMarkBackgroundQueueProjectionContractTests {

    @Test("queue-line projection is isolated from observable queue ownership")
    func queueProjectionReceivesFactsAndCatalogWithoutQueueStoreOwnership() throws {
        let service = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/App/MemoMarkBackgroundStatusService.swift"
            ),
            encoding: .utf8
        )
        let projection = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/App/MemoMarkBackgroundQueueProjection.swift"
            ),
            encoding: .utf8
        )
        let statusProjection = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/App/MemoMarkBackgroundStatusProjection.swift"
            ),
            encoding: .utf8
        )

        #expect(service.contains("MemoMarkBackgroundStatusProjection("))
        #expect(projection.contains("struct MemoMarkBackgroundQueueProjection"))
        #expect(statusProjection.contains("MemoMarkBackgroundQueueProjection("))
        #expect(projection.contains("let textCatalog: MemoMarkBackgroundStatusTextCatalog"))
        #expect(projection.contains("func queueLines("))
        #expect(projection.contains("func overflowQueueCount("))
        #expect(projection.contains("func queuedJobCount("))
        #expect(!projection.contains("BatchQueueStore"))
        #expect(!projection.contains("@Published"))
        #expect(!projection.contains("Publishers."))
    }
}
#endif
