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

    @Test("configuration unavailable controls expose native disabled states")
    func configurationUnavailableControlsUseNativeStates() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )

        #expect(source.contains(".disabled(!isLocationSelectable)"))
        #expect(source.contains("ProgressView()"))
        #expect(source.contains(".buttonStyle(.bordered)"))
    }

    @Test("configuration destructive actions require confirmation")
    func configurationDestructiveActionsRequireConfirmation() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )

        #expect(source.contains("showsResetConfigurationConfirmation"))
        #expect(source.contains("showsDeleteConfigurationConfirmation"))
        #expect(source.contains("恢复默认配置？"))
        #expect(source.contains("删除当前配置？"))
        #expect(source.contains("role: .destructive"))
        #expect(source.contains(".disabled(isSavingConfiguration)"))
    }

    @Test("compact primary actions share state and press feedback")
    func compactPrimaryActionsShareStateAndFeedback() throws {
        let rootSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )
        let homeSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )
        let outputSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift"
        )
        let supportSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )

        #expect(rootSource.contains("configurationStatus: activeConfigurationStatus"))
        #expect(outputSource.contains("let configurationStatus: V1ConfigurationStatus"))
        #expect(outputSource.contains("\"已保存\""))
        #expect(outputSource.contains("\"重新保存\""))
        #expect(homeSource.contains("V1CompactPrimaryActionButtonStyle()"))
        #expect(outputSource.contains("V1CompactPrimaryActionButtonStyle()"))
        #expect(supportSource.contains("struct V1CompactPrimaryActionButtonStyle"))
        #expect(supportSource.contains("accessibilityReduceMotion"))
    }

    @Test("configuration disclosures use interruptible reduced-motion-aware springs")
    func configurationDisclosuresUseInterruptibleSprings() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/IOSCompactEntryRow.swift"
        )

        #expect(source.contains("accessibilityReduceMotion"))
        #expect(source.contains(".interactiveSpring("))
        #expect(source.contains("response: 0.32"))
        #expect(source.contains("dampingFraction: 1"))
        #expect(source.contains("blendDuration: 0.08"))
        #expect(!source.contains(".easeInOut(duration: 0.18)"))
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
