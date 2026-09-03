#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("root runtime composition contracts")
struct RootRuntimeCompositionContractTests {

    @Test("runtime coordinator assembly is separated from root state ownership")
    func runtimeCoordinatorAssemblyIsSeparatedFromRootStateOwnership() throws {
        let rootSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView.swift"
        )
        let compositionSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView+RuntimeComposition.swift"
        )

        #expect(
            compositionSource.contains(
                "var configurationDeletionRuntimeCoordinator"
            )
        )
        #expect(
            compositionSource.contains(
                "var configurationApplyRuntimeCoordinator"
            )
        )
        #expect(
            compositionSource.contains("var draftRuntimeCoordinator")
        )
        #expect(
            !rootSource.contains(
                "var configurationDeletionRuntimeCoordinator"
            )
        )
        #expect(
            !rootSource.contains(
                "var configurationApplyRuntimeCoordinator"
            )
        )
        #expect(!rootSource.contains("var draftRuntimeCoordinator"))
        #expect(rootSource.contains("private var rootLifecycleState"))
        #expect(
            rootSource.contains(
                "private var rootConfigurationProjectionState"
            )
        )
        #expect(rootSource.contains("var rootPresentationState"))
    }

    @Test("Configuration Center has one runtime composition input")
    func configurationCenterRuntimeDependenciesHaveOneCompositionPath() throws {
        let dependencySource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterDependencies.swift"
        )
        let rootSceneSource = try sourceText(
            "Source/MemoMark/MemoMark/App/MemoMarkRootSceneView.swift"
        )
        let previewSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterViewPreview.swift"
        )
        let rootViewSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView.swift"
        )

        #expect(
            dependencySource.contains(
                "struct MemoMarkConfigurationCenterDependencies"
            )
        )
        #expect(dependencySource.contains("init(\n        runtime:"))
        #expect(!dependencySource.contains("@State"))
        #expect(!dependencySource.contains("UserDefaults"))
        #expect(rootSceneSource.contains("dependencies:"))
        #expect(previewSource.contains("dependencies:"))
        #expect(
            rootViewSource.contains(
                "init(\n        dependencies: MemoMarkConfigurationCenterDependencies"
            )
        )
        #expect(!rootViewSource.contains("init(\n        runtimeEnvironment:"))
    }

    private func sourceText(_ relativePath: String) throws -> String {
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
