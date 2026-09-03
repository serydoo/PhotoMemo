#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("Home activity card surface")
struct HomeActivityCardSurfaceContractTests {

    @Test("activity presentation is a focused surface outside the home coordinator")
    func activityPresentationStaysOutsideTheHomeCoordinator() throws {
        let homeSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/HomePageSurface.swift"
        )
        let cardSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/HomeActivityCard.swift"
        )

        #expect(homeSource.contains("HomeActivityCard("))
        #expect(!homeSource.contains("private struct HomeActivityCard"))
        #expect(cardSource.contains("struct HomeActivityCard: View"))
        #expect(cardSource.contains("let projection: HomeActivityProjection"))
        #expect(cardSource.contains("let onOpenProcessing: () -> Void"))
        #expect(cardSource.contains("HomeActivityPresenter.shouldShow(projection)"))
        #expect(cardSource.contains("accessibilityReduceMotion"))
        #expect(!cardSource.contains("ConfigurationSession"))
        #expect(!cardSource.contains("BatchQueueStore"))
        #expect(!cardSource.contains("PhotoLibrary"))
    }

    private func sourceText(_ relativePath: String) throws -> String {
        let testsDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
        let repositoryRoot = testsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appendingPathComponent(relativePath), encoding: .utf8)
    }
}
#endif
