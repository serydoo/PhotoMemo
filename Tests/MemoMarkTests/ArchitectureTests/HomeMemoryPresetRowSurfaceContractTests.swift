#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("Home memory preset row surface")
struct HomeMemoryPresetRowSurfaceContractTests {

    @Test("preset-row presentation stays separate from preset selection ownership")
    func presetRowStaysOutsideTheHomeCoordinator() throws {
        let homeSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/HomePageSurface.swift"
        )
        let rowSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/HomeMemoryPresetRow.swift"
        )

        #expect(homeSource.contains("HomeMemoryPresetRow("))
        #expect(!homeSource.contains("private struct HomeMemoryPresetRow"))
        #expect(rowSource.contains("struct HomeMemoryPresetRow: View"))
        #expect(rowSource.contains("let preset: MemoryPreset"))
        #expect(rowSource.contains("let onSelect: () -> Void"))
        #expect(rowSource.contains("dynamicTypeSize.isAccessibilitySize"))
        #expect(rowSource.contains("ViewThatFits(in: .horizontal)"))
        #expect(rowSource.contains("home.preset.identity_format"))
        #expect(!rowSource.contains("ConfigurationSession"))
        #expect(!rowSource.contains("saveConfiguration"))
        #expect(!rowSource.contains("BatchQueueStore"))
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
