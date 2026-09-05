#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("Apple native product surface contract")
struct AppleNativeProductSurfaceContractTests {

    @Test("App projects the persisted appearance without forcing global light")
    func appProjectsPersistedAppearanceWithoutForcingGlobalLight() throws {
        let root = try sourceText(
            "Source/MemoMark/MemoMark/App/MemoMarkRootSceneView.swift"
        )
        let preference = try sourceText(
            "Source/MemoMark/MemoMark/Models/MemoMarkLanguage.swift"
        )

        #expect(root.contains("MemoMarkAppearancePreference.storageKey"))
        #expect(root.contains(".preferredColorScheme(preferredColorScheme)"))
        #expect(
            root.contains(
                "#if os(iOS)\n        MemoMarkConfigurationCenterView("
            )
        )
        #expect(root.contains("case .system:"))
        #expect(root.contains("case .light:"))
        #expect(root.contains("case .dark:"))
        #expect(!root.contains(".preferredColorScheme(.light)"))
        #expect(!root.contains("overrideUserInterfaceStyle"))
        #expect(preference.contains("enum MemoMarkAppearancePreference"))
        #expect(preference.contains("photomemo.interface.appearance.preference"))
        #expect(preference.contains("case system"))
        #expect(preference.contains("case light"))
        #expect(preference.contains("case dark"))
    }

    @Test("shared runtime headings resolve through the selected interface language")
    func sharedRuntimeHeadingsResolveLocalization() throws {
        let support = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterViewSupportComponents.swift"
        )
        let configurationRowLayout = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionRowLayout.swift"
        )
        let advanced = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/AdvancedModulesSheet.swift"
        )

        let pageHeaderStart = try #require(
            support.range(of: "struct ConfigurationPageHeader: View")
        )
        let pageHeaderEnd = try #require(
            support.range(of: "struct ConfigurationSheetSubtitle: View")
        )
        let pageHeader = support[
            pageHeaderStart.lowerBound..<pageHeaderEnd.lowerBound
        ]

        let sheetSubtitleStart = pageHeaderEnd
        let sheetSubtitleEnd = try #require(
            support.range(of: "struct CompactSelectionLabel: View")
        )
        let sheetSubtitle = support[
            sheetSubtitleStart.lowerBound..<sheetSubtitleEnd.lowerBound
        ]

        let rowHeadingStart = try #require(
            configurationRowLayout.range(of: "private func configurationRowHeading")
        )
        let rowHeadingEnd = try #require(
            configurationRowLayout.range(
                of: "private func configurationRowTrailing",
                range: rowHeadingStart.upperBound..<configurationRowLayout.endIndex
            )
        )
        let rowHeading = configurationRowLayout[
            rowHeadingStart.lowerBound..<rowHeadingEnd.lowerBound
        ]

        #expect(
            pageHeader.contains("Text(localized(title))")
        )
        #expect(
            pageHeader.contains(
                ".lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)"
            )
        )
        #expect(sheetSubtitle.contains("Text(localized(text))"))
        #expect(rowHeading.contains("Text(localized(title))"))
        #expect(rowHeading.contains("Text(localized(subtitle))"))
        #expect(advanced.contains("Text(localized(\"时间显示\"))"))
        #expect(advanced.contains("Text(localized(option.title))"))
        #expect(
            advanced.contains(
                "return localized(\"农历 · 节气\")"
            )
        )
    }

    @Test("photo description supports accessibility text and reduced motion")
    func photoDescriptionSupportsAccessibilityPreferences() throws {
        let output = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/V1OutputPageSurface.swift"
        )
        let reduceMotionEnvironmentCount = output.components(
            separatedBy: "@Environment(\\.accessibilityReduceMotion)"
        ).count - 1

        #expect(reduceMotionEnvironmentCount >= 2)
        #expect(
            output.contains(
                ".lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)"
            )
        )
        #expect(output.contains("reduceMotion ? .opacity"))
        #expect(
            output.contains("reduceMotion")
                && output.contains(": .easeOut(")
                && output.contains("value: usesCustomMemoryWriteText")
        )
    }

    @Test("MemoMark Design System freezes memory-first restrained UI rules")
    func designSystemFreezesMemoryFirstRestrainedUIRules() throws {
        let designSystem = try sourceText("Docs/DesignSystem.md")

        #expect(designSystem.contains("Status: Frozen"))
        #expect(designSystem.contains("Memory First, not Photo First"))
        #expect(designSystem.contains("One screen, one responsibility"))
        #expect(designSystem.contains("One screen, one accent"))
        #expect(designSystem.contains("One card, one responsibility"))
        #expect(designSystem.contains("A page may have only one"))
        #expect(designSystem.contains("The Configuration Center edits Memory Engine Configuration Objects"))
        #expect(designSystem.contains("Renderer remains stateless"))
        #expect(designSystem.contains("Informational phrases"))
        #expect(!designSystem.contains("1. Photo first."))
        #expect(!designSystem.contains("If two cards can become one, merge them."))
    }

    @Test("semantic tokens cover spacing surfaces elevation and controls")
    func semanticTokensCoverTheCompleteUISystem() throws {
        let tokens = try sourceText(
            "Source/MemoMark/MemoMark/App/MemoMarkDesignTokens.swift"
        )
        let configurationUI = try sourceText(
            "Source/MemoMark/MemoMark/ConfigurationCenter/Components/InspectorSectionView.swift"
        )

        #expect(tokens.contains("enum Spacing"))
        #expect(tokens.contains("enum CornerRadius"))
        #expect(tokens.contains("enum Stroke"))
        #expect(tokens.contains("enum SurfaceMaterial"))
        #expect(tokens.contains("enum Elevation"))
        #expect(tokens.contains("enum ControlState"))
        #expect(configurationUI.contains("MemoMarkDesignTokens.Spacing"))
        #expect(configurationUI.contains("MemoMarkDesignTokens.CornerRadius"))
        #expect(configurationUI.contains("MemoMarkDesignTokens.Elevation"))
    }

    @Test("shared cards preserve VoiceOver order and increased contrast")
    func sharedCardsSupportSystemAccessibilityPreferences() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterViewSupportComponents.swift"
        )

        #expect(source.contains("@Environment(\\.colorSchemeContrast)"))
        #expect(source.contains("accessibilityContrast == .increased"))
        #expect(source.contains(".accessibilityElement(children: .contain)"))
        #expect(source.contains(".accessibilityAddTraits(.isHeader)"))
    }

    @Test("configuration and processing apply subtractive visual hierarchy")
    func configurationAndProcessingApplySubtractiveVisualHierarchy() throws {
        let configuration = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let rowLayout = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionRowLayout.swift"
        )
        let processing = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/TaskPageSurface.swift"
        )

        let textFirstRowCount =
            configuration.components(
                separatedBy: "configurationTextRow("
            ).count - 1

        #expect(textFirstRowCount == 5)
        #expect(rowLayout.contains("Text(localized(detail))"))
        #expect(rowLayout.contains(".foregroundStyle(.secondary)"))
        #expect(!processing.contains(".fill(Color.accentColor)"))
        #expect(!processing.contains("Color.accentColor.opacity(0.16)"))
        #expect(processing.contains(".fill(ConfigurationUI.controlBackground.opacity(0.54))"))
        #expect(processing.contains(".stroke(ConfigurationUI.faintHairline)"))
    }

    @Test("processing surface separates result states from live progress")
    func processingSurfaceSeparatesResultStatesFromLiveProgress() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/TaskPageSurface.swift"
        )

        #expect(!source.contains("Circle()\n                    .fill(presentation.currentTask.tint.color)"))
        #expect(source.contains("case .waiting:"))
        #expect(source.contains("case .processing:"))
        #expect(source.contains("case .completed:"))
        #expect(source.contains("case .needsAttention:"))
        #expect(source.contains("task.processing.title"))
        #expect(source.contains("task.completed.title"))
        #expect(source.contains("task.attention.title"))
        #expect(source.contains("task.pipeline.title"))
        #expect(!source.contains("progressPercentText"))
        #expect(!source.contains("showsProgressPercentage"))
        #expect(!source.contains("pipelineStepTime"))
        #expect(!source.contains("private func progressBarTint"))
    }

    @Test("output and region editors use typography before secondary icons")
    func outputAndRegionEditorsUseTypographyBeforeSecondaryIcons() throws {
        let output = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/V1OutputPageSurface.swift"
        )
        let configuration = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let regionEditor = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoryCardRegionEditorCluster.swift"
        )
        let support = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterViewSupportComponents.swift"
        )

        #expect(output.contains("OutputPhotoDescriptionSection("))
        #expect(output.contains("OutputDestinationSection("))
        #expect(output.contains("OutputPhotoDescriptionContent("))
        #expect(output.contains("OutputDestinationContent("))
        #expect(configuration.contains("OutputPhotoDescriptionContent("))
        #expect(configuration.contains("OutputDestinationContent("))
        #expect(!configuration.contains("OutputPhotoDescriptionSection("))
        #expect(!configuration.contains("OutputDestinationSection("))
        #expect(configuration.contains("title: \"configuration.photo_description.title\""))
        #expect(configuration.contains("title: \"configuration.save_location.title\""))
        #expect(!output.contains("V1OutputRetentionRow("))
        #expect(!output.contains("private struct V1OutputContentCard"))
        #expect(!output.contains("private struct V1OutputCompactCard"))
        #expect(!output.contains("title: \"回到哪里\",\n                systemImage:"))
        #expect(!output.contains("private struct V1MemoryWriteExplanation"))
        #expect(!output.contains("let tint: Color\n    let title: String\n    let subtitle: String"))
        #expect(support.contains("struct ConfigurationTitledSectionSurface"))
        #expect(regionEditor.contains("Text(\"这里的内容会怎样使用？\")"))
        #expect(!regionEditor.contains("Label(\"这里的内容会怎样使用？\", systemImage:"))
        #expect(regionEditor.contains("private var editorFooterNote"))
    }

    @Test("processing and output share titled card hierarchy")
    func processingAndOutputShareTitledCardHierarchy() throws {
        let processing = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/TaskPageSurface.swift"
        )
        let recentHistory = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/TaskRecentHistorySurface.swift"
        )
        let output = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/V1OutputPageSurface.swift"
        )
        let support = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterViewSupportComponents.swift"
        )
        let configuration = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )

        #expect(support.contains("struct ConfigurationTitledSectionCard"))
        #expect(support.contains("HStack(alignment: .center, spacing: 8)"))
        #expect(configuration.contains("ConfigurationCompactSectionRow("))
        #expect(configuration.contains("ConfigurationSectionCardMetrics.cardHeaderContentSpacing"))
        #expect(support.contains(".font(.headline.weight(.semibold))"))
        #expect(support.contains(".font(.caption)"))
        #expect(processing.contains("TaskRecentHistorySurface("))
        #expect(recentHistory.contains("task.recent.title"))
        #expect(processing.contains("taskStatusPill("))
        #expect(recentHistory.contains("isSheetPresented = true"))
        #expect(recentHistory.contains("ConfigurationCardHeaderIconButton("))
        #expect(recentHistory.contains("systemImage: \"ellipsis\""))
        #expect(recentHistory.contains(".frame(minHeight: 70)"))
        #expect(recentHistory.contains(".foregroundStyle(Color.accentColor)"))
        #expect(!recentHistory.contains("Text(\"…\")"))
        #expect(!recentHistory.contains("ConfigurationSectionHeading(\n                    \"最近任务\""))
        #expect(!recentHistory.contains("systemImage: MemoMarkSymbol.processing.name,\n                    tint: .blue"))
        #expect(output.contains("private var existingAlbumControlRow"))
        #expect(output.contains(".frame(width: 36, height: 36)"))
        #expect(output.contains(".foregroundStyle(.secondary)"))
        #expect(output.contains("output.destination.refreshing"))
        #expect(output.contains("output.destination.refresh"))
    }

    @Test("home summary cards follow configuration heading hierarchy")
    func homeSummaryCardsFollowConfigurationHeadingHierarchy() throws {
        let home = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/HomePageSurface.swift"
        )
        let presetRow = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/HomeMemoryPresetRow.swift"
        )

        #expect(home.contains("home.presets.title"))
        #expect(home.contains("home.presets.subtitle"))
        #expect(home.contains("home.presets.edit_hint"))
        #expect(
            !home.contains(
                "activeConfigurationStatus =\n                    update.activeConfigurationStatus"
            )
        )
        #expect(!home.contains("private struct HomeConfigurationCard"))
        #expect(!home.contains("systemImage: MemoMarkSymbol.memorySubject.name"))
        #expect(!home.contains("systemImage: MemoMarkSymbol.configuration.name"))
        #expect(home.contains("HStack(spacing: 8)"))
        #expect(home.contains(".frame(width: 48, height: 48)"))
        #expect(presetRow.contains(".frame(width: 26, height: 30)"))
    }

    @Test("actions use accent while reading destinations stay neutral")
    func actionsUseAccentWhileReadingDestinationsStayNeutral() throws {
        let sourcePaths = [
            "Source/MemoMark/MemoMark/iOS/Views/HomeCardPrimitives.swift",
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterSummarySection.swift",
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionRowLayout.swift",
            "Source/MemoMark/MemoMark/iOS/Views/IOSCompactEntryRow.swift",
            "Source/MemoMark/MemoMark/iOS/Views/SubjectOverviewSupport.swift"
        ]

        for sourcePath in sourcePaths {
            let source = try sourceText(sourcePath)
            let chevronSegments = source.components(
                separatedBy: "Image(systemName: \"chevron.right\")"
            ).dropFirst()

            for segment in chevronSegments {
                #expect(
                    segment.prefix(240).contains(
                        ".foregroundStyle(Color.accentColor)"
                    ),
                    "Expected accent chevron in \(sourcePath)"
                )
            }
        }

        let progress = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/TaskPageSurface.swift"
        )
        let applePhotosRow = try #require(
            progress.range(of: "private var photoLibraryLinkRow: some View")
        )
        let applePhotosRowSource = progress[applePhotosRow.lowerBound...]
        #expect(
            applePhotosRowSource.prefix(2_200).contains(
                "Image(systemName: \"chevron.right\")"
            )
        )
        #expect(
            applePhotosRowSource.prefix(2_200).contains(
                ".foregroundStyle(.secondary)"
            )
        )

        let disclosureSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsDisclosureSection.swift"
        )
        let supportRows = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsSupportRowComponents.swift"
        )

        let feedback = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/FeedbackSupportContent.swift"
        )
        #expect(feedback.contains("SettingsLinkRow("))
        #expect(supportRows.contains(".foregroundStyle(Color.accentColor)"))
        #expect(disclosureSource.contains(".foregroundStyle(.tertiary)"))
    }

    @Test("memory subject sections and interface preferences use restrained hierarchy")
    func memorySubjectSectionsAndInterfacePreferencesUseRestrainedHierarchy() throws {
        let overview = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectOverviewSheetSurface.swift"
        )
        let editorFlow = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectConfigurationFlow.swift"
        )
        let editor = try sourceText(
            "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let settings = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsPageSurface.swift"
        )
        let disclosure = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsDisclosureSection.swift"
        )

        #expect(overview.contains("title: \"基础资料\""))
        #expect(overview.contains("title: \"时间锚点\""))
        #expect(overview.contains("ConfigurationTitledSectionSurface("))
        #expect(!overview.contains("ConfigurationTitledSectionCard("))
        #expect(overview.contains("subjectBasicInformation"))
        #expect(overview.contains(".v1CardChrome()"))
        #expect(overview.contains(".frame(maxWidth: .infinity, alignment: .center)"))
        #expect(overview.contains(".padding(.vertical, 7)"))
        #expect(editorFlow.contains("title: \"基础资料\""))
        #expect(editorFlow.contains("title: \"时间锚点\""))
        #expect(editorFlow.contains("private func subjectSectionHeader("))
        #expect(!editorFlow.contains("ConfigurationTitledSectionCard("))
        #expect(editor.contains("contactAvatarEditor"))
        #expect(editor.contains("private var identityOverviewFieldsGroup"))
        #expect(editor.contains("HorizontalDivider(horizontalInset: 12)"))
        #expect(editor.contains(".groupedSurface()"))
        #expect(settings.contains("case interfacePreferences"))
        #expect(settings.contains("section: .interfacePreferences"))
        #expect(settings.contains("trailingValue: InterfacePreferencesContent.summary("))
        #expect(disclosure.contains("private var adaptiveDisclosureHeader"))
        #expect(disclosure.contains("private var verticalDisclosureHeader"))
        #expect(disclosure.contains("if let trailingValue,"))
    }

    @Test("Application surfaces are semantic while fixed output previews stay light")
    func applicationSurfacesAreSemanticAndOutputPreviewsStayLight() throws {
        let welcome = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/WelcomePresentation.swift"
        )
        let subjectOverview = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectOverviewSupport.swift"
        )
        let subjectAnchors = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectOverviewCardSections.swift"
        )
        let subjectEditor = try sourceText(
            "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let cropSheet = try sourceText(
            "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/SubjectAvatarCropSheet.swift"
        )
        let configurationPreview = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterTopPreviewSection.swift"
        )
        let configurationPreviewRenderer = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterIOSSupportViews.swift"
        )
        let accessory = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/AccessoryEntrySection.swift"
        )
        let home = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/HomePageSurface.swift"
        )
        let presetRow = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/HomeMemoryPresetRow.swift"
        )

        #expect(!welcome.contains(".fill(Color.white.opacity(0.94))"))
        #expect(!subjectOverview.contains(".fill(Color.white.opacity(0.92))"))
        #expect(!subjectAnchors.contains(".background(Color.white.opacity(0.94))"))
        #expect(!subjectEditor.contains(".background(Color.white.opacity(0.94))"))
        #expect(!subjectEditor.contains(".fill(Color.white.opacity(0.88))"))
        #expect(!cropSheet.contains(".fill(Color.white)"))

        #expect(configurationPreview.contains("IOSMacStyleMemoryCardPreview("))
        #expect(
            configurationPreviewRenderer.contains(
                "RendererConstants.CompactInformationBar.background"
            )
        )
        #expect(accessory.contains(".environment(\\.colorScheme, .light)"))
        #expect(presetRow.contains(".environment(\\.colorScheme, .light)"))
    }

    @Test("processing surface avoids dashboard and import-first language")
    func processingSurfaceAvoidsDashboardLanguage() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/TaskPageSurface.swift"
        )

        #expect(!source.contains("overviewStrip"))
        #expect(!source.contains("从首页选择照片开始"))
        #expect(source.contains("处理"))
        #expect(source.contains("task.waiting.detail"))
    }

    @Test("output persistence copy names output settings")
    func outputPersistenceNamesOutputSettings() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/V1OutputPageSurface.swift"
        )

        #expect(source.contains("OutputPhotoDescriptionSection("))
        #expect(source.contains("OutputDestinationSection("))
        #expect(source.contains("output.save.saved"))
        #expect(source.contains("output.save.action"))
        #expect(source.contains("configurationStatus == .saved"))
        #expect(!source.contains("output.result.capture_info.title"))
        #expect(!source.contains("保留 EXIF 信息"))
    }

    @Test("background status avoids fixed time estimates")
    func backgroundStatusAvoidsFixedTimeEstimates() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/App/MemoMarkBackgroundStatusService.swift"
        )

        #expect(!source.contains("estimatedSeconds("))
        #expect(!source.contains("约 \\(totalEstimatedSeconds) 秒"))
        #expect(!source.contains("约 \\(minutes) 分钟"))
    }

    @Test("home keeps product objects and removes repeated promotion")
    func homeKeepsObjectsAndRemovesRepeatedPromotion() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/HomePageSurface.swift"
        )

        #expect(!source.contains("developmentBackgroundSection"))
        #expect(!source.contains("HomeFeedbackSection"))
        #expect(source.contains("profileSection"))
        #expect(source.contains("currentPresetSection"))
        #expect(source.contains("选择照片"))
    }

    @Test("primary pages reserve cards for objects instead of section wrappers")
    func primaryPagesReserveCardsForObjects() throws {
        let home = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/HomePageSurface.swift"
        )
        let configuration = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let settings = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsPageSurface.swift"
        )
        let support = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterViewSupportComponents.swift"
        )

        #expect(support.contains("struct ConfigurationTitledSectionSurface"))
        #expect(home.contains("currentPresetSection"))
        #expect(home.contains("profileSection"))
        #expect(configuration.contains(".v1SectionSurfaceLayout()"))
        #expect(!settings.contains("ConfigurationCardContainer(\n            background: sectionBackground"))
        #expect(settings.contains("memoMarkPlusSection"))
    }

    @Test("settings opens getting started first and keeps secondary sections collapsed")
    func settingsStartsGettingStartedAndCollapsesSecondarySections() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsPageSurface.swift"
        )

        #expect(source.contains("private var isGettingStartedExpanded = true"))
        #expect(source.contains("private var isPhotoProcessingExpanded = false"))
        #expect(source.contains("private var isDataSafetyExpanded = false"))
        #expect(source.contains("private var isAboutExpanded = false"))
        #expect(source.contains("MemoMarkSharedContainer.sharedUserDefaults"))
        #expect(source.contains("private var memoMarkPlusSection"))
        #expect(!source.contains("private func settingsTonalIcon"))
        #expect(!source.contains("private func settingsThumbnailStack"))
        #expect(source.contains("DataSafetySupportContent("))
        let supportRows = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsSupportRowComponents.swift"
        )
        #expect(supportRows.contains("struct SettingsPrivacyRow"))
    }

    @Test("interactive surfaces respect reduced motion")
    func interactiveSurfacesRespectReducedMotion() throws {
        let paths = [
            "Source/MemoMark/MemoMark/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift",
            "Source/MemoMark/MemoMark/ConfigurationCenter/MemoryCard/InteractiveMemoryCardConfigurationComponentDock.swift",
            "Source/MemoMark/MemoMark/ConfigurationCenter/MemoryCard/InteractiveMemoryCardCompactPreview.swift",
            "Source/MemoMark/MemoMark/iOS/Views/SettingsDisclosureSection.swift"
        ]

        for path in paths {
            let source = try sourceText(path)
            #expect(source.contains("accessibilityReduceMotion"))
        }
    }

    @Test("configuration center presents objects instead of engineering regions")
    func configurationCenterUsesUserFacingHierarchy() throws {
        let options = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let footer = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationActionFooter.swift"
        )
        let preview = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterTopPreviewSection.swift"
        )

        #expect(footer.contains("configuration.editor.save"))
        #expect(footer.contains("更多配置操作"))
        #expect(options.contains("configuration.card_style.title"))
        #expect(options.contains("configuration.layout.title"))
        #expect(!options.contains("index: \"1.\""))
        #expect(preview.contains("configuration.preview"))
        #expect(!preview.contains("Apple Photos -> Share"))
        #expect(!preview.contains("workflowChips"))
    }

    @Test("primary product rows grow with accessibility text")
    func primaryRowsUseContentDrivenHeight() throws {
        let home = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/HomePageSurface.swift"
        )
        let processing = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/TaskPageSurface.swift"
        )
        let recentHistory = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/TaskRecentHistorySurface.swift"
        )

        #expect(!home.contains("CGFloat(memoryPresets.count) * 92"))
        #expect(processing.contains("TaskRecentHistorySurface("))
        #expect(recentHistory.contains(".frame(minHeight: 70)"))
        #expect(!recentHistory.contains(".frame(height: 70)"))
    }

    @Test("card row separators use one symmetric semantic hairline")
    func cardRowSeparatorsUseSharedSymmetricHairline() throws {
        let support = try sourceText(
            "Source/MemoMark/MemoMark/ConfigurationCenter/Components/InspectorSectionView.swift"
        )
        let configuration = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let output = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/V1OutputPageSurface.swift"
        )

        #expect(support.contains("struct HorizontalDivider"))
        #expect(support.contains("ConfigurationUI.faintHairline"))
        #expect(configuration.contains("HorizontalDivider("))
        #expect(!configuration.contains("private var optionDivider"))
        #expect(!configuration.contains(".padding(\n                .leading,"))
        #expect(output.contains("HorizontalDivider()"))
        #expect(!output.contains("private struct V1OutputDivider"))
    }

    @Test("memory subject detail separates reading from basic information editing")
    func memorySubjectDetailSeparatesReadingFromEditing() throws {
        let detail = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectOverviewSheetSurface.swift"
        )
        let editor = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectConfigurationFlow.swift"
        )

        #expect(detail.contains("subjectIdentitySummary"))
        #expect(detail.contains("subjectBasicInformation"))
        #expect(detail.contains("size: 84"))
        #expect(detail.contains("ToolbarItem(placement: .topBarLeading)"))
        #expect(!detail.contains("ToolbarItem(placement: .topBarTrailing)"))
        #expect(detail.contains("private var editSubjectButton"))
        #expect(detail.contains("ConfigurationCardHeaderIconButton("))
        #expect(detail.contains("systemImage: \"pencil\""))
        #expect(detail.contains("accessibilityLabel: \"编辑记忆对象\""))
        #expect(detail.contains("ConfigurationTitledSectionSurface("))
        #expect(!detail.contains("ConfigurationTitledSectionCard("))
        #expect(!detail.contains("onSaveSubject"))
        #expect(!detail.contains("当前使用"))
        #expect(!detail.contains("mode: .identityOverview"))
        #expect(editor.contains("mode: .identityOverview"))
        #expect(editor.contains("private func subjectSectionHeader("))
        #expect(!editor.contains("ConfigurationTitledSectionCard("))
        #expect(editor.contains("删除记忆对象"))
    }

    @Test("memory subject detail presents anchors as ordered long press modules")
    func memorySubjectDetailPresentsAnchorModules() throws {
        let detail = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectOverviewSheetSurface.swift"
        )
        let anchors = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectAnchorDetailSection.swift"
        )
        let source = detail + anchors

        #expect(source.contains("Array(subject.timeAnchors.enumerated())"))
        #expect(source.contains("id: \\.element.id"))
        #expect(source.contains("SubjectAnchorDetailModule"))
        #expect(source.contains("contextMenu"))
        #expect(source.contains("添加时间锚点"))
        #expect(source.contains("最多保留 5 个时间锚点"))
        #expect(source.contains("至少保留一个时间锚点"))
        #expect(source.contains("accessibilityAction(named: \"配置时间锚点\")"))
        #expect(source.contains("accessibilityAction(named: \"删除时间锚点\")"))
        #expect(!source.contains("时间锚点配置"))
    }

    @Test("single destructive decisions use centered alerts")
    func destructiveDecisionsUseCenteredAlerts() throws {
        let paths = [
            "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/SubjectTimeAnchorRow.swift",
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationActionFooter.swift",
            "Source/MemoMark/MemoMark/iOS/Views/HomePageSurface.swift",
            "Source/MemoMark/MemoMark/iOS/Views/SubjectAnchorDetailSection.swift",
            "Source/MemoMark/MemoMark/iOS/Views/SubjectConfigurationFlow.swift",
            "Source/MemoMark/MemoMark/iOS/Views/LocalConfigurationLibrarySheet.swift"
        ]

        for path in paths {
            let source = try sourceText(path)
            #expect(source.contains(".alert("))
            #expect(!source.contains(".confirmationDialog("))
        }
    }

    @Test("destructive entry points use native red semantics")
    func destructiveEntryPointsUseNativeSemantics() throws {
        let home = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/HomePageSurface.swift"
        )
        let configuration = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationActionFooter.swift"
        )
        let subjectEditor = try sourceText(
            "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/SubjectTimeAnchorRow.swift"
        )
        let anchors = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectAnchorDetailSection.swift"
        )
        let subject = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectConfigurationFlow.swift"
        )
        let backups = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/LocalConfigurationLibrarySheet.swift"
        )

        for source in [home, configuration, subjectEditor, anchors, subject, backups] {
            #expect(source.contains("role: .destructive"))
        }
        #expect(home.contains("systemImage: \"trash\""))
        #expect(subjectEditor.contains(".tint(.red)"))
        #expect(anchors.contains(".tint(.red)"))
        #expect(backups.contains(".tint(.red)"))
        #expect(home.contains(".alert("))
        #expect(configuration.contains(".alert("))
        #expect(subject.contains(".alert("))
        #expect(backups.contains(".alert("))
    }

    @Test("every visible delete entry point declares destructive red semantics")
    func everyVisibleDeleteEntryPointDeclaresDestructiveRedSemantics() throws {
        let home = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/HomePageSurface.swift"
        )
        let subjectEditor = try sourceText(
            "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/SubjectTimeAnchorRow.swift"
        )
        let anchors = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectAnchorDetailSection.swift"
        )
        let backups = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/LocalConfigurationLibrarySheet.swift"
        )
        let customFields = try sourceText(
            "Source/MemoMark/MemoMark/ConfigurationCenter/Inspector/MemoryBlockInspectorCustomFieldsSection.swift"
        )
        let systemModules = try sourceText(
            "Source/MemoMark/MemoMark/ConfigurationCenter/Inspector/MemoryBlockInspectorSystemModulesSection.swift"
        )
        let expression = try sourceText(
            "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/ExpressionEditor.swift"
        )

        #expect(home.contains("role: .destructive"))
        #expect(home.contains("systemImage: \"trash\""))

        for source in [subjectEditor, anchors, backups] {
            #expect(source.contains("role: .destructive"))
            #expect(source.contains(".tint(.red)"))
        }

        #expect(customFields.contains("Button(role: .destructive)"))
        #expect(customFields.contains(".foregroundStyle(.red)"))
        #expect(customFields.contains("Button(role: .destructive) {"))
        #expect(systemModules.contains("Button(role: .destructive)"))
        #expect(systemModules.contains(".tint(.red)"))
        #expect(expression.contains("Button(role: .destructive)"))
        #expect(expression.contains(".foregroundStyle(.red)"))

        for source in [home, subjectEditor, anchors, backups] {
            #expect(source.contains("role: .destructive)"))
        }
    }

    @Test("bottom primary actions use a softened system tint")
    func bottomPrimaryActionsUseASoftenedSystemTint() throws {
        let sharedSupport = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterViewSupportComponents.swift"
        )
        let tokens = try sourceText(
            "Source/MemoMark/MemoMark/App/MemoMarkDesignTokens.swift"
        )
        let shareController = try sourceText(
            "Source/MemoMark/MemoMark/iOS/ShareExtension/MemoMarkShareExtensionViewController.swift"
        )

        #expect(sharedSupport.contains("Color.accentColor.opacity("))
        #expect(
            sharedSupport.contains(
                "compactPrimaryActionTintOpacity"
            )
        )
        #expect(
            sharedSupport.contains(
                "compactPrimaryActionShadowOpacity"
            )
        )
        #expect(
            tokens.contains(
                "compactPrimaryActionTintOpacity: Double = 0.84"
            )
        )
        #expect(
            tokens.contains(
                "compactPrimaryActionShadowOpacity: Double = 0.04"
            )
        )
        #expect(
            tokens.contains(
                "compactPrimaryActionShadowRadius: CGFloat = 6"
            )
        )
        #expect(
            tokens.contains(
                "compactPrimaryActionShadowOffsetY: CGFloat = 2"
            )
        )
        #expect(
            shareController.contains("view.tintColor")
        )
        #expect(shareController.contains("withAlphaComponent"))
        #expect(!shareController.contains(".systemBlue"))
    }

    @Test("time anchor dialog copy names the consequence")
    func timeAnchorDialogCopyNamesTheConsequence() throws {
        let detail = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectAnchorDetailSection.swift"
        )
        let editor = try sourceText(
            "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/SubjectTimeAnchorRow.swift"
        )

        #expect(detail.contains("此操作无法撤销。"))
        #expect(editor.contains("此操作无法撤销。"))
        #expect(detail.contains("至少保留一个时间锚点"))
        #expect(detail.contains("新增另一个时间锚点后，才能删除当前时间锚点。"))
    }

    @Test("time anchor deletion validates the current session state")
    func timeAnchorDeletionUsesCurrentSessionState() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectAnchorDetailSection.swift"
        )

        #expect(source.contains("session.state.selectedSubject?.timeAnchors.count"))
        #expect(
            !source.contains(
                "guard (subject?.timeAnchors.count ?? 0) > 1"
            )
        )
    }

    @Test("memory subject editor separates cancel save and delete outcomes")
    func memorySubjectEditorSeparatesCompletionOutcomes() throws {
        let editor = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectConfigurationFlow.swift"
        )
        let presentation = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectPresentationModifier.swift"
        )

        #expect(editor.contains("onCancel:"))
        #expect(editor.contains("onSave:"))
        #expect(editor.contains(".memoMarkEditorSheetToolbar("))
        #expect(editor.contains("cancelTitle: \"取消\""))
        #expect(editor.contains("onCancel: onCancel"))
        #expect(editor.contains("flowState.saveChanges()"))
        #expect(editor.contains("onSave()"))
        #expect(presentation.contains("nextState.showsSubjectOverview = true"))
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
