#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("Photo intake importer responsibility contract")
struct PhotoIntakeImporterContractTests {

    @Test("platform adapter keeps picker identity and managed-resource evidence together")
    func importerOwnsOnlyPlatformIntakeAdaptation() throws {
        let importer = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/iOS/Views/PhotoIntakeImporter.swift"
            ),
            encoding: .utf8
        )

        #expect(importer.contains("enum PhotoIntakeImporter"))
        #expect(importer.contains("PhotosPickerItem"))
        #expect(importer.contains("PHPickerResult"))
        #expect(importer.contains("PhotoIntakeURLResolver"))
        #expect(importer.contains("PHAsset.fetchAssets"))
        #expect(importer.contains("MemoMarkShareDiagnostics.record"))
        #expect(!importer.contains("BatchConfigurationSnapshot"))
        #expect(!importer.contains("BatchQueueStore"))
        #expect(!importer.contains("PhotoLibraryExportService"))

        #expect(
            !FileManager.default.fileExists(
                atPath: MemoMarkTestPaths.path(
                    "Source/MemoMark/MemoMark/iOS/Views/V1PhotoIntakeSupport.swift"
                )
            )
        )
    }
}
#endif
