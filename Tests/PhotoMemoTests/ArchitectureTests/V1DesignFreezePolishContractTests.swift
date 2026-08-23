import Foundation
import Testing

@Suite("V1 design freeze polish contract")
struct V1DesignFreezePolishContractTests {

    @Test("home and subject presentation use the accepted quiet hierarchy")
    func homeAndSubjectHierarchy() throws {
        let home = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )
        let subject = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift"
        )
        let backups = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1LocalConfigurationLibrarySheet.swift"
        )
        let anchors = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectAnchorDetailSection.swift"
        )

        #expect(home.contains(".frame(width: 70, height: 70)"))
        #expect(home.contains(".font(.title2.weight(.bold))"))
        #expect(home.contains(".opacity(isSelected ? 1 : 0.42)"))
        #expect(!home.contains("上次修改："))
        #expect(subject.contains("subjectAvatar(size: 68)"))
        #expect(subject.contains("subjectAvatar(size: 60)"))
        #expect(subject.contains("MemoMarkDesignTokens.Semantic.memoryStatistics"))
        #expect(backups.contains("最近保存的配置会留在这里"))
        #expect(backups.contains("恢复时会保留当前配置"))
        #expect(anchors.contains(".buttonStyle(.borderedProminent)"))
        #expect(anchors.contains("LazyVGrid(columns: typeColumns"))
        #expect(anchors.contains("V1TimeAnchorTodayPresenter.presentation("))
    }

    @Test("configuration center uses preview and state-aware save treatment")
    func configurationPreviewAndSaveState() throws {
        let options = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let modules = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ModuleLibrarySurface.swift"
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
        #expect(options.contains("saveActionButtonStyle"))
        #expect(options.contains("configurationStatus == .saved"))
        #expect(options.contains(".disabled(isSavingConfiguration || configurationStatus == .saved)"))
        #expect(modules.contains("groupedModules"))
        #expect(modules.contains("ForEach(groupedModules"))
    }

    @Test("save page is organized around an accurate final result")
    func savePageShowsFinalResult() throws {
        let output = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift"
        )

        #expect(output.contains("V1OutputResultSection("))
        #expect(output.contains("V1OutputPhotoDescriptionSection("))
        #expect(output.contains("mediaOutputMode: $mediaOutputMode"))
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
        #expect(output.contains("output.result.title"))
        #expect(
            output.contains(
                "title: presentation.defaultContentTitle"
            )
        )
        #expect(
            output.contains(
                "subtitle: presentation.defaultContentDescription"
            )
        )
        #expect(output.contains("Text(presentation.resolvedTitle)"))
        #expect(output.contains("output.result.photo_format"))
        #expect(output.contains("case .originalFormat:"))
        #expect(output.contains("case .staticImage:"))
        #expect(output.contains("output.memory_write.system_note"))
        #expect(output.contains("V1OutputDashedDivider()"))
        #expect(output.contains(".foregroundStyle(Color.primary.opacity(0.72))"))
        #expect(output.contains("@Environment(\\.accessibilityReduceMotion)"))
        #expect(output.contains("reduceMotion ? .opacity : .opacity.combined("))
        #expect(output.contains("with: .move(edge: .top)"))
        #expect(output.contains(".animation("))
        #expect(output.contains("@FocusState"))
        #expect(output.contains(".focused($isNewAlbumNameFocused)"))
        #expect(output.contains(".foregroundStyle(.secondary)"))
        #expect(output.contains(".disabled(isSaving || configurationStatus == .saved)"))
    }

    @Test("photo-description changes return a saved configuration to the existing dirty save flow")
    func photoDescriptionChangesMarkOutputDirty() throws {
        let root = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )
        let rootObservation = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1RootChangeObservationModifier.swift"
        )

        #expect(
            root.contains(
                "usesCustomMemoryWriteText: $session.usesCustomMemoryWriteText"
            )
        )
        #expect(
            root.contains(
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
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift"
        )
        let welcome = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1WelcomePresentation.swift"
        )

        #expect(task.contains("task.photoLibrary.hint"))
        #expect(task.contains(".saveDestinationText"))
        #expect(task.contains(".foregroundStyle(.secondary)"))
        #expect(task.contains("systemImage: \"clock\""))
        #expect(welcome.contains("对象名称"))
        #expect(welcome.contains("Text(\"*\")"))
        #expect(welcome.contains(".foregroundStyle(.red)"))
        #expect(welcome.contains("showsNameRequiredAlert = true"))
        #expect(welcome.contains("重要日期"))
        #expect(welcome.contains("从一个人和一个重要时刻开始。"))
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
