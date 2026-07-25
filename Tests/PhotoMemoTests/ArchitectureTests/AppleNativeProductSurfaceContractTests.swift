#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing

@Suite("Apple native product surface contract")
struct AppleNativeProductSurfaceContractTests {

    @Test("processing surface avoids dashboard and import-first language")
    func processingSurfaceAvoidsDashboardLanguage() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift"
        )

        #expect(!source.contains("overviewStrip"))
        #expect(!source.contains("开始处理"))
        #expect(!source.contains("从首页选择照片开始"))
        #expect(source.contains("处理"))
        #expect(source.contains("从 Apple Photos 分享照片"))
    }

    @Test("output persistence copy names output settings")
    func outputPersistenceNamesOutputSettings() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift"
        )

        #expect(source.contains("输出设置已保存"))
        #expect(source.contains("保存输出设置"))
        #expect(source.contains("保留拍摄信息"))
        #expect(!source.contains("保留 EXIF 信息"))
    }

    @Test("background status avoids fixed time estimates")
    func backgroundStatusAvoidsFixedTimeEstimates() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/App/PhotoMemoBackgroundStatusService.swift"
        )

        #expect(!source.contains("estimatedSeconds("))
        #expect(!source.contains("约 \\(totalEstimatedSeconds) 秒"))
        #expect(!source.contains("约 \\(minutes) 分钟"))
    }

    @Test("home keeps product objects and removes repeated promotion")
    func homeKeepsObjectsAndRemovesRepeatedPromotion() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )

        #expect(!source.contains("developmentBackgroundSection"))
        #expect(!source.contains("V1HomeFeedbackSection"))
        #expect(source.contains("profileSection"))
        #expect(source.contains("currentPresetSection"))
        #expect(source.contains("选择照片"))
    }

    @Test("settings starts with secondary explanations collapsed")
    func settingsStartsSecondaryExplanationsCollapsed() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )

        #expect(source.contains("expandedSections: Set<SettingsSection> = []"))
    }

    @Test("interactive surfaces respect reduced motion")
    func interactiveSurfacesRespectReducedMotion() throws {
        let paths = [
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift",
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCardConfigurationComponentDock.swift",
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCardCompactPreview.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        ]

        for path in paths {
            let source = try sourceText(path)
            #expect(source.contains("accessibilityReduceMotion"))
        }
    }

    @Test("configuration center presents objects instead of engineering regions")
    func configurationCenterUsesUserFacingHierarchy() throws {
        let options = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let center = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift"
        )
        let preview = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterTopPreviewSection.swift"
        )

        #expect(options.contains("保存配置"))
        #expect(options.contains("更多配置操作"))
        #expect(options.contains("编辑卡片内容"))
        #expect(!options.contains("index: \"1.\""))
        #expect(center.contains("title: \"拍摄信息\""))
        #expect(center.contains("subtitle: \"卡片区域 C\""))
        #expect(!preview.contains("Apple Photos -> Share"))
        #expect(!preview.contains("workflowChips"))
    }

    @Test("primary product rows grow with accessibility text")
    func primaryRowsUseContentDrivenHeight() throws {
        let home = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )
        let processing = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift"
        )

        #expect(!home.contains("CGFloat(memoryPresets.count) * 92"))
        #expect(processing.contains(".frame(minHeight: 78)"))
        #expect(!processing.contains(".frame(height: 78)"))
    }
}

private extension AppleNativeProductSurfaceContractTests {

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
