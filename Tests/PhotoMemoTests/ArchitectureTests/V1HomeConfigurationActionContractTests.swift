import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 home configuration action contract")
struct V1HomeConfigurationActionContractTests {

    @Test("home presents a dismissible first-install Apple Photos workflow")
    func homeMakesApplePhotosSharingPrimary() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )
        let rootSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )
        let presentationSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1WelcomeAndSettingsPresentationModifier.swift"
        )

        #expect(source.contains("applePhotosEntrySection"))
        #expect(source.contains("home.apple_photos.title"))
        #expect(source.contains("photomemo.v1.applePhotosGuideDismissed"))
        #expect(source.contains("if !hasDismissedApplePhotosGuide"))
        #expect(source.contains("dismissApplePhotosGuide"))
        #expect(source.contains("Image(systemName: \"xmark\")"))
        #expect(source.contains("V1WelcomePresentation.workflowSteps"))
        #expect(source.contains("ForEach(applePhotosWorkflowSteps)"))
        #expect(source.contains("home.next_share.configuration_format"))
        #expect(source.contains("onOpenWorkflowGuide"))
        #expect(source.contains("home.process.choose_photo"))
        #expect(!source.contains("备用：App 内选择照片"))
        #expect(source.contains(".v1CompactBottomPrimaryAction()"))
        #expect(source.contains("V1CompactPrimaryActionButtonStyle()"))
        #expect(!source.contains("applePhotosEntryIcon"))
        #expect(rootSource.contains("entryFlowState.showsWorkflowGuide = true"))
        #expect(presentationSource.contains("V1WorkflowGuideSurface("))
        #expect(!rootSource.contains("V1WorkflowGuideSurface("))
    }

    @Test("home keeps the complete daily workflow visible below presets")
    func homeKeepsWorkflowReminderBelowPresets() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )

        let presetPosition = try #require(
            source.range(of: "currentPresetSection")
        )
        let reminderPosition = try #require(
            source.range(of: "workflowReminderCard")
        )
        #expect(reminderPosition.lowerBound > presetPosition.lowerBound)
        #expect(source.contains("private struct V1HomeWorkflowReminderCard"))
        #expect(source.contains("home.workflow.title"))
        #expect(source.contains("home.workflow.detail"))
        #expect(source.contains("home.workflow.note"))

        let cardSource = try #require(
            source.components(
                separatedBy: "private struct V1HomeWorkflowReminderCard"
            ).last
        )
        #expect(!cardSource.contains("Image(systemName:"))
    }

    @Test("configuration rows use native non-full-swipe actions")
    func rowSwipeActionsExposeSaveAndDelete() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )

        #expect(source.contains(".swipeActions("))
        #expect(source.contains("allowsFullSwipe: false"))
        let normalizedSource = source.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        #expect(normalizedSource.contains("home.preset.save"))
        #expect(normalizedSource.contains("MemoMarkSymbol.localStorage.name"))
        #expect(source.contains(".tint(.blue)"))
        #expect(source.contains("home.preset.delete"))
        #expect(source.contains(".tint(.red)"))
        #expect(source.contains("Button(role: .destructive)"))
        #expect(source.contains("showsDeleteConfirmation = true"))
        #expect(!source.contains("DragGesture(minimumDistance: 12)"))
        #expect(!source.contains("V1HomeConfigurationSwipePresenter"))
        #expect(source.contains("home.preset.save_accessibility"))
        #expect(source.contains("home.preset.delete_accessibility"))
        #expect(source.contains("home.preset.more_actions"))
        #expect(source.contains("Image(systemName: \"ellipsis.circle\")"))
        #expect(source.contains("home.preset.rename"))
        #expect(!source.contains("accessibilityLabel(\"重命名配置\")"))
        #expect(source.contains("home.preset.delete_confirmation"))
    }

    @Test("swipe-action rows avoid nested collection-view lists")
    func swipeActionRowsAvoidNestedCollectionViewLists() throws {
        let homeSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )
        let subjectSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let subjectSheetSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSheetSurface.swift"
        )

        #expect(homeSource.contains("ForEach(memoryPresets)"))
        #expect(subjectSource.contains("private var timeAnchorListEditor"))
        #expect(subjectSource.contains("List {"))
        #expect(
            homeSource.range(
                of: #"\bList\s*(?:\{|\()"#,
                options: .regularExpression
            ) == nil
        )
        #expect(
            subjectSheetSource.contains(
                "V1IOSSubjectAnchorDetailSection("
            )
        )
        #expect(!subjectSheetSource.contains("List {"))
    }

    @Test("configuration header uses a clean overflow action with guidance below the rows")
    func headerUsesOverflowActionWithGuidanceBelowTheRows() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )

        #expect(source.contains("V1CardHeaderIconButton("))
        #expect(source.contains("systemImage: \"ellipsis\""))
        #expect(source.contains("home.presets.manage"))
        #expect(source.contains("onOpenLocalConfigurationLibrary"))
        #expect(source.contains("home.presets.manage_hint"))
        #expect(source.contains("home.presets.edit_hint"))
        #expect(!source.contains("Text(\"勾选生效\")"))
        #expect(!source.contains("Image(systemName: \"plus\")"))
    }

    @Test("card header actions share the native icon-button treatment")
    func cardHeaderActionsShareTheNativeIconButtonTreatment() throws {
        let supportSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )
        let subjectSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSheetSurface.swift"
        )
        let taskSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift"
        )

        #expect(supportSource.contains("struct V1CardHeaderIconButton"))
        #expect(supportSource.contains(".frame(width: 44, height: 44)"))
        #expect(supportSource.contains(".secondarySystemFill"))
        #expect(subjectSource.contains("systemImage: \"pencil\""))
        #expect(taskSource.contains("systemImage: \"ellipsis\""))
        #expect(taskSource.contains("trailingAccessory:"))
    }

    @Test("home separates blocking failures from non-modal success feedback")
    func homeSurfacesConfigurationActionFeedback() throws {
        let rootSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )
        let actionSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationLibraryActions.swift"
        )
        let presentationSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1RootPresentationState.swift"
        )

        #expect(presentationSource.contains("var homeActionFeedback: String?"))
        #expect(rootSource.contains("homeConfigurationStatusBanner"))
        #expect(presentationSource.contains("var showsHomeActionFailureAlert = false"))
        #expect(!rootSource.contains("\"配置操作\""))
        #expect(!rootSource.contains("Button(\"知道了\""))
        #expect(rootSource.contains("presentHomeConfigurationActionFeedback"))
        #expect(rootSource.contains("configurationLibraryActions.decide"))
        #expect(actionSource.contains("case applyCurrentThenDelete"))
        #expect(actionSource.contains("case persistDeletion"))
        #expect(actionSource.contains("reconcilingRevision"))
    }

    @Test("rename and save callbacks use explicit action decisions")
    func renameAndSaveCallbacksUseExplicitActionDecisions() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )

        #expect(source.contains("case .beginRename(let title):"))
        #expect(source.contains("renamePresentation.titleDraft = title"))
        #expect(source.contains("case .commitRenameAndSave(let title):"))
        #expect(!source.contains("case .rename(let title):"))
        #expect(
            source.components(
                separatedBy:
                    "performConfigurationLibraryAction(.saveCurrent)"
            ).count - 1 == 2
        )
        #expect(source.contains("case .saveCurrent:"))
        #expect(
            source.contains("startCurrentConfigurationSaveWithFeedback()")
        )
        #expect(!source.contains("decide(.saveCurrent)"))
    }
}

private extension V1HomeConfigurationActionContractTests {

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
