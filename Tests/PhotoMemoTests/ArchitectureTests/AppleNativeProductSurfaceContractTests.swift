#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing

@Suite("Apple native product surface contract")
struct AppleNativeProductSurfaceContractTests {

    @Test("App projects the persisted appearance without forcing global light")
    func appProjectsPersistedAppearanceWithoutForcingGlobalLight() throws {
        let root = try sourceText(
            "Source/PhotoMemo/PhotoMemo/App/PhotoMemoRootSceneView.swift"
        )
        let preference = try sourceText(
            "Source/PhotoMemo/PhotoMemo/Models/MemoMarkLanguage.swift"
        )

        #expect(root.contains("MemoMarkAppearancePreference.storageKey"))
        #expect(root.contains(".preferredColorScheme(preferredColorScheme)"))
        #expect(
            root.contains(
                "#if os(iOS)\n        PhotoMemoiOSV1View("
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
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )
        let configuration = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let advanced = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1AdvancedModulesSheet.swift"
        )

        let pageHeaderStart = try #require(
            support.range(of: "struct V1PageHeader: View")
        )
        let pageHeaderEnd = try #require(
            support.range(of: "struct V1ConfigurationSheetSubtitle: View")
        )
        let pageHeader = support[
            pageHeaderStart.lowerBound..<pageHeaderEnd.lowerBound
        ]

        let sheetSubtitleStart = pageHeaderEnd
        let sheetSubtitleEnd = try #require(
            support.range(of: "struct V1CompactSelectionLabel: View")
        )
        let sheetSubtitle = support[
            sheetSubtitleStart.lowerBound..<sheetSubtitleEnd.lowerBound
        ]

        let rowHeadingStart = try #require(
            configuration.range(of: "private func configurationRowHeading")
        )
        let rowHeadingEnd = try #require(
            configuration.range(
                of: "private func configurationRowTrailing",
                range: rowHeadingStart.upperBound..<configuration.endIndex
            )
        )
        let rowHeading = configuration[
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
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift"
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
            output.contains(
                "reduceMotion\n                ? nil\n                : .easeOut"
            )
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
            "Source/PhotoMemo/PhotoMemo/App/MemoMarkDesignTokens.swift"
        )
        let configurationUI = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Components/InspectorSectionView.swift"
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
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )

        #expect(source.contains("@Environment(\\.colorSchemeContrast)"))
        #expect(source.contains("accessibilityContrast == .increased"))
        #expect(source.contains(".accessibilityElement(children: .contain)"))
        #expect(source.contains(".accessibilityAddTraits(.isHeader)"))
    }

    @Test("configuration and processing apply subtractive visual hierarchy")
    func configurationAndProcessingApplySubtractiveVisualHierarchy() throws {
        let configuration = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let processing = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift"
        )

        let textFirstRowCount =
            configuration.components(
                separatedBy: "configurationTextRow("
            ).count - 1

        #expect(textFirstRowCount == 5)
        #expect(configuration.contains("Text(localized(detail))"))
        #expect(configuration.contains(".foregroundStyle(.secondary)"))
        #expect(!processing.contains(".fill(Color.accentColor)"))
        #expect(!processing.contains("Color.accentColor.opacity(0.16)"))
        #expect(processing.contains(".fill(ConfigurationUI.controlBackground)"))
        #expect(processing.contains(".stroke(ConfigurationUI.faintHairline)"))
    }

    @Test("processing surface separates result states from live progress")
    func processingSurfaceSeparatesResultStatesFromLiveProgress() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift"
        )

        #expect(!source.contains("Circle()\n                    .fill(presentation.currentTask.tint.color)"))
        #expect(source.contains("case .waiting:"))
        #expect(source.contains("case .processing:"))
        #expect(source.contains("case .completed:"))
        #expect(source.contains("case .needsAttention:"))
        #expect(source.contains("title: \"正在处理\""))
        #expect(source.contains("title: \"刚刚完成\""))
        #expect(source.contains("title: \"需要处理\""))
        #expect(source.contains("DisclosureGroup(\"本次进展\")"))
        #expect(!source.contains("progressPercentText"))
        #expect(!source.contains("showsProgressPercentage"))
        #expect(!source.contains("pipelineStepTime"))
        #expect(!source.contains("private func progressBarTint"))
    }

    @Test("output and region editors use typography before secondary icons")
    func outputAndRegionEditorsUseTypographyBeforeSecondaryIcons() throws {
        let output = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift"
        )
        let regionEditor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1RegionEditorCluster.swift"
        )
        let support = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )

        #expect(output.contains("V1TitledSectionCard(\n            title: \"回到哪里\""))
        #expect(output.contains("V1TitledSectionCard(\n            title: \"新照片\""))
        #expect(output.contains("Picker(\"照片形式\""))
        #expect(output.contains("V1OutputRetentionRow("))
        #expect(!output.contains("private struct V1OutputContentCard"))
        #expect(!output.contains("private struct V1OutputCompactCard"))
        #expect(!output.contains("title: \"回到哪里\",\n                systemImage:"))
        #expect(!output.contains("private struct V1MemoryWriteExplanation"))
        #expect(!output.contains("let tint: Color\n    let title: String\n    let subtitle: String"))
        #expect(support.contains("systemImage: nil"))
        #expect(regionEditor.contains("Text(\"写进卡片的内容\")"))
        #expect(!regionEditor.contains("Label(\"写进卡片的内容\", systemImage: \"info.circle\")"))
        #expect(regionEditor.contains("configurationGuide\n                .padding(.horizontal, 4)"))
    }

    @Test("processing and output share titled card hierarchy")
    func processingAndOutputShareTitledCardHierarchy() throws {
        let processing = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift"
        )
        let output = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift"
        )
        let support = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )
        let configuration = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )

        #expect(support.contains("struct V1TitledSectionCard"))
        #expect(support.contains("HStack(alignment: .center, spacing: 8)"))
        #expect(configuration.contains(".font(.headline.weight(.semibold))"))
        #expect(configuration.contains(".font(.caption)"))
        #expect(support.contains(".font(.headline.weight(.semibold))"))
        #expect(support.contains(".font(.caption)"))
        #expect(processing.contains("title: \"最近保存\""))
        #expect(processing.contains("taskStatusPill("))
        #expect(processing.contains("isRecentTasksSheetPresented = true"))
        #expect(processing.contains("V1CardHeaderIconButton("))
        #expect(processing.contains("systemImage: \"ellipsis\""))
        #expect(processing.contains(".frame(width: 40, height: 40)"))
        #expect(processing.contains("ConfigurationUI.controlBackground"))
        #expect(processing.contains(".foregroundStyle(Color.accentColor)"))
        #expect(!processing.contains("Text(\"…\")"))
        #expect(!processing.contains("V1SectionHeading(\n                    \"最近任务\""))
        #expect(!processing.contains("systemImage: MemoMarkSymbol.processing.name,\n                    tint: .blue"))
        #expect(output.contains("private var existingAlbumControlRow"))
        #expect(output.contains(".frame(width: 36, height: 36)"))
        #expect(output.contains(".foregroundStyle(.secondary)"))
        #expect(output.contains(".accessibilityLabel(\n                isLoadingAlbums\n                ? \"正在刷新相册\"\n                : \"刷新相册\""))
    }

    @Test("home summary cards follow configuration heading hierarchy")
    func homeSummaryCardsFollowConfigurationHeadingHierarchy() throws {
        let home = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )

        #expect(home.contains("title: \"记忆对象\",\n            subtitle: \"回忆正围绕谁展开。\""))
        #expect(home.contains("title: \"我的预设\",\n            subtitle: \"下一次分享，照片会怎样呈现。\""))
        #expect(home.contains("勾选切换当前配置"))
        #expect(
            !home.contains(
                "activeConfigurationStatus =\n                    update.activeConfigurationStatus"
            )
        )
        #expect(!home.contains("private struct V1HomeConfigurationCard"))
        #expect(!home.contains("systemImage: MemoMarkSymbol.memorySubject.name"))
        #expect(!home.contains("systemImage: MemoMarkSymbol.configuration.name"))
        #expect(home.contains("HStack(spacing: 8)"))
        #expect(home.contains(".frame(width: 30, height: 30)"))
        #expect(home.contains(".frame(width: 26, height: 30)"))
    }

    @Test("actions use accent while reading destinations stay neutral")
    func actionsUseAccentWhileReadingDestinationsStayNeutral() throws {
        let sourcePaths = [
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSHomeCardPrimitives.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterSummarySection.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/IOSCompactEntryRow.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift"
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
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift"
        )
        let applePhotosRow = try #require(
            progress.range(of: "Text(\"查看 Apple Photos\")")
        )
        let applePhotosRowSource = progress[applePhotosRow.lowerBound...]
        #expect(
            applePhotosRowSource.prefix(1_400).contains(
                "Image(systemName: \"chevron.right\")"
            )
        )
        #expect(
            applePhotosRowSource.prefix(1_400).contains(
                ".foregroundStyle(.secondary)"
            )
        )

        let settings = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )
        let disclosureStart = try #require(
            settings.range(
                of: "private struct V1SettingsDisclosureSection"
            )?.lowerBound
        )
        let actionSource = settings[..<disclosureStart]
        let disclosureSource = settings[disclosureStart...]

        #expect(actionSource.contains(".foregroundStyle(Color.accentColor)"))
        #expect(disclosureSource.contains(".foregroundStyle(.tertiary)"))
    }

    @Test("memory subject sections and interface preferences use restrained hierarchy")
    func memorySubjectSectionsAndInterfacePreferencesUseRestrainedHierarchy() throws {
        let overview = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSheetSurface.swift"
        )
        let editorFlow = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlow.swift"
        )
        let editor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let settings = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )

        #expect(overview.contains("title: \"基础资料\""))
        #expect(overview.contains("title: \"时间锚点\""))
        #expect(overview.contains("V1TitledSectionSurface("))
        #expect(!overview.contains("V1TitledSectionCard("))
        #expect(overview.contains("subjectBasicInformation"))
        #expect(overview.contains(".v1CardChrome()"))
        #expect(overview.contains(".frame(maxWidth: .infinity, alignment: .center)"))
        #expect(overview.contains(".padding(.vertical, 7)"))
        #expect(editorFlow.contains("title: \"基础资料\""))
        #expect(editorFlow.contains("title: \"时间锚点\""))
        #expect(editorFlow.contains("V1TitledSectionSurface("))
        #expect(!editorFlow.contains("V1TitledSectionCard("))
        #expect(editor.contains("contactAvatarEditor"))
        #expect(editor.contains("expressionSubjectCard\n                .subjectIdentityInnerCardChrome()"))
        #expect(editor.contains("compactIdentityFieldsPanel\n                .subjectIdentityInnerCardChrome()"))
        #expect(editor.contains("func subjectIdentityInnerCardChrome()"))
        #expect(settings.contains("case interfacePreferences"))
        #expect(settings.contains("section: .interfacePreferences"))
        #expect(settings.contains("trailingValue: interfacePreferencesSummary"))
        #expect(settings.contains("private var adaptiveDisclosureHeader"))
        #expect(settings.contains("private var verticalDisclosureHeader"))
        #expect(settings.contains("if let trailingValue,"))
    }

    @Test("Application surfaces are semantic while fixed output previews stay light")
    func applicationSurfacesAreSemanticAndOutputPreviewsStayLight() throws {
        let welcome = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1WelcomePresentation.swift"
        )
        let subjectOverview = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift"
        )
        let subjectAnchors = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewCardSections.swift"
        )
        let subjectEditor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let cropSheet = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/SubjectAvatarCropSheet.swift"
        )
        let configurationPreview = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterTopPreviewSection.swift"
        )
        let accessory = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1AccessoryEntrySection.swift"
        )
        let home = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )

        #expect(!welcome.contains(".fill(Color.white.opacity(0.94))"))
        #expect(!subjectOverview.contains(".fill(Color.white.opacity(0.92))"))
        #expect(!subjectAnchors.contains(".background(Color.white.opacity(0.94))"))
        #expect(!subjectEditor.contains(".background(Color.white.opacity(0.94))"))
        #expect(!subjectEditor.contains(".fill(Color.white.opacity(0.88))"))
        #expect(!cropSheet.contains(".fill(Color.white)"))

        #expect(configurationPreview.contains(".environment(\\.colorScheme, .light)"))
        #expect(accessory.contains(".environment(\\.colorScheme, .light)"))
        #expect(home.contains(".environment(\\.colorScheme, .light)"))
    }

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

        #expect(source.contains("已保存"))
        #expect(source.contains("保存这次选择"))
        #expect(source.contains("保留拍摄信息"))
        #expect(source.contains("configurationStatus == .saved"))
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

    @Test("primary pages reserve cards for objects instead of section wrappers")
    func primaryPagesReserveCardsForObjects() throws {
        let home = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )
        let configuration = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let settings = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )
        let support = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )

        #expect(support.contains("struct V1TitledSectionSurface"))
        #expect(home.contains("V1TitledSectionSurface(\n            title: \"记忆对象\""))
        #expect(home.contains("V1TitledSectionSurface(\n            title: \"我的预设\""))
        #expect(configuration.contains(".v1SectionSurfaceLayout()"))
        #expect(!settings.contains("V1ConfigurationCardContainer(\n            background: sectionBackground"))
        #expect(settings.contains("memoMarkPlusSection"))
    }

    @Test("settings opens getting started first and keeps secondary sections collapsed")
    func settingsStartsGettingStartedAndCollapsesSecondarySections() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )

        #expect(source.contains("private var isGettingStartedExpanded = true"))
        #expect(source.contains("private var isPhotoProcessingExpanded = false"))
        #expect(source.contains("private var isDataSafetyExpanded = false"))
        #expect(source.contains("private var isAboutExpanded = false"))
        #expect(source.contains("PhotoMemoSharedContainer.sharedUserDefaults"))
        #expect(source.contains("private var memoMarkPlusSection"))
        #expect(!source.contains("private func settingsTonalIcon"))
        #expect(!source.contains("private func settingsThumbnailStack"))
        #expect(source.contains("private func settingsPrivacyRow"))
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

        #expect(options.contains("保存当前配置"))
        #expect(options.contains("更多配置操作"))
        #expect(options.contains("编辑卡片呈现"))
        #expect(!options.contains("index: \"1.\""))
        #expect(center.contains("title: \"拍摄信息\""))
        #expect(center.contains("subtitle: \"卡片右上\""))
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

    @Test("card row separators use one symmetric semantic hairline")
    func cardRowSeparatorsUseSharedSymmetricHairline() throws {
        let support = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Components/InspectorSectionView.swift"
        )
        let configuration = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let output = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift"
        )

        #expect(support.contains("struct V1HorizontalDivider"))
        #expect(support.contains("ConfigurationUI.faintHairline"))
        #expect(configuration.contains("V1HorizontalDivider("))
        #expect(!configuration.contains("private var optionDivider"))
        #expect(!configuration.contains(".padding(\n                .leading,"))
        #expect(output.contains("V1HorizontalDivider()"))
        #expect(!output.contains("private struct V1OutputDivider"))
    }

    @Test("memory subject detail separates reading from basic information editing")
    func memorySubjectDetailSeparatesReadingFromEditing() throws {
        let detail = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSheetSurface.swift"
        )
        let editor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlow.swift"
        )

        #expect(detail.contains("subjectIdentitySummary"))
        #expect(detail.contains("subjectBasicInformation"))
        #expect(detail.contains("ToolbarItem(placement: .topBarLeading)"))
        #expect(!detail.contains("ToolbarItem(placement: .topBarTrailing)"))
        #expect(detail.contains("private var editSubjectButton"))
        #expect(detail.contains("V1CardHeaderIconButton("))
        #expect(detail.contains("systemImage: \"pencil\""))
        #expect(detail.contains("accessibilityLabel: \"编辑记忆对象\""))
        #expect(detail.contains("V1TitledSectionSurface("))
        #expect(!detail.contains("V1TitledSectionCard("))
        #expect(!detail.contains("onSaveSubject"))
        #expect(!detail.contains("当前使用"))
        #expect(!detail.contains("mode: .identityOverview"))
        #expect(editor.contains("mode: .identityOverview"))
        #expect(editor.contains("V1TitledSectionSurface("))
        #expect(!editor.contains("V1TitledSectionCard("))
        #expect(editor.contains("删除记忆对象"))
    }

    @Test("memory subject detail presents anchors as ordered long press modules")
    func memorySubjectDetailPresentsAnchorModules() throws {
        let detail = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSheetSurface.swift"
        )
        let anchors = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectAnchorDetailSection.swift"
        )
        let source = detail + anchors

        #expect(source.contains("ForEach(subject.timeAnchors)"))
        #expect(source.contains("V1IOSSubjectAnchorDetailModule"))
        #expect(source.contains("contextMenu"))
        #expect(source.contains("添加锚点"))
        #expect(source.contains("最多保留 5 个时间锚点"))
        #expect(source.contains("至少保留一个时间锚点"))
        #expect(source.contains("accessibilityAction(named: \"配置锚点\")"))
        #expect(source.contains("accessibilityAction(named: \"删除锚点\")"))
        #expect(!source.contains("时间锚点配置"))
    }

    @Test("single destructive decisions use centered alerts")
    func destructiveDecisionsUseCenteredAlerts() throws {
        let paths = [
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectAnchorDetailSection.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlow.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1LocalConfigurationLibrarySheet.swift"
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
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )
        let configuration = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let subjectEditor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let anchors = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectAnchorDetailSection.swift"
        )
        let subject = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlow.swift"
        )
        let backups = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1LocalConfigurationLibrarySheet.swift"
        )

        for source in [home, configuration, subjectEditor, anchors, subject, backups] {
            #expect(source.contains("role: .destructive"))
        }
        #expect(home.contains(".tint(.red)"))
        #expect(subjectEditor.contains(".tint(.red)"))
        #expect(anchors.contains(".tint(.red)"))
        #expect(backups.contains(".tint(.red)"))
        #expect(home.contains("本地配置库中的备份会保留。此操作无法撤销。"))
        #expect(configuration.contains("当前未保存的修改会被默认内容替换。此操作无法撤销。"))
        #expect(subject.contains("对象的基础资料和时间锚点都会被删除。此操作无法撤销。"))
        #expect(backups.contains("当前正在使用的配置不会被删除。此操作无法撤销。"))
    }

    @Test("every visible delete entry point declares destructive red semantics")
    func everyVisibleDeleteEntryPointDeclaresDestructiveRedSemantics() throws {
        let home = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )
        let subjectEditor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let anchors = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectAnchorDetailSection.swift"
        )
        let backups = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1LocalConfigurationLibrarySheet.swift"
        )
        let customFields = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorCustomFieldsSection.swift"
        )
        let systemModules = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorSystemModulesSection.swift"
        )
        let expression = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/ExpressionEditor.swift"
        )

        for source in [home, subjectEditor, anchors, backups] {
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
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )
        let tokens = try sourceText(
            "Source/PhotoMemo/PhotoMemo/App/MemoMarkDesignTokens.swift"
        )
        let shareController = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift"
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
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectAnchorDetailSection.swift"
        )
        let editor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )

        #expect(detail.contains("此操作无法撤销。"))
        #expect(editor.contains("此操作无法撤销。"))
        #expect(detail.contains("至少保留一个时间锚点"))
        #expect(detail.contains("新增另一个锚点后，才能删除当前锚点。"))
    }

    @Test("time anchor deletion validates the current session state")
    func timeAnchorDeletionUsesCurrentSessionState() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectAnchorDetailSection.swift"
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
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlow.swift"
        )
        let presentation = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SubjectPresentationModifier.swift"
        )

        #expect(editor.contains("onCancel:"))
        #expect(editor.contains("onSave:"))
        #expect(editor.contains("Button(\"取消\") {\n                        onCancel()"))
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
