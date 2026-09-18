#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("macOS configuration runtime contracts")
struct MacConfigurationRuntimeContractTests {

    @Test("macOS root injects the application runtime")
    func macRootInjectsApplicationRuntime() throws {
        let source = try Self.source(
            at: "Source/MemoMark/MemoMark/App/MemoMarkRootSceneView.swift"
        )

        #expect(
            source.contains(
                "ConfigurationCenterView(\n            runtime: runtime"
            )
        )
    }

    @Test("macOS configuration editor uses the application transactions")
    func macEditorUsesApplicationTransactions() throws {
        let source = try Self.source(
            at: "Source/MemoMark/MemoMark/ConfigurationCenter/MacConfigurationCenterPage.swift"
        )

        #expect(source.contains("LoadPhotoLibraryAlbumsTransaction"))
        #expect(source.contains("SaveConfigurationTransaction"))
        #expect(source.contains("ConfigurationSaveRuntimeCoordinator"))
        #expect(source.contains("loadConfigurationBootstrap"))
    }

    @Test("macOS custom logo selection uses the shared optimization flow")
    func macCustomLogoSelectionUsesSharedOptimizationFlow() throws {
        let source = try Self.source(
            at: "Source/MemoMark/MemoMark/ConfigurationCenter/MacConfigurationCenterPage.swift"
        )

        #expect(source.contains("onChange(of: selectedLogoItem)"))
        #expect(source.contains("LogoAssetRuntimeCoordinator"))
        #expect(source.contains("LogoAssetCoordinator().optimize(item)"))
    }

    @Test("macOS configuration center uses explicit workspace routes")
    func macConfigurationCenterUsesExplicitWorkspaceRoutes() throws {
        let source = try Self.source(
            at: "Source/MemoMark/MemoMark/ConfigurationCenter/MacConfigurationCenterPage.swift"
        )

        #expect(source.contains("MacConfigurationWorkspaceRoute"))
        #expect(source.contains("case cardContent"))
        #expect(source.contains("case filmMarkDetails"))
        #expect(source.contains("case timeAndPlace"))
        #expect(source.contains("inspectorRoute"))
        #expect(source.contains("inspectorRoute = .cardContent"))
        #expect(source.contains("inspectorRoute = .filmMarkDetails"))
        #expect(source.contains("inspectorRoute = .timeAndPlace"))
        #expect(source.contains("DispatchQueue.main.async"))
    }

    @Test("macOS summary cards use a deterministic wide layout and full hit targets")
    func macSummaryCardsUseDeterministicWideLayout() throws {
        let header = try Self.source(
            at: "Source/MemoMark/MemoMark/ConfigurationCenter/MacConfigurationCenterHeader.swift"
        )

        #expect(header.contains("subjectPresetWideLayoutBreakpoint"))
        #expect(header.contains("subjectPresetCardMinimumWidth"))
        #expect(header.contains("Button(action: onOpenPreset)"))
        #expect(!header.contains("ViewThatFits(in: .horizontal)"))
    }

    @Test("macOS configuration rows route to an inspector instead of appending editors")
    func macRowsRouteToInspector() throws {
        let source = try Self.source(
            at: "Source/MemoMark/MemoMark/ConfigurationCenter/MacConfigurationCenterPage.swift"
        )

        #expect(source.contains("MacConfigurationInspector"))
        #expect(source.contains("MacRegionDraftEditor"))
        #expect(source.contains("regionDrafts: $regionDraftsByPresentationStyle"))
        #expect(source.contains("mac.configurationCenter.cardContent.editor"))
        #expect(source.contains("TextField("))
        #expect(!source.contains("MacInlineCardContent"))
        #expect(!source.contains("MacInlineAdvancedModules"))
    }

    @Test("macOS card-content modules expose native removal actions")
    func macCardContentModulesCanBeRemoved() throws {
        let source = try Self.source(
            at: "Source/MemoMark/MemoMark/ConfigurationCenter/MacConfigurationCenterPage.swift"
        )

        #expect(source.contains(".contextMenu"))
        #expect(source.contains("移除模块"))
        #expect(source.contains("items.removeAll"))
    }

    @Test("macOS repeated configuration edits use a resizable trailing inspector")
    func macRepeatedConfigurationEditsUseTrailingInspector() throws {
        let source = try Self.source(
            at: "Source/MemoMark/MemoMark/ConfigurationCenter/MacConfigurationCenterPage.swift"
        )

        #expect(source.contains(".inspector(isPresented:"))
        #expect(source.contains(".inspectorColumnWidth("))
        #expect(source.contains("presentation: .inspector"))
    }

    @Test("macOS Inspector is discoverable through the app commands")
    func macInspectorIsDiscoverableThroughAppCommands() throws {
        let source = try Self.source(
            at: "Source/MemoMark/MemoMark/App/MemoMarkApp.swift"
        )

        #expect(source.contains(".commands"))
        #expect(source.contains("InspectorCommands()"))
    }

    @Test("macOS draft editing exposes standard undo and redo commands")
    func macDraftEditingExposesUndoRedoCommands() throws {
        let appSource = try Self.source(
            at: "Source/MemoMark/MemoMark/App/MemoMarkApp.swift"
        )
        let editingSource = try Self.source(
            at: "Source/MemoMark/MemoMark/ConfigurationCenter/MacConfigurationEditingContext.swift"
        )

        #expect(appSource.contains("MacConfigurationUndoCommands()"))
        #expect(appSource.contains(".undoRedo"))
        #expect(editingSource.contains("MacConfigurationUndoCoordinator"))
        #expect(editingSource.contains("MacConfigurationDraftSnapshot"))
    }

    @Test("macOS card editing reveals selected regions and focuses new text")
    func macCardEditingRevealsAndFocuses() throws {
        let source = try Self.source(
            at: "Source/MemoMark/MemoMark/ConfigurationCenter/MacConfigurationCenterPage.swift"
        )

        #expect(source.contains("ScrollViewReader"))
        #expect(source.contains("revealSelectedRegion"))
        #expect(source.contains(".focused($focusedTextItemID"))
        #expect(source.contains("appendTextInput()"))
        #expect(source.contains(".id(region)"))
    }

    private static func source(at relativePath: String) throws -> String {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
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
