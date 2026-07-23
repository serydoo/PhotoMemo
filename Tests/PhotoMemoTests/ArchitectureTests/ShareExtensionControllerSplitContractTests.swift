#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing

@Suite("Share Extension controller responsibility split")
struct ShareExtensionControllerSplitContractTests {

    @Test("Share Extension uses compact Apple-native handoff language")
    func shareExtensionUsesCompactAppleNativeHandoffLanguage() throws {
        let controller = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift"
        )
        let renderer = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareExtensionViewStateRenderer.swift"
        )
        let typography = try sourceText(
            "Source/PhotoMemo/PhotoMemo/App/MemoMarkDesignTokens.swift"
        )

        #expect(controller.contains("height: 440"))
        #expect(controller.contains("本次分享"))
        #expect(controller.contains("scheduleSuccessfulDismissal"))
        #expect(controller.contains("scrollView.topAnchor"))
        #expect(controller.contains("constant: 36"))
        #expect(controller.contains("override func viewDidAppear"))
        #expect(controller.contains("summary.memorySubjectTitle"))
        #expect(controller.contains("makeQuoteStack"))
        #expect(controller.contains("今天的照片"))
        #expect(controller.contains("contentStack.addArrangedSubview(quoteStack)"))
        #expect(controller.contains("title: \"配置\""))
        #expect(controller.contains("title: \"相册\""))
        #expect(controller.contains("constant: -24"))
        #expect(controller.contains("stack.spacing = 8"))
        #expect(controller.contains("baseBackgroundColor =\n            .systemBlue"))
        #expect(controller.contains("baseForegroundColor =\n            .white"))
        #expect(!controller.contains("这次会如何处理"))
        #expect(!controller.contains("默认风格"))
        #expect(!controller.contains("结果去向"))
        #expect(renderer.contains("已准备好"))
        #expect(renderer.contains("已开始处理"))
        #expect(renderer.contains("后台继续处理"))
        #expect(renderer.contains("\\(input.photoCount) 张照片准备开始记录"))
        #expect(renderer.contains("photo.stack.fill"))
        #expect(renderer.contains("doc.badge.gearshape"))
        #expect(renderer.contains("bell.fill"))
        #expect(renderer.contains("arrow.right.circle.fill"))
        #expect(renderer.contains("hierarchicalColor"))
        #expect(!renderer.contains("UIColor.systemGreen"))
        #expect(!renderer.contains("UIColor.systemBlue"))
        #expect(renderer.contains("showsProcessingChecklist"))
        #expect(renderer.contains("生成时光记录"))
        #expect(typography.contains("enum MemoMarkDesignTokens"))
        #expect(typography.contains("static let hero"))
        #expect(typography.contains("static let heroSubtitle"))
        #expect(typography.contains("static let sectionTitle"))
        #expect(typography.contains("static let value"))
        #expect(typography.contains("static let detail"))
        #expect(typography.contains("static let brand"))
        #expect(typography.contains("var swiftUIFont"))
        #expect(typography.contains("func uiFont"))
        #expect(typography.contains("size: 28"))
        #expect(typography.contains("size: 17"))
        #expect(typography.contains("size: 20"))
        #expect(typography.contains("size: 15"))
        #expect(typography.contains("size: 14"))
    }

    @Test("Share Extension owns focused lifecycle collaborators")
    func shareExtensionOwnsFocusedLifecycleCollaborators() throws {
        let controller = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift"
        )
        let renderer = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareExtensionViewStateRenderer.swift"
        )
        let preview = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareExtensionPreviewController.swift"
        )
        let handoff = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareExtensionHandoffCoordinator.swift"
        )
        let progress = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareExtensionProgressObserver.swift"
        )
        let intake = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareExtensionIntakeCoordinator.swift"
        )

        #expect(renderer.contains("final class ShareExtensionViewStateRenderer"))
        #expect(preview.contains("final class ShareExtensionPreviewController"))
        #expect(handoff.contains("final class ShareExtensionHandoffCoordinator"))
        #expect(progress.contains("final class ShareExtensionProgressObserver"))
        #expect(intake.contains("final class ShareExtensionIntakeCoordinator"))
        #expect(controller.contains("ShareExtensionViewStateRenderer"))
        #expect(controller.contains("ShareExtensionPreviewController"))
        #expect(controller.contains("ShareExtensionHandoffCoordinator"))
        #expect(controller.contains("ShareExtensionProgressObserver"))
        #expect(controller.contains("ShareExtensionIntakeCoordinator"))
        #expect(!controller.contains("func requestMainAppRefreshThroughResponderChain"))
        #expect(!controller.contains("func observeProcessingProgress"))
        #expect(!controller.contains("func makePreviewCard"))
        #expect(!controller.contains("func updatePreviewRows"))
        #expect(!controller.contains("func handlePreviewCardTap"))
        #expect(!controller.contains("previewStatusBadgeViews"))
        #expect(!controller.contains("batchSnapshotService"))
        #expect(!controller.contains("SharedBatchQueueSnapshotService"))
        #expect(!controller.contains(".persistSharedItems("))
        #expect(!controller.contains("detailedFailureMessage"))
        #expect(!controller.contains("detailedSuggestion"))
        #expect(!controller.contains("func holdCompletionStateBeforeDismissal"))
        #expect(!controller.contains("func applyWaitingForQueueState"))
        #expect(!controller.contains("func applyWaitingForAppState"))
        #expect(!controller.contains("func applyProcessingSnapshot"))
        #expect(!controller.contains("func activeTaskNumber"))
        #expect(!controller.contains("func currentProgressMessage"))
        #expect(intake.contains(".persistSharedItems("))
        #expect(intake.contains("detailedFailureMessage"))
        #expect(intake.contains("detailedSuggestion"))
        #expect(preview.contains("func configurePlaceholders"))
        #expect(preview.contains("func updateRows"))
        #expect(preview.contains("func applyImages"))
        #expect(preview.contains("func loadPreviews"))
    }

    private func sourceText(_ relativePath: String) throws -> String {
        let fileURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent(relativePath)
        return try String(contentsOf: fileURL, encoding: .utf8)
    }
}
#endif
