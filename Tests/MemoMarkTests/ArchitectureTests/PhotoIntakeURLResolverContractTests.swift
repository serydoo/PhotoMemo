#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("Photo intake URL resolver responsibility contract")
struct PhotoIntakeURLResolverContractTests {

    @Test("resolver is outside the legacy intake support aggregation")
    func resolverIsOutsideLegacyIntakeSupportAggregation() throws {
        let resolver = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/iOS/Views/PhotoIntakeURLResolver.swift"
            ),
            encoding: .utf8
        )
        let support = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/iOS/Views/PhotoIntakeImporter.swift"
            ),
            encoding: .utf8
        )

        #expect(resolver.contains("enum PhotoIntakeURLResolver"))
        #expect(resolver.contains("MemoMarkPicker"))
        #expect(resolver.contains("resolvingSymlinksInPath()"))
        #expect(resolver.contains("PhotoProcessingInputPolicy.standard"))
        #expect(!resolver.contains("BatchQueueStore"))
        #expect(!resolver.contains("PhotoLibraryExportService"))
        #expect(!support.contains("enum PhotoIntakeURLResolver"))
    }
}
#endif
