import Foundation
import Testing

@Suite("iPhone responsive layout contract")
struct IPhoneResponsiveLayoutContractTests {

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
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
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
        #expect(source.contains("ViewThatFits(in: .horizontal)"))
        #expect(source.contains("fixedSize(horizontal: true"))
    }

    @Test("configuration library actions provide a narrow width fallback")
    func configurationLibraryActionsProvideNarrowWidthFallback() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1LocalConfigurationLibrarySheet.swift"
        )

        #expect(source.contains("adaptiveBackupActions"))
        #expect(source.contains("ViewThatFits(in: .horizontal)"))
        #expect(source.contains("compactBackupActions"))
    }

    @Test("configuration controls reflow for accessibility text sizes")
    func configurationControlsReflowForAccessibilityText() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )

        #expect(source.contains("@Environment(\\.dynamicTypeSize)"))
        #expect(source.contains("dynamicTypeSize.isAccessibilitySize"))
        #expect(source.contains("configurationActionColumns"))
        #expect(source.contains("adaptiveSectionHeader"))
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

        #expect(
            source.contains(
                "v1AdaptiveScrollContent(\n                    horizontalPadding: ConfigurationUI.contentColumnPadding"
            )
        )
        #expect(!source.contains("GeometryReader"))
        #expect(source.contains("private var basicInfoInnerPanel"))
        #expect(source.contains("V1ConfigurationCardContainer"))
        #expect(source.contains(".padding(ConfigurationUI.innerPanelPadding)"))
        #expect(source.contains("ConfigurationUI.innerPanelCornerRadius"))
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
