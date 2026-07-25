#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing

@Suite("MemoryResult variable projection boundary")
struct MemoryResultVariableProjectionBoundaryTests {

    @Test("MemoryResult anchor projection stays outside CardVariableProvider")
    func memoryResultAnchorProjectionStaysOutsideCardVariableProvider() throws {
        let providerSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/Models/CardVariableProvider.swift"
        )
        let projectorSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/Models/MemoryResultVariableProjector.swift"
        )
        let formatterSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/Models/MemoryAnchorVariableTextFormatter.swift"
        )

        #expect(
            providerSource.contains(
                "MemoryResultVariableProjector.project("
            )
        )
        #expect(
            providerSource.contains(
                "MemoryResultVariableProjector.memoryValues("
            )
        )
        #expect(
            !providerSource.contains(
                "static func projectMemoryResultAnchorValues"
            )
        )
        #expect(
            !providerSource.contains(
                "static func memoryResultValues"
            )
        )
        #expect(
            projectorSource.contains(
                "enum MemoryResultVariableProjector"
            )
        )
        #expect(
            formatterSource.contains(
                "enum MemoryAnchorVariableTextFormatter"
            )
        )
    }

    private func sourceText(
        _ relativePath: String
    ) throws -> String {
        try String(
            contentsOf: repositoryRoot.appendingPathComponent(
                relativePath
            ),
            encoding: .utf8
        )
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
#endif
