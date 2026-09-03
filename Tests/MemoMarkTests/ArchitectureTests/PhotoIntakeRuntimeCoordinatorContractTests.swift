#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("Photo intake runtime coordinator responsibility contract")
struct PhotoIntakeRuntimeCoordinatorContractTests {

    @Test("runtime coordinator remains the latest-request-only lifecycle owner")
    func runtimeCoordinatorOwnsOnlyTheRequestLifecycle() throws {
        let coordinator = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/iOS/Views/PhotoIntakeRuntimeCoordinator.swift"
            ),
            encoding: .utf8
        )
        let support = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/iOS/Views/PhotoIntakeImporter.swift"
            ),
            encoding: .utf8
        )

        #expect(coordinator.contains("final class PhotoIntakeRuntimeCoordinator"))
        #expect(coordinator.contains("private var activeRequestID: UUID?"))
        #expect(coordinator.contains("discardUnsubmittedItems(importedItems)"))
        #expect(coordinator.contains("&& !Task.isCancelled"))
        #expect(coordinator.contains("submit(importedItems, configuration)"))
        #expect(!coordinator.contains("BatchQueueStore"))
        #expect(!coordinator.contains("PhotoLibraryExportService"))
        #expect(!support.contains("final class PhotoIntakeRuntimeCoordinator"))
    }
}
#endif
