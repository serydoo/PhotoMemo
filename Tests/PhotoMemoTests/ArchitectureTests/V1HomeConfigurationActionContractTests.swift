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
        #expect(!source.contains("Button(role: .destructive)"))
        #expect(!source.contains("DragGesture(minimumDistance: 12)"))
        #expect(!source.contains("V1HomeConfigurationSwipePresenter"))
        #expect(source.contains("accessibilityLabel(\"保存配置到本地库\")"))
        #expect(source.contains("accessibilityLabel(\"删除配置\")"))
        #expect(source.contains("accessibilityLabel(\"配置操作\")"))
        #expect(source.contains("Image(systemName: \"ellipsis.circle\")"))
        #expect(source.contains("删除这个配置？"))
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
        let timeAnchorPageStart = try #require(
            subjectSheetSource.range(
                of: "private var timeAnchorConfigurationPage"
            )
        )
        let timeAnchorPageSource = String(
            subjectSheetSource[timeAnchorPageStart.lowerBound...]
        )
        #expect(!timeAnchorPageSource.contains("ScrollView"))
    }

    @Test("configuration card footer opens the current subject local library")
    func footerPlusOpensLocalLibrary() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )

        #expect(source.contains("Image(systemName: \"plus\")"))
        #expect(source.contains("accessibilityLabel(\"打开当前记忆对象的本地配置库\")"))
        #expect(source.contains("onOpenLocalConfigurationLibrary"))
    }

    @Test("home explains the development origin before memory objects")
    func developmentBackgroundAppearsBeforeMemoryObject() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )
        let normalizedSource = source.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )

        #expect(normalizedSource.contains("为什么开发时光记"))
        #expect(normalizedSource.contains("很多很多照片"))
        #expect(normalizedSource.contains("那一天，孩子多大"))
        #expect(normalizedSource.contains("儿子出生"))
        #expect(normalizedSource.contains("纪念日"))
        #expect(normalizedSource.contains("重要日期"))
        #expect(normalizedSource.contains("时间锚点"))
        #expect(normalizedSource.contains("未来的重要日期"))
        #expect(normalizedSource.contains("反馈和建议"))
        #expect(normalizedSource.contains("小红书等公开渠道"))
        #expect(normalizedSource.contains("邀请更多人一起参与"))

        let backgroundIndex = try #require(
            normalizedSource.range(of: "为什么开发时光记")?.lowerBound
        )
        let memoryObjectIndex = try #require(
            normalizedSource.range(
                of: "V1CardSurface(title: \"记忆对象\")"
            )?.lowerBound
        )
        #expect(backgroundIndex < memoryObjectIndex)
    }

    @Test("home development background can be permanently dismissed")
    func developmentBackgroundCanBeDismissed() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )

        #expect(
            source.contains(
                "@AppStorage(\"photomemo.v1.developmentBackgroundDismissed\")"
            )
        )
        #expect(source.contains("if !hasDismissedDevelopmentBackground"))
        #expect(source.contains("hasDismissedDevelopmentBackground = true"))
        #expect(source.contains("Image(systemName: \"xmark\")"))
        #expect(source.contains("ConfigurationUI.controlBackground"))
        #expect(source.contains("ConfigurationUI.faintHairline"))
        #expect(source.contains(".frame(width: 44, height: 44)"))
        #expect(source.contains("accessibilityLabel(\"关闭开发背景说明\")"))
        #expect(source.contains("关闭后仍可在设置中重新查看"))
    }

    @Test("home surfaces local backup and deletion feedback")
    func homeSurfacesConfigurationActionFeedback() throws {
        let rootSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )
        let actionSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationLibraryActions.swift"
        )

        #expect(rootSource.contains("showsHomeConfigurationActionFeedback"))
        #expect(rootSource.contains(".alert("))
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
        #expect(source.contains("case .commitRename(let title):"))
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
