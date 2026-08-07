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
        #expect(root.contains("productionDiagnosticsRepository"))
        #expect(!root.contains("ConfigurationBackupRequest("))
        #expect(!root.contains("ConfigurationRestoreRequest("))
        #expect(root.components(separatedBy: "\n").count < 2_800)
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
        #expect(source.contains("alignment: .center"))
    }

    @Test("section cards share one compact accessible header rhythm")
    func sectionCardsShareCompactHeaderRhythm() throws {
        let support = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )
        let configuration = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )

        #expect(support.contains("enum V1SectionCardMetrics"))
        #expect(support.contains("static let headerContentSpacing: CGFloat = 10"))
        #expect(support.contains("static let sectionSpacing: CGFloat = 12"))
        #expect(
            support.contains(
                "static let cardHeaderMinimumHeight: CGFloat = 28"
            )
        )
        #expect(support.contains("spacing: V1SectionCardMetrics.cardHeaderContentSpacing"))
        #expect(
            support.contains(
                "V1SectionCardMetrics.cardHeaderMinimumHeight"
            )
        )
        #expect(
            support.contains(
                "static let cardHeaderContentSpacing: CGFloat = 6"
            )
        )
        #expect(
            support.contains(
                "static let cardVerticalPadding: CGFloat = 10"
            )
        )
        #expect(
            support.contains(
                ".padding(.vertical, V1SectionCardMetrics.cardVerticalPadding)"
            )
        )
        #expect(configuration.contains("spacing: V1SectionCardMetrics.cardHeaderContentSpacing"))
        #expect(configuration.contains("minHeight: V1SectionCardMetrics.cardHeaderMinimumHeight"))
        #expect(configuration.contains("V1SectionCardMetrics.cardVerticalPadding"))
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
            if path ==
                "Source/PhotoMemo/PhotoMemo/iOS/Views/V1EditorPresentationModifier.swift" {
                #expect(
                    source.contains("editorContent"),
                    "The card editor owns its fixed header and internal scroll surface."
                )
                continue
            }
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
        #expect(anchors.contains("@Environment(\\.dynamicTypeSize)"))
        #expect(anchors.contains("dynamicTypeSize.isAccessibilitySize"))
        #expect(!anchors.contains("ViewThatFits(in: .horizontal)"))
        #expect(anchors.contains("V1CompactSelectionLabel("))
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
        #expect(!optionListSource.contains("ViewThatFits(in: .horizontal)"))
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
        #expect(
            anchors.contains(
                ".height(ConfigurationUI.compactSheetHeight)"
            )
        )
        #expect(anchors.contains("ScrollView"))
    }

    @Test("configuration preview stays above the inspector at every viewport")
    func configurationPreviewStaysAboveInspector() throws {
        let editor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1EditorPageSurface.swift"
        )

        #expect(editor.contains("private var stackedContent"))
        #expect(editor.contains("previewPane"))
        #expect(editor.contains("editorScrollView"))
        #expect(!editor.contains("sideBySideContent"))
        #expect(!editor.contains("availableWidth * 0.46"))
    }

    @Test("configuration preview fills the centered readable column")
    func configurationPreviewFillsCenteredReadableColumn() throws {
        let editor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1EditorPageSurface.swift"
        )
        let previewStart = try #require(
            editor.range(of: "private var previewPane")?.lowerBound
        )
        let previewEnd = try #require(
            editor.range(
                of: "    private var editorScrollView",
                range: previewStart..<editor.endIndex
            )?.lowerBound
        )
        let previewBody = String(editor[previewStart..<previewEnd])

        #expect(previewBody.contains("previewContent"))
        #expect(previewBody.contains("maxWidth: .infinity"))
        #expect(previewBody.contains("alignment: .center"))
    }

    @Test("region composer keeps text editing separate from module selection")
    func regionComposerKeepsTextEditingSeparateFromModuleSelection() throws {
        let cluster = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1RegionEditorCluster.swift"
        )
        let support = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )
        let root = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )

        #expect(!cluster.contains("private var moduleToolbar"))
        #expect(!cluster.contains("onShowModules"))
        #expect(cluster.contains("onFocusTextItem"))
        #expect(cluster.contains("onFocusTrailingText"))
        #expect(cluster.contains("activeModuleRegion"))
        #expect(cluster.contains("ScrollViewReader"))
        #expect(cluster.contains("keyboardWillChangeFrameNotification"))
        #expect(cluster.contains("scrollTo(region, anchor: .center)"))
        #expect(root.contains("focusedEditorRegion"))
        #expect(root.contains("onToggleModuleLibrary"))
        #expect(!root.contains("showModuleLibrary(for: region)"))
        #expect(support.contains("onFocus()"))
        #expect(support.contains("ScrollView(.horizontal, showsIndicators: false)"))
        #expect(support.contains("private var compositionField"))
        #expect(!support.contains("private var adaptiveComposerHeader"))
        #expect(!support.contains("组合结果"))
    }

    @Test("card editor exposes a separate top module action")
    func cardEditorExposesASeparateTopModuleAction() throws {
        let modifier = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1EditorPresentationModifier.swift"
        )
        let root = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )

        #expect(modifier.contains("onToggleModuleLibrary"))
        #expect(modifier.contains("? \"minus\""))
        #expect(modifier.contains(": \"plus\""))
        #expect(modifier.contains("canToggleModuleLibrary"))
        #expect(modifier.contains("isModuleLibraryPresented"))
        #expect(root.contains("dismissKeyboard()"))
        #expect(root.contains("toggleModuleLibraryFromToolbar"))
        #expect(root.contains("showModuleLibrary("))
    }

    @Test("card content editor does not render duplicate right-side row previews")
    func cardContentEditorDoesNotRenderDuplicateRightSideRowPreviews() throws {
        let cluster = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1RegionEditorCluster.swift"
        )
        let support = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )
        let editorStart = try #require(
            support.range(of: "struct V1RegionEditorCard: View")?.lowerBound
        )
        let editorSource = String(support[editorStart..<support.endIndex])

        #expect(cluster.contains("ForEach(CardRegion.memoryCardRegions"))
        #expect(editorSource.contains("Text(region.displayTitle)"))
        #expect(editorSource.contains("VStack(alignment: .leading, spacing: 6)"))
        #expect(!editorSource.contains("HStack(alignment: .center, spacing: 8)"))
        #expect(editorSource.contains(".frame(maxWidth: .infinity)"))
        #expect(editorSource.contains("private var compositionField"))
        #expect(!editorSource.contains("IOSCompactEntryDisclosureRow("))
        #expect(!editorSource.contains("组合结果"))
        #expect(!editorSource.contains("rowValueText"))
        #expect(cluster.contains("四个区域都可以自由组合文字和内容"))
    }

    @Test("card composer keeps module removal in keyboard text-flow semantics")
    func cardComposerUsesKeyboardBackspaceForModuleRemoval() throws {
        let support = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )
        let module = try sourceSection(
            in: support,
            from: "private func moduleChip(",
            to: "private func editableTextField"
        )

        #expect(module.contains("RoundedRectangle"))
        #expect(module.contains(".frame(height: 28)"))
        #expect(support.contains("HStack(spacing: 1)"))
        #expect(!support.contains("当前插入位置"))
        #expect(!support.contains("Color.accentColor.opacity(0.82)"))
        #expect(support.contains("insertionMarkerID"))
        #expect(support.contains("insertionAnchor"))
        #expect(support.contains("showsInsertionMarkerAtEnd"))
        #expect(support.contains("insertionAnchorBelongsBefore"))
        #expect(support.contains("Color.primary.opacity(0.42)"))
        #expect(support.contains("Color(uiColor: .systemBackground)"))
        #expect(!module.contains("onRemoveItem(item)"))
        #expect(!module.contains("xmark.circle.fill"))
        #expect(support.contains("onBackspaceAtBeginning"))
        #expect(support.contains("V1InlineTextField"))
        #expect(module.contains(".systemBlue"))
        #expect(!support.contains("V1ModuleChipRemoveButtonStyle"))
    }


    @Test("card composer keeps empty nodes native and places leading modules at the edge")
    func cardComposerKeepsEmptyNodesNativeAndPlacesLeadingModulesAtTheEdge() throws {
        let support = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )
        let editorSource = try sourceSection(
            in: support,
            from: "struct V1RegionEditorCard: View",
            to: "private struct V1InlineTextField"
        )

        #expect(!editorSource.contains("placeholder: \"短语\""))
        #expect(!editorSource.contains("if draft.items.first?.kind != .text"))
        #expect(editorSource.contains("placeholder: \"\""))
        #expect(!editorSource.contains("Color.accentColor.opacity(0.06)"))
    }

    @Test("card editor surface covers the keyboard gap instead of exposing page controls")
    func cardEditorSurfaceCoversKeyboardGap() throws {
        let modifier = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1EditorPresentationModifier.swift"
        )
        let paddingIndex = try #require(
            modifier.range(of: ".padding(.bottom, bottomInset)")?.lowerBound
        )
        let backgroundIndex = try #require(
            modifier.range(of: ".background(ConfigurationUI.appBackground)")?.lowerBound
        )

        #expect(paddingIndex < backgroundIndex)
        #expect(modifier.contains("card-editor-dismiss-keyboard"))
        #expect(modifier.contains("keyboardBottomInset > 0"))
        #expect(modifier.contains(".overlay(alignment: .bottomTrailing)"))
        #expect(modifier.contains("proxy.frame(in: .global).maxY"))
        #expect(!modifier.contains("UIScreen.main.bounds"))
        #expect(modifier.contains("keyboardBottomInset - 19"))
        #expect(modifier.contains(".frame(width: 38, height: 38)"))
        #expect(!modifier.contains("keyboard seam"))
        #expect(!modifier.contains("Color.primary.opacity(0.10)"))
        #expect(modifier.contains("onDismissKeyboard()"))
    }

    @Test("module candidates stay inline with the card editor instead of a half sheet")
    func moduleCandidatesStayInlineWithTheCardEditor() throws {
        let modifier = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1EditorPresentationModifier.swift"
        )
        let cluster = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1RegionEditorCluster.swift"
        )
        let library = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ModuleLibrarySurface.swift"
        )

        #expect(!modifier.contains(".sheet(isPresented: $isModuleSheetPresented)"))
        #expect(cluster.contains("V1ModuleLibrarySurface("))
        #expect(cluster.contains("activeModuleRegion"))
        #expect(cluster.contains("VStack(spacing: 0)"))
        #expect(cluster.contains(".zIndex(1)"))
        #expect(cluster.contains("insertionMarkerID: insertionMarkerID(region)"))
        #expect(cluster.contains("showsInsertionMarkerAtEnd"))
        #expect(library.contains(".horizontal"))
        #expect(library.contains("ForEach(group.modules)"))
        #expect(library.contains(".caption2"))
        #expect(library.contains(".ultraThinMaterial"))
        #expect(library.contains("static let fixedHeight: CGFloat = 96"))
        #expect(library.contains(".frame(width: 48, alignment: .leading)"))
        #expect(library.contains("LinearGradient"))
        #expect(library.contains("group.modules.count > 4"))
        #expect(library.contains(".frame(width: 34, height: 2)"))
        #expect(!library.contains("关闭模块候选"))
        #expect(!library.contains("NavigationStack"))
        #expect(!library.contains(".searchable"))
        #expect(!library.contains("List {"))
        #expect(!library.contains("插入内容"))
        #expect(!library.contains("选择一项，放入当前光标位置。"))
        #expect(!library.contains("LazyVGrid"))
        #expect(!library.contains("ignoresSafeArea"))
    }

    @Test("card editor owns the bounded viewport while the keyboard is visible")
    func cardEditorKeepsTheSheetStableWhileTheKeyboardIsVisible() throws {
        let modifier = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1EditorPresentationModifier.swift"
        )

        #expect(modifier.contains("V1CardEditorOverlay"))
        #expect(modifier.contains("maximumEditorHeight"))
        #expect(modifier.contains("safeAreaInsets.bottom"))
        #expect(modifier.contains("contentEditorMinimumTopBoundary"))
        #expect(modifier.contains(".overlay"))
        #expect(!modifier.contains(".sheet("))
        #expect(modifier.contains(".safeAreaPadding(.bottom"))
        #expect(modifier.contains("keyboardWillChangeFrameNotification"))
        #expect(modifier.contains(".ignoresSafeArea(.keyboard)"))
        #expect(!modifier.contains("contentSheetKeyboardFraction"))
        #expect(!modifier.contains("keyboardWillShowNotification"))
        #expect(modifier.contains("keyboardWillHideNotification"))
        #expect(!modifier.contains("activeSheetFraction"))
        #expect(!modifier.contains(".presentationDetents"))

        let cluster = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1RegionEditorCluster.swift"
        )
        #expect(cluster.contains(".scrollDismissesKeyboard(.never)"))
        #expect(cluster.contains("ScrollView(.vertical, showsIndicators: false)"))
        #expect(cluster.contains("V1ModuleLibrarySurface.fixedHeight"))
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

    @Test("subject anchors and interface preferences provide vertical accessibility fallbacks")
    func subjectAnchorsAndInterfacePreferencesProvideVerticalFallbacks() throws {
        let subjectAnchors = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewCardSections.swift"
        )
        let settings = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )

        #expect(subjectAnchors.contains("private func anchorTypePill"))
        #expect(subjectAnchors.contains("dynamicTypeSize.isAccessibilitySize"))
        #expect(subjectAnchors.contains("ViewThatFits(in: .horizontal)"))
        #expect(settings.contains("private var adaptiveAppearancePicker"))
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
                "pageSubtitle: \"围绕一个人和一个重要时刻，决定照片如何呈现。\""
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

    @Test("subject editor uses a vertical Contacts hierarchy without a duplicated identity header")
    func subjectEditorUsesVerticalContactsHierarchy() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let editor = try sourceSection(
            in: source,
            from: "private var identityOverviewEditor",
            to: "private var expressionSubjectCard"
        )

        #expect(editor.contains("contactAvatarEditor"))
        #expect(editor.contains("expressionSubjectCard"))
        #expect(editor.contains("compactIdentityFieldsPanel"))
        #expect(editor.contains("frame(maxWidth: .infinity, alignment: .center)"))
        #expect(!source.contains("private var adaptiveIdentityOverviewHeader"))
        #expect(!source.contains("private var identityOverviewText"))
        #expect(!source.contains(".scaleEffect(130.0 / 64.0)"))
    }

    @Test("subject anchor modules use compact semantic-color type labels")
    func subjectAnchorModulesUseCompactSemanticColorTypeLabels() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectAnchorDetailSection.swift"
        )
        let editorSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let module = try sourceSection(
            in: source,
            from: "struct V1IOSSubjectAnchorDetailModule",
            to: "private struct V1IOSSubjectAnchorCompactEditor"
        )
        let editorRow = try sourceSection(
            in: editorSource,
            from: "private struct SubjectTimeAnchorRow",
            to: "private struct PlatformAvatarImage"
        )

        #expect(module.contains("static let ordinaryMinimumHeight: CGFloat = 64"))
        #expect(module.contains("anchorTypeMarker"))
        #expect(module.contains("anchor.resolvedAnchorType.compactDisplayName"))
        #expect(module.contains("anchorTypeTint"))
        #expect(module.contains("dynamicTypeSize.isAccessibilitySize"))
        #expect(module.contains("accessibilityLabel(anchorTypeAccessibilityLabel)"))
        #expect(module.contains("localizedDisplayName("))
        #expect(module.contains("类型，\\(typeName)"))
        #expect(module.contains("Type, \\(typeName)"))
        #expect(!module.contains("anchorTypeSystemImage"))
        #expect(!module.contains("Text(\"类型："))
        #expect(!module.contains("minHeight: 76"))

        #expect(editorRow.contains("SubjectTimeAnchorMetrics.rowHeight"))
        #expect(editorSource.contains("static let rowHeight: CGFloat = 52"))
        #expect(editorRow.contains("anchor.resolvedAnchorType.compactDisplayName"))
        #expect(editorRow.contains("anchorTypeTint"))
        #expect(editorRow.contains("accessibilityLabel(anchorTypeAccessibilityLabel)"))
        #expect(!editorRow.contains("anchorTypeIconName"))
        #expect(!editorRow.contains("Capsule(style: .continuous)"))
    }

    @Test("compact rows share density without shrinking interactive targets")
    func compactRowsShareDensityWithoutShrinkingInteractiveTargets() throws {
        let configurationUI = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Components/InspectorSectionView.swift"
        )
        let editor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let homeRows = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSHomeCardPrimitives.swift"
        )
        let subjectRows = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift"
        )
        let anchorRows = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectAnchorDetailSection.swift"
        )

        #expect(configurationUI.contains("compactRowVerticalPadding: CGFloat = 6"))
        #expect(configurationUI.contains("compactInputRowMinimumHeight: CGFloat = 48"))
        #expect(editor.contains("static let contactFieldRowHeight ="))
        #expect(editor.contains("ConfigurationUI.compactInputRowMinimumHeight"))
        #expect(editor.contains("foregroundStyle(Color.accentColor)"))
        #expect(homeRows.contains("ConfigurationUI.compactRowVerticalPadding"))
        #expect(subjectRows.contains("ConfigurationUI.compactRowVerticalPadding"))
        #expect(anchorRows.contains("minHeight: ConfigurationUI.minimumInteractiveHeight"))
        #expect(editor.contains("width: ConfigurationUI.minimumInteractiveHeight"))
        #expect(editor.contains("height: ConfigurationUI.minimumInteractiveHeight"))
    }

    @Test("home activity card remains a distinct processing status surface")
    func homeActivityCardRemainsDistinctProcessingStatusSurface() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )

        #expect(source.contains("private struct V1IOSHomeActivityCard"))
        #expect(source.contains("V1TitledSectionCard(title: \"当前任务\")"))
        #expect(source.contains("activityProgressBar"))
        #expect(source.contains(".frame(height: 4)"))
        #expect(source.contains("进度 \\(progressPercentText)"))
        #expect(source.contains("V1IOSHomeActivityPresenter.shouldShow(projection)"))
    }

    @Test("Home and Memory Subject flows reuse one statistics strip and one count source")
    func homeAndSubjectFlowsReuseOneStatisticsStrip() throws {
        let support = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift"
        )
        let home = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )
        let overview = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSheetSurface.swift"
        )
        let editor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlow.swift"
        )
        let modifier = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SubjectPresentationModifier.swift"
        )
        let root = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )

        #expect(support.contains("struct V1IOSSubjectStatisticsStrip: View"))
        #expect(support.contains("minHeight: ConfigurationUI.minimumInteractiveHeight"))
        #expect(support.contains("dynamicTypeSize.isAccessibilitySize"))
        #expect(support.contains("accessibilityStatisticsContent"))
        #expect(home.contains("V1IOSSubjectStatisticsStrip("))
        #expect(overview.contains("V1IOSSubjectStatisticsStrip("))
        #expect(!editor.contains("V1IOSSubjectStatisticsStrip("))
        #expect(modifier.contains("availableConfigurationCount"))
        #expect(modifier.contains("completedPhotoCount"))
        #expect(root.contains("availableConfigurationCount: homeAvailablePresets.count"))
        #expect(root.contains("completedPhotoCount:"))

        let statistics = try sourceSection(
            in: support,
            from: "struct V1IOSSubjectStatisticsStrip: View",
            to: "struct V1SubjectAvatarView: View"
        )
        #expect(statistics.contains("maxWidth: .infinity"))
        #expect(statistics.contains("alignment: .center"))
        #expect(statistics.contains("美好的回忆慢慢品味！"))
        #expect(
            statistics.contains(
                "累计完成 \\(max(completedPhotoCount, 0)) 张。美好的回忆慢慢品味！"
            )
        )

        let subjectEditor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        #expect(
            subjectEditor.contains(
                "width: ConfigurationUI.minimumInteractiveHeight"
            )
        )
    }

    @Test("subject editor keeps the expression title stable and bounds deletion")
    func subjectEditorKeepsStableExpressionTitleAndBoundedDeletion() throws {
        let subjectEditor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let flow = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlow.swift"
        )
        let expressionCard = try sourceSection(
            in: subjectEditor,
            from: "private var expressionSubjectCard",
            to: "private var compactIdentityFieldsPanel"
        )

        #expect(expressionCard.contains("expressionSubjectMenu"))
        #expect(expressionCard.contains("Text(\"记忆表达主体\")"))
        #expect(expressionCard.contains("private var expressionSubjectMenu"))

        let deleteButton = try sourceSection(
            in: flow,
            from: "private var deleteSubjectRow",
            to: "private func dismissKeyboard"
        )
        #expect(deleteButton.contains(".buttonStyle(.plain)"))
        #expect(deleteButton.contains("minHeight: ConfigurationUI.minimumInteractiveHeight"))
        #expect(deleteButton.contains("ConfigurationUI.panelBackground"))
        #expect(deleteButton.contains("foregroundStyle(.red)"))
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
        #expect(navigationSource.contains("let navigationStyle: V1EntryNavigationStyle"))
        #expect(navigationSource.contains("TabView(selection: $selection)"))
        #expect(navigationSource.contains("compactSidebarNavigation"))
        #expect(navigationSource.contains("V1EntryCompactSidebar(selection: $selection)"))
        #expect(navigationSource.contains("V1EntrySidebar(selection: $selection)"))
        #expect(navigationSource.contains(".tag(V1EntryTab.home)"))
        #expect(navigationSource.contains(".tag(V1EntryTab.editor)"))
        #expect(navigationSource.contains(".tag(V1EntryTab.output)"))
        #expect(navigationSource.contains(".tag(V1EntryTab.tasks)"))
        #expect(navigationSource.contains("case .settings:"))
        #expect(!navigationSource.contains("@State"))
        #expect(!navigationSource.contains("ConfigurationSession"))
        #expect(rootSource.contains("V1EntryNavigationSurface("))
        #expect(rootSource.contains("@Environment(\\.verticalSizeClass)"))
        #expect(rootSource.contains("navigationStyle: entryNavigationStyle"))
        #expect(rootSource.contains("hasCompactVerticalSizeClass:"))
    }

    @Test("sidebar navigation fills the host viewport")
    func sidebarNavigationFillsHostViewport() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1AdaptiveNavigationShell.swift"
        )
        let sidebarStart = try #require(
            source.range(of: "private func sidebarNavigation")?.lowerBound
        )
        let sidebarEnd = try #require(
            source.range(
                of: "    @ViewBuilder\n    private var sidebarDestination",
                range: sidebarStart..<source.endIndex
            )?.lowerBound
        )
        let sidebarBody = String(source[sidebarStart..<sidebarEnd])

        #expect(sidebarBody.contains("maxWidth: .infinity"))
        #expect(sidebarBody.contains("maxHeight: .infinity"))
        #expect(sidebarBody.contains("alignment: .leading"))
    }

    @Test("card content editor uses one fixed four-region editing surface")
    func cardContentEditorUsesOneFixedFourRegionEditingSurface() throws {
        let cluster = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1RegionEditorCluster.swift"
        )
        let support = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )

        #expect(cluster.contains("ForEach(CardRegion.memoryCardRegions"))
        #expect(cluster.contains("V1RegionEditorCard("))
        #expect(!cluster.contains("expansionBinding"))
        #expect(!cluster.contains("configurationGuide"))

        let editorStart = try #require(
            support.range(of: "struct V1RegionEditorCard: View")
        )
        let editorBody = String(support[editorStart.lowerBound...])

        #expect(editorBody.contains("let region: CardRegion"))
        #expect(editorBody.contains("draft: V1EditorDraft"))
        #expect(!editorBody.contains("IOSCompactEntryDisclosureRow("))
        #expect(!editorBody.contains("组合结果"))
        #expect(!editorBody.contains("模块与文字"))
    }

    @Test("card content editing keeps right-bottom as the photo description carrier")
    func cardContentEditingKeepsRightBottomAsThePhotoDescriptionCarrier() throws {
        let region = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Models/CardRegion.swift"
        )
        let buildService = try sourceText(
            "Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift"
        )

        #expect(region.contains("case .rightSecondary:"))
        #expect(region.contains("return .rightBottom"))
        #expect(buildService.contains("first(where: { $0.area == .rightBottom })"))
        #expect(buildService.contains("func resolvedPhotoDescription("))
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

    func sourceSection(
        in source: String,
        from startMarker: String,
        to endMarker: String
    ) throws -> String {
        let start = try #require(source.range(of: startMarker))
        let end = try #require(
            source.range(
                of: endMarker,
                range: start.upperBound..<source.endIndex
            )
        )
        return String(source[start.lowerBound..<end.lowerBound])
    }
}
