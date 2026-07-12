#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing

@Suite("V1 native system interaction contract")
struct V1NativeSystemInteractionContractTests {

    @Test("output target uses a native segmented picker")
    func outputTargetUsesSegmentedPicker() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift"
        )

        #expect(source.contains("\"输出目标\","))
        #expect(source.contains(".pickerStyle(.segmented)"))
        #expect(!source.contains("private struct V1OutputTargetGrid"))
    }

    @Test("recent task history uses a native list sheet")
    func recentTasksUseNativeListSheet() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift"
        )

        #expect(source.contains("List(presentation.historyRows)"))
        #expect(source.contains(".listStyle(.plain)"))
        #expect(source.contains("Button(\"完成\")"))
    }

    @Test("backup swipe confirmation avoids destructive precommit")
    func backupSwipeAvoidsDestructivePrecommit() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1LocalConfigurationLibrarySheet.swift"
        )

        #expect(source.contains(".tint(.red)"))
        #expect(source.contains("allowsFullSwipe: false"))
    }
}

private extension V1NativeSystemInteractionContractTests {

    func sourceText(_ relativePath: String) throws -> String {
        let testsDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
        let repositoryRoot = testsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}
#endif
