#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing

@Suite("Share Extension controller responsibility split")
struct ShareExtensionControllerSplitContractTests {

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

        #expect(renderer.contains("final class ShareExtensionViewStateRenderer"))
        #expect(preview.contains("final class ShareExtensionPreviewController"))
        #expect(handoff.contains("final class ShareExtensionHandoffCoordinator"))
        #expect(progress.contains("final class ShareExtensionProgressObserver"))
        #expect(controller.contains("ShareExtensionViewStateRenderer"))
        #expect(controller.contains("ShareExtensionPreviewController"))
        #expect(controller.contains("ShareExtensionHandoffCoordinator"))
        #expect(controller.contains("ShareExtensionProgressObserver"))
        #expect(!controller.contains("func requestMainAppRefreshThroughResponderChain"))
        #expect(!controller.contains("func observeProcessingProgress"))
        #expect(!controller.contains("func makePreviewCard"))
        #expect(!controller.contains("func updatePreviewRows"))
        #expect(!controller.contains("func handlePreviewCardTap"))
        #expect(!controller.contains("previewStatusBadgeViews"))
        #expect(preview.contains("func configurePlaceholders"))
        #expect(preview.contains("func updateRows"))
        #expect(preview.contains("func applyImages"))
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
