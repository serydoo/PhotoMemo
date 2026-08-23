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
        #expect(controller.contains("share.summary"))
        #expect(controller.contains("scheduleSuccessfulDismissal"))
        #expect(controller.contains("scrollView.topAnchor"))
        #expect(controller.contains("MemoMarkDesignTokens.Share.contentTopInset"))
        #expect(controller.contains("override func viewDidAppear"))
        #expect(controller.contains("summary.memorySubjectTitle"))
        #expect(controller.contains("makeQuoteStack"))
        #expect(controller.contains("share.summary.photo"))
        #expect(controller.contains("contentStack.addArrangedSubview(quoteStack)"))
        #expect(controller.contains("share.summary.configuration"))
        #expect(controller.contains("share.summary.album"))
        #expect(controller.contains("MemoMarkDesignTokens.Share.bottomActionInset"))
        #expect(controller.contains("stack.spacing = 8"))
        #expect(controller.contains("view.tintColor ?? UIColor.tintColor"))
        #expect(controller.contains("baseForegroundColor =\n            .white"))
        #expect(!controller.contains("这次会如何处理"))
        #expect(!controller.contains("默认风格"))
        #expect(!controller.contains("结果去向"))
        #expect(renderer.contains("share.ready.subtitle"))
        #expect(renderer.contains("share.status.stage.submitted"))
        #expect(controller.contains("share.success.remaining_note"))
        #expect(controller.contains("photo.stack.fill"))
        #expect(controller.contains("doc.badge.gearshape"))
        #expect(controller.contains("bell.fill"))
        #expect(controller.contains("arrow.right.circle.fill"))
        #expect(controller.contains("MemoMarkDesignTokens.Share.checklistIconSize"))
        #expect(!renderer.contains("UIColor.systemGreen"))
        #expect(!renderer.contains("UIColor.systemBlue"))
        #expect(renderer.contains("showsProcessingChecklist"))
        #expect(renderer.contains("share.status.button.create_record"))
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
        #expect(typography.contains("compactPrimaryActionWidth: CGFloat = 184"))
        #expect(typography.contains("primaryActionHitTarget: CGFloat = 44"))
        #expect(typography.contains("compactPrimaryActionCornerRadius: CGFloat = 12"))
        #expect(controller.contains("MemoMarkDesignTokens.Layout.compactPrimaryActionWidth"))
        #expect(controller.contains("MemoMarkDesignTokens.Share.primaryActionHitTarget"))
        #expect(controller.contains("MemoMarkDesignTokens.Layout.compactPrimaryActionCornerRadius"))
        #expect(controller.contains("UIImage(systemName: \"sparkles\")"))
        #expect(controller.contains("primaryButton.configuration?.imagePadding =\n            8"))
        #expect(controller.contains("makeTitledCardContainer("))
        #expect(controller.contains("makeInnerCardContainer("))
        #expect(controller.contains("makeInsetDivider()"))
        #expect(controller.contains("stack.alignment = .fill"))
    }

    @Test("Share Extension normal handoff states keep one stable visual shell")
    func shareExtensionNormalHandoffStatesKeepOneStableVisualShell() throws {
        let controller = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift"
        )
        let renderer = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareExtensionViewStateRenderer.swift"
        )
        let tokens = try sourceText(
            "Source/PhotoMemo/PhotoMemo/App/MemoMarkDesignTokens.swift"
        )

        #expect(renderer.contains("func normalTitle("))
        #expect(renderer.contains("func normalSubtitle("))
        #expect(renderer.components(separatedBy: "title: normalTitle(input)").count == 4)
        #expect(renderer.components(separatedBy: "subtitle: normalSubtitle(input)").count == 4)
        #expect(renderer.components(separatedBy: "statusTitle: localized(\"share.status.title\"").count >= 2)
        #expect(renderer.components(separatedBy: "showsProcessingChecklist: true").count == 3)
        #expect(renderer.contains("showsProcessingChecklist: isNormalConfirmation"))
        #expect(renderer.contains("share.status.stage.waiting"))
        #expect(renderer.contains("share.status.stage.receiving"))
        #expect(renderer.contains("share.status.stage.submitted"))
        #expect(renderer.contains("share.status.button.submitted"))
        #expect(renderer.contains("buttonSystemImage: \"checkmark\""))
        #expect(controller.contains("private let statusSymbolView"))
        #expect(controller.contains("private let statusStageLabel"))
        #expect(controller.contains("makeStatusStageStack()"))
        #expect(tokens.contains("static let compactCardCornerRadius: CGFloat = 18"))
        #expect(tokens.contains("static let compactCardPadding: CGFloat = 14"))
        #expect(tokens.contains("static let compactInnerCardPadding: CGFloat = 12"))
        #expect(controller.contains("MemoMarkDesignTokens.Layout.compactCardCornerRadius"))
        #expect(controller.contains("MemoMarkDesignTokens.Layout.compactCardPadding"))
        #expect(controller.contains(".compactInnerCardPadding"))
        #expect(
            controller.contains(
                ".received,\n                photoCount: sharedPhotoCount"
            )
        )
        #expect(controller.contains("nanoseconds: 700_000_000"))
        #expect(!controller.contains("灰色等待，蓝色处理中，绿色完成，红色需要处理。"))
        #expect(renderer.contains("formatted("))
    }

    @Test("Share Extension summary dividers use symmetric native hairlines")
    func shareExtensionSummaryDividersUseSymmetricNativeHairlines() throws {
        let controller = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift"
        )
        let tokens = try sourceText(
            "Source/PhotoMemo/PhotoMemo/App/MemoMarkDesignTokens.swift"
        )

        #expect(controller.contains("divider.backgroundColor =\n            .separator"))
        #expect(controller.contains("equalToConstant: 1 / UIScreen.main.scale"))
        #expect(controller.contains("constant: MemoMarkDesignTokens.Layout.dividerInset"))
        #expect(controller.contains("constant: -MemoMarkDesignTokens.Layout.dividerInset"))
        #expect(tokens.contains("static let dividerInset: CGFloat = 12"))
    }

    @Test("Share Extension keeps semantic heading and action targets")
    func shareExtensionKeepsSemanticHeadingAndActionTargets() throws {
        let controller = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift"
        )
        let tokens = try sourceText(
            "Source/PhotoMemo/PhotoMemo/App/MemoMarkDesignTokens.swift"
        )

        #expect(controller.contains("brandLabel.accessibilityTraits =\n            .staticText"))
        #expect(controller.contains("titleLabel.accessibilityTraits =\n            .header"))
        #expect(controller.contains("MemoMarkDesignTokens.Share.primaryActionHitTarget"))
        #expect(controller.contains("MemoMarkDesignTokens.Share.contentTopInset"))
        #expect(tokens.contains("enum Share"))
        #expect(tokens.contains("static let primaryActionHitTarget: CGFloat = 44"))
    }

    @Test("Share processing assurances use independent native rows")
    func shareProcessingAssurancesUseIndependentNativeRows() throws {
        let controller = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift"
        )
        let renderer = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareExtensionViewStateRenderer.swift"
        )
        let englishLocalization = try sourceText(
            "Source/PhotoMemo/PhotoMemo/en.lproj/Localizable.strings"
        )
        let chineseLocalization = try sourceText(
            "Source/PhotoMemo/PhotoMemo/zh-Hans.lproj/Localizable.strings"
        )

        #expect(controller.contains("private let processingChecklistStack ="))
        #expect(controller.contains("makeProcessingChecklistStack()"))
        #expect(controller.contains("makeProcessingChecklistRow("))
        #expect(renderer.contains("statusChecklistStack"))
        #expect(!renderer.contains("NSTextAttachment"))
        #expect(
            englishLocalization.contains(
                "\"后台继续处理\" = \"Continues in the background\";"
            )
        )
        #expect(
            chineseLocalization.contains(
                "\"后台继续处理\" = \"后台继续处理\";"
            )
        )
    }

    @Test("Share hero subtitle avoids repeating the summary count")
    func shareHeroSubtitleAvoidsRepeatingSummaryCount() throws {
        let renderer = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareExtensionViewStateRenderer.swift"
        )

        #expect(renderer.contains("share.ready.subtitle"))
        #expect(!renderer.contains("\\(input.photoCount) 张照片准备开始记录"))
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
