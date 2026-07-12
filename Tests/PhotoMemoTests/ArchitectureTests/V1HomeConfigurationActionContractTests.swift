import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 home configuration action contract")
struct V1HomeConfigurationActionContractTests {

    @Test("configuration rows use native full-swipe delete confirmation")
    func rowSwipeActionsExposeSaveAndDelete() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )

        #expect(source.contains(".swipeActions("))
        #expect(source.contains("allowsFullSwipe: true"))
        #expect(source.contains("Label(\"保存\", systemImage: \"tray.and.arrow.down\")"))
        #expect(source.contains(".tint(.blue)"))
        #expect(source.contains("Label(\"删除\", systemImage: \"trash\")"))
        #expect(source.contains(".tint(.red)"))
        #expect(!source.contains("Button(role: .destructive)"))
        #expect(!source.contains("DragGesture(minimumDistance: 12)"))
        #expect(!source.contains("V1HomeConfigurationSwipePresenter"))
        #expect(source.contains("accessibilityLabel(\"保存配置到本地库\")"))
        #expect(source.contains("accessibilityLabel(\"删除配置\")"))
        #expect(source.contains("删除这个配置？"))
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

    @Test("home surfaces local backup and deletion feedback")
    func homeSurfacesConfigurationActionFeedback() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )

        #expect(source.contains("showsHomeConfigurationActionFeedback"))
        #expect(source.contains(".alert("))
        #expect(source.contains("presentHomeConfigurationActionFeedback"))
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
