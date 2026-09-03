#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("Photo processing quick-action coordinator responsibility contract")
struct PhotoProcessingQuickActionCoordinatorContractTests {

    @Test("quick-action coordination is separated from picker, queue, and export owners")
    func coordinatorHasOnlyForegroundIntakeHandoffResponsibilities() throws {
        let coordinator = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/iOS/Views/PhotoProcessingQuickActionCoordinator.swift"
            ),
            encoding: .utf8
        )
        let support = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/iOS/Views/PhotoIntakeImporter.swift"
            ),
            encoding: .utf8
        )

        #expect(coordinator.contains("enum PhotoProcessingQuickActionCoordinator"))
        #expect(coordinator.contains("BatchConfigurationSnapshot"))
        #expect(coordinator.contains("case configurationSaveFailed"))
        #expect(coordinator.contains("case noSupportedPhotos"))
        #expect(coordinator.contains("case submitted"))
        #expect(!coordinator.contains("PhotosPickerItem"))
        #expect(!coordinator.contains("BatchQueueStore"))
        #expect(!coordinator.contains("PhotoLibraryExportService"))
        #expect(!support.contains("enum PhotoProcessingQuickActionCoordinator"))
    }
}
#endif
