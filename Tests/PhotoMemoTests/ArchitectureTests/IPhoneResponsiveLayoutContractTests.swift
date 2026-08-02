import Foundation
import Testing

@Suite("iPhone responsive layout contract")
struct IPhoneResponsiveLayoutContractTests {

    @Test("root delegates system presentation and runtime coordination")
    func rootDelegatesSystemPresentationAndRuntimeCoordination() throws {
        let root = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )

        #expect(root.contains("V1SubjectPresentationModifier("))
        #expect(root.contains("V1EditorPresentationModifier("))
        #expect(root.contains("V1WelcomeAndSettingsPresentationModifier("))
        #expect(root.contains("V1RootChangeObservationModifier("))
        #expect(root.contains("V1ConfigurationDeletionRuntimeCoordinator"))
        #expect(root.contains("V1ConfigurationApplyPayloadBuilder.build"))
        #expect(!root.contains("ConfigurationBackupRequest("))
        #expect(!root.contains("ConfigurationRestoreRequest("))
        #expect(root.components(separatedBy: "\n").count < 2_750)
    }

    @Test("shared page layout binds scroll content to the viewport")
    func sharedPageLayoutBindsScrollContentToViewport() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1AdaptivePageLayout.swift"
        )

        #expect(source.contains("maximumReadableContentWidth"))
        #expect(source.contains("containerRelativeFrame(.horizontal)"))
        #expect(source.contains("func v1AdaptiveScrollContent"))
        #expect(source.contains("func v1AdaptivePageContent"))
    }

    @Test("primary vertical pages adopt the shared viewport contract")
    func primaryVerticalPagesAdoptSharedViewportContract() throws {
        let scrollPageExpectations = [
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlow.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSheetSurface.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1WelcomePresentation.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterSidebarView.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1EditorPresentationModifier.swift"
        ]

        for path in scrollPageExpectations {
            let source = try sourceText(path)
            #expect(
                source.contains("v1AdaptiveScrollContent("),
                "Expected \(path) to bind vertical scroll content to the viewport."
            )
        }

        let editorSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1EditorPageSurface.swift"
        )
        #expect(editorSource.contains("v1AdaptivePageContent("))
        #expect(editorSource.contains("v1AdaptiveScrollContent("))

        let taskSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift"
        )
        #expect(taskSource.contains("ScrollView {"))
        #expect(taskSource.contains("v1AdaptiveScrollContent("))
    }

    @Test("home subject card provides a narrow width fallback")
    func homeSubjectCardProvidesNarrowWidthFallback() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift"
        )

        #expect(source.contains("responsiveCardContent"))
        #expect(source.contains("compactCardContent"))
        #expect(source.contains("ViewThatFits(in: .horizontal)"))
    }

    @Test("home header labels provide a narrow width fallback")
    func homeHeaderLabelsProvideNarrowWidthFallback() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )

        #expect(source.contains("adaptiveHeaderPills"))
        #expect(source.contains("regularTopHeaderSection"))
        #expect(source.contains("compactTopHeaderSection"))
        #expect(source.contains("ViewThatFits(in: .horizontal)"))
        #expect(source.contains("fixedSize(horizontal: true"))
    }

    @Test("home preset rows and settings disclosures preserve readable content")
    func compactRowsProvideVerticalFallbacks() throws {
        let home = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )
        let settings = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )

        #expect(home.contains("private var adaptivePresetRowContent"))
        #expect(home.contains("private var verticalPresetRowContent"))
        #expect(home.contains("dynamicTypeSize.isAccessibilitySize"))
        #expect(settings.contains("private var adaptiveDisclosureHeader"))
        #expect(settings.contains("private var verticalDisclosureHeader"))
    }

    @Test("processing pipeline and anchor category avoid fixed compact geometry")
    func processingPipelineAndAnchorCategoryAvoidFixedGeometry() throws {
        let processing = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift"
        )
        let anchors = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectAnchorDetailSection.swift"
        )

        #expect(processing.contains("private func pipelineStepTitle"))
        #expect(processing.contains(".frame(minHeight: 28)"))
        #expect(!processing.contains(".frame(height: 28)"))
        #expect(anchors.contains("private var categoryMenu"))
        #expect(anchors.contains("private var selectedDateText"))
        #expect(anchors.contains("ViewThatFits(in: .horizontal)"))
    }

    @Test("shared headings and semantic tokens support system accessibility")
    func sharedHeadingsAndSemanticTokensSupportSystemAccessibility() throws {
        let support = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )
        let tokens = try sourceText(
            "Source/PhotoMemo/PhotoMemo/App/MemoMarkDesignTokens.swift"
        )
        let home = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )

        #expect(support.contains(".accessibilityAddTraits(.isHeader)"))
        #expect(tokens.contains("enum Semantic"))
        #expect(tokens.contains("static let interaction = Color.accentColor"))
        #expect(tokens.contains("static let success"))
        #expect(tokens.contains("static let danger"))
        #expect(tokens.contains("enum Motion"))
        #expect(home.contains("MemoMarkDesignTokens.Semantic.quietInformation"))
        #expect(!home.contains(".fill(Color.blue.opacity(0.08))"))
    }

    @Test("home header gives the app mark and settings entry primary touch weight")
    func homeHeaderGivesTheAppMarkAndSettingsEntryPrimaryTouchWeight() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )

        #expect(source.contains(".frame(width: 70, height: 70)"))
        #expect(source.contains(".frame(width: 44, height: 44)"))
        #expect(source.contains(".font(.body.weight(.bold))"))
        #expect(source.contains(".foregroundStyle(.secondary)"))
        #expect(source.contains("Image(\"HomeAppIcon\")"))
        #expect(!source.contains("Image(systemName: \"photo.stack\")"))
    }

    @Test("configuration backup library uses a native row menu")
    func configurationBackupLibraryUsesNativeRowMenu() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1LocalConfigurationLibrarySheet.swift"
        )

        #expect(source.contains("Menu"))
        #expect(source.contains("恢复为副本"))
        #expect(source.contains("恢复并设为当前"))
        #expect(source.contains("Image(systemName: \"ellipsis\")"))
        #expect(!source.contains("adaptiveBackupActions"))
        #expect(!source.contains("compactBackupActions"))
    }

    @Test("configuration controls reflow for accessibility text sizes")
    func configurationControlsReflowForAccessibilityText() throws {
        let optionListSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )

        #expect(optionListSource.contains("@Environment(\\.dynamicTypeSize)"))
        #expect(optionListSource.contains("dynamicTypeSize.isAccessibilitySize"))
        #expect(optionListSource.contains("更多配置操作"))
        #expect(optionListSource.contains("adaptiveSectionHeader"))
        #expect(optionListSource.contains("adaptiveConfigurationRow"))
        #expect(optionListSource.contains("horizontalConfigurationRow"))
        #expect(optionListSource.contains("verticalConfigurationRow"))
        #expect(optionListSource.contains("ViewThatFits(in: .horizontal)"))
    }

    @Test("configuration footer and anchor editor remain reachable in short environments")
    func configurationFooterAndAnchorEditorRemainReachable() throws {
        let editor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1EditorPageSurface.swift"
        )
        let anchors = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectAnchorDetailSection.swift"
        )

        #expect(editor.contains(".safeAreaInset(edge: .bottom, spacing: 0)"))
        #expect(!editor.contains(".overlay(alignment: .bottom)"))
        #expect(anchors.contains(".presentationDetents([.height(390), .large])"))
        #expect(anchors.contains("ScrollView"))
    }

    @Test("region composer preserves chip size and reflows its action header")
    func regionComposerPreservesChipSizeAndReflowsActionHeader() throws {
        let support = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )

        #expect(support.contains("private var adaptiveComposerHeader"))
        #expect(support.contains("ViewThatFits(in: .horizontal)"))
        #expect(support.contains("ScrollView(.horizontal, showsIndicators: false)"))
    }

    @Test("output and processing preserve controls and copy at accessibility sizes")
    func outputAndProcessingPreserveAccessibilityContent() throws {
        let output = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift"
        )
        let processing = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift"
        )

        #expect(output.contains("private var adaptiveOutputTargetPicker"))
        #expect(output.contains("dynamicTypeSize.isAccessibilitySize"))
        #expect(output.contains(".pickerStyle(.segmented)"))
        #expect(output.contains(".pickerStyle(.menu)"))
        #expect(processing.contains("@Environment(\\.dynamicTypeSize)"))
        #expect(processing.contains("dynamicTypeSize.isAccessibilitySize ? 3 : 1"))
    }

    @Test("subject anchors and language settings provide vertical accessibility fallbacks")
    func subjectAnchorsAndLanguageSettingsProvideVerticalFallbacks() throws {
        let subjectAnchors = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewCardSections.swift"
        )
        let settings = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )

        #expect(subjectAnchors.contains("private func anchorTypePill"))
        #expect(subjectAnchors.contains("dynamicTypeSize.isAccessibilitySize"))
        #expect(subjectAnchors.contains("ViewThatFits(in: .horizontal)"))
        #expect(settings.contains("private var adaptiveInterfaceLanguagePicker"))
        #expect(settings.contains(".pickerStyle(.segmented)"))
        #expect(settings.contains(".pickerStyle(.menu)"))
    }

    @Test("configuration preview is full width and restores the page guidance")
    func configurationPreviewIsFullWidthAndRestoresPageGuidance() throws {
        let configurationPageSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationPageSurface.swift"
        )
        let supportSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )

        #expect(
            configurationPageSource.contains(
                "pageSubtitle: \"从一个人和一个重要时刻开始，让回忆慢慢成形。\""
            )
        )

        let previewStart = try #require(
            supportSource.range(of: "struct V1PreviewCard")?.lowerBound
        )
        let previewEnd = try #require(
            supportSource.range(
                of: "private var compactSpec",
                range: previewStart..<supportSource.endIndex
            )?.lowerBound
        )
        let previewBody = String(
            supportSource[previewStart..<previewEnd]
        )

        #expect(previewBody.contains(".aspectRatio(compactPreviewAspectRatio"))
        #expect(previewBody.contains("cornerRadius: ConfigurationUI.cornerRadius"))
        #expect(previewBody.contains(".stroke(ConfigurationUI.faintHairline)"))
        #expect(previewBody.contains("color: ConfigurationUI.cardShadow"))
        #expect(!previewBody.contains(".padding(12)"))
        #expect(!previewBody.contains(".v1CardChrome()"))
    }

    @Test("subject identity overview does not force intrinsic horizontal width")
    func subjectIdentityOverviewAvoidsForcedIntrinsicWidth() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )

        #expect(source.contains("adaptiveIdentityOverviewHeader"))
        #expect(source.contains("ViewThatFits(in: .horizontal)"))
        #expect(!source.contains(".fixedSize(horizontal: true, vertical: false)"))
    }

    @Test("subject overview uses the configuration-center card hierarchy")
    func subjectOverviewUsesConfigurationCenterCardHierarchy() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSheetSurface.swift"
        )

        #expect(source.contains("v1AdaptiveScrollContent("))
        #expect(source.contains("ConfigurationUI.contentColumnPadding"))
        #expect(!source.contains("GeometryReader"))
        #expect(source.contains("subjectIdentitySummary"))
        #expect(source.contains("subjectBasicInformation"))
        #expect(source.contains("V1TitledSectionCard("))
        #expect(source.contains("V1IOSSubjectAnchorDetailSection("))
        #expect(!source.contains("V1ConfigurationCardContainer"))
    }

    @Test("iPhone views do not branch on the physical screen or device model")
    func iPhoneViewsAvoidPhysicalScreenAndDeviceModelBranching() throws {
        let viewsDirectory = repositoryRoot
            .appendingPathComponent(
                "Source/PhotoMemo/PhotoMemo/iOS/Views",
                isDirectory: true
            )
        let paths = try FileManager.default.contentsOfDirectory(
            at: viewsDirectory,
            includingPropertiesForKeys: nil
        )
        .filter { $0.pathExtension == "swift" }

        for path in paths {
            let source = try String(contentsOf: path, encoding: .utf8)
            #expect(!source.contains("UIScreen.main.bounds"))
            #expect(!source.contains("utsname"))
        }
    }

    @Test("root navigation state owns entry disclosure and scroll position")
    func rootNavigationStateOwnsEntryDisclosureAndScrollPosition() throws {
        let navigationSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/EntryNavigationState.swift"
        )
        let rootSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )

        #expect(navigationSource.contains("var flowState: V1EntryFlowState"))
        #expect(navigationSource.contains("expandedEditorSections"))
        #expect(navigationSource.contains("profileOffsetY"))
        #expect(navigationSource.contains("previewOffsetY"))
        #expect(rootSource.contains("private var entryNavigationState"))
        #expect(rootSource.contains("private var entryFlowState: V1EntryFlowState {"))
        #expect(!rootSource.contains("private var entryFlowState ="))
        #expect(!rootSource.contains("@State\n    private var expandedEditorSections"))
        #expect(!rootSource.contains("@State\n    private var profileOffsetY"))
        #expect(!rootSource.contains("@State\n    private var previewOffsetY"))
    }

    @Test("root groups media picker presentation without moving intake ownership")
    func rootGroupsMediaPickerPresentationState() throws {
        let root = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )
        let presentation = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1RootPresentationState.swift"
        )

        #expect(presentation.contains("struct V1MediaPickerPresentationState"))
        #expect(presentation.contains("selectedProcessingItems"))
        #expect(presentation.contains("selectedLogoItem"))
        #expect(presentation.contains("isOptimizingLogo"))
        #expect(root.contains("private var mediaPickerPresentation"))
        #expect(!root.contains("private var selectedProcessingItems"))
        #expect(!root.contains("private var selectedLogoItem"))
        #expect(!root.contains("private var isOptimizingLogo"))
        #expect(root.contains("externalIntakeCenter.submit"))
    }

    @Test("adaptive entry navigation is stateless and preserves all destinations")
    func adaptiveEntryNavigationIsStatelessAndPreservesAllDestinations() throws {
        let navigationSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1AdaptiveNavigationShell.swift"
        )
        let rootSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )

        #expect(navigationSource.contains("struct V1EntryNavigationSurface<"))
        #expect(navigationSource.contains("@Binding\n    var selection: V1EntryTab"))
        #expect(navigationSource.contains("TabView(selection: $selection)"))
        #expect(navigationSource.contains(".tag(V1EntryTab.home)"))
        #expect(navigationSource.contains(".tag(V1EntryTab.editor)"))
        #expect(navigationSource.contains(".tag(V1EntryTab.output)"))
        #expect(navigationSource.contains(".tag(V1EntryTab.tasks)"))
        #expect(navigationSource.contains("case .settings:"))
        #expect(!navigationSource.contains("@State"))
        #expect(!navigationSource.contains("ConfigurationSession"))
        #expect(rootSource.contains("V1EntryNavigationSurface("))
    }
}

private extension IPhoneResponsiveLayoutContractTests {

    var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    func sourceText(_ relativePath: String) throws -> String {
        try String(
            contentsOf: repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}
