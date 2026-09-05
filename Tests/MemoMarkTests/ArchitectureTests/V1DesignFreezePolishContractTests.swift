import Foundation
import Testing

@Suite("V1 design freeze polish contract")
struct V1DesignFreezePolishContractTests {

    @Test("home and subject presentation use the accepted quiet hierarchy")
    func homeAndSubjectHierarchy() throws {
        let home = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/HomePageSurface.swift"
        )
        let presetRow = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/HomeMemoryPresetRow.swift"
        )
        let subject = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectOverviewSupport.swift"
        )
        let backups = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/LocalConfigurationLibrarySheet.swift"
        )
        let anchors = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectAnchorDetailSection.swift"
        )

        #expect(home.contains(".frame(width: 70, height: 70)"))
        #expect(home.contains(".font(.title2.weight(.bold))"))
        #expect(presetRow.contains("isSelected ? \"checkmark.circle.fill\" : \"circle\""))
        #expect(presetRow.contains("isSelected ? Color.accentColor"))
        #expect(!home.contains("上次修改："))
        #expect(subject.contains("subjectAvatar(size: 68)"))
        #expect(subject.contains("subjectAvatar(size: 60)"))
        #expect(subject.contains("MemoMarkDesignTokens.Semantic.memoryStatistics"))
        #expect(backups.contains("最近保存的配置会留在这里"))
        #expect(backups.contains("恢复时会保留当前配置"))
        #expect(anchors.contains(".memoMarkEditorSheetToolbar("))
        #expect(anchors.contains("LazyVGrid(columns: typeColumns"))
        #expect(anchors.contains("TimeAnchorTodayPresenter.presentation("))
    }

    @Test("configuration center uses preview and state-aware save treatment")
    func configurationPreviewAndSaveState() throws {
        let options = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let footer = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationActionFooter.swift"
        )
        let modules = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ModuleLibrarySurface.swift"
        )

        #expect(options.contains("memoryExpressionPreview"))
        #expect(options.contains("memoryExpressionPreviewLines"))
        #expect(options.contains(".split(separator: \"｜\""))
        #expect(
            options.contains(
                "ConfigurationUI.compactTrailingControlWidth"
            )
        )
        #expect(!options.contains("horizontalTrailingWidth: 112"))
        #expect(!options.contains("V1MemoryExpressionPreviewSheet"))
        #expect(!options.contains("showsMemoryDisplayDetail"))
        #expect(footer.contains("saveActionButtonStyle"))
        #expect(footer.contains("configurationStatus == .saved"))
        #expect(footer.contains(".disabled(isSavingConfiguration || configurationStatus == .saved)"))
        #expect(modules.contains("groupedModules"))
        #expect(modules.contains("ForEach(groupedModules"))
    }

    @Test("save options are owned by configuration center")
    func savePageShowsFinalResult() throws {
        let output = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/V1OutputPageSurface.swift"
        )
        let options = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let navigation = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/AdaptiveNavigationShell.swift"
        )

        #expect(output.contains("OutputPhotoDescriptionSection("))
        #expect(output.contains("OutputDestinationSection("))
        #expect(!output.contains("V1OutputResultSection"))
        #expect(!output.contains("V1OutputDashedDivider"))
        #expect(!output.contains("V1OutputRetentionRow"))
        #expect(options.contains("OutputPhotoDescriptionContent("))
        #expect(options.contains("OutputDestinationContent("))
        #expect(!options.contains("OutputPhotoDescriptionSection("))
        #expect(!options.contains("OutputDestinationSection("))
        #expect(options.contains("title: \"configuration.photo_description.title\""))
        #expect(options.contains("title: \"configuration.save_location.title\""))
        #expect(!navigation.contains(".tag(EntryTab.output)"))
        #expect(
            output.contains(
                "usesCustomMemoryWriteText: $usesCustomMemoryWriteText"
            )
        )
        #expect(
            output.contains(
                "customMemoryWriteText: $customMemoryWriteText"
            )
        )
        #expect(
            output.contains(
                "resolvedMemoryWriteText: resolvedMemoryWriteText"
            )
        )
        #expect(output.contains("@FocusState"))
        #expect(output.contains(".focused($isNewAlbumNameFocused)"))
        #expect(output.contains(".foregroundStyle(.secondary)"))
        #expect(output.contains(".disabled(isSaving || configurationStatus == .saved)"))
    }

    @Test("photo-description changes return a saved configuration to the existing dirty save flow")
    func photoDescriptionChangesMarkOutputDirty() throws {
        let root = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView.swift"
        )
        let pages = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView+Pages.swift"
        )
        let rootObservation = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/RootChangeObservationModifier.swift"
        )

        #expect(
            pages.contains(
                "usesCustomMemoryWriteText: $session.usesCustomMemoryWriteText"
            )
        )
        #expect(
            pages.contains(
                "customMemoryWriteText: $session.customMemoryWriteText"
            )
        )
        #expect(
            rootObservation.contains(
                """
                .onChange(of: session.usesCustomMemoryWriteText) { _, _ in
                                markOutputDirtyIfNeeded()
                            }
                """
            )
        )
        #expect(
            rootObservation.contains(
                """
                .onChange(of: session.customMemoryWriteText) { _, _ in
                                markOutputDirtyIfNeeded()
                            }
                """
            )
        )
    }

    @Test("progress and first run close with restrained factual feedback")
    func progressAndFirstRunFeedback() throws {
        let task = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/TaskPageSurface.swift"
        )
        let welcome = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/WelcomePresentation.swift"
        )

        #expect(task.contains("task.photoLibrary.hint"))
        #expect(task.contains(".saveDestinationText"))
        #expect(task.contains(".foregroundStyle(.secondary)"))
        #expect(task.contains("systemImage: \"clock\""))
        #expect(welcome.contains("对象名称"))
        #expect(welcome.contains("Text(\"*\")"))
        #expect(welcome.contains(".foregroundStyle(.red)"))
        #expect(welcome.contains("showsNameRequiredAlert = true"))
        #expect(welcome.contains("时间锚点"))
        #expect(welcome.contains("从一个人和一个时间锚点开始。"))
        #expect(welcome.contains("isFirstRunConfigurationReady"))
        #expect(welcome.contains("isSaving"))
    }
}

private extension V1DesignFreezePolishContractTests {

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
