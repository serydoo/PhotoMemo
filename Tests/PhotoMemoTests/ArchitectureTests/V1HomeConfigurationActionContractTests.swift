import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 home configuration action contract")
struct V1HomeConfigurationActionContractTests {

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
        #expect(
            normalizedSource.contains(
                "Label( \"保存\", systemImage: MemoMarkSymbol.localStorage.name )"
            )
        )
        #expect(source.contains(".tint(.blue)"))
        #expect(source.contains("Label(\"删除\", systemImage: \"trash\")"))
        #expect(source.contains(".tint(.red)"))
        #expect(
            source.contains(
                "Button(role: .destructive) {\n                        showsDeleteConfirmation = true"
            )
        )
        #expect(!source.contains("DragGesture(minimumDistance: 12)"))
        #expect(!source.contains("V1HomeConfigurationSwipePresenter"))
        #expect(source.contains("accessibilityLabel(\"保存配置到本地库\")"))
        #expect(source.contains("accessibilityLabel(\"删除配置\")"))
        #expect(source.contains("accessibilityLabel(\"更多配置操作\")"))
        #expect(source.contains("Image(systemName: \"ellipsis.circle\")"))
        #expect(source.contains("Label(\"重命名\", systemImage: \"pencil\")"))
        #expect(!source.contains("accessibilityLabel(\"重命名配置\")"))
        #expect(source.contains("删除“\\(preset.title)”配置？"))
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

    @Test("configuration header exposes a dedicated local backup manager")
    func headerOpensLocalBackupManager() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )

        #expect(source.contains("Image(systemName: \"archivebox\")"))
        #expect(source.contains("accessibilityLabel(\"管理本地备份\")"))
        #expect(source.contains("onOpenLocalConfigurationLibrary"))
        #expect(!source.contains("Image(systemName: \"plus\")"))
    }

    @Test("home separates blocking failures from non-modal success feedback")
    func homeSurfacesConfigurationActionFeedback() throws {
        let rootSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )
        let actionSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationLibraryActions.swift"
        )

        #expect(rootSource.contains("homeConfigurationActionFeedback"))
        #expect(rootSource.contains("homeConfigurationStatusBanner"))
        #expect(rootSource.contains("showsHomeConfigurationFailureAlert"))
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
        #expect(source.contains("memoryPresetTitleDraft = title"))
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
