#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("Share Extension surface factory")
struct ShareExtensionSurfaceFactoryContractTests {

    @Test("static UIKit card construction stays outside the handoff controller")
    func staticUIKitCardConstructionStaysOutsideTheHandoffController() throws {
        let controllerSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/ShareExtension/MemoMarkShareExtensionViewController.swift"
        )
        let factorySource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/ShareExtension/ShareExtensionSurfaceFactory.swift"
        )

        #expect(factorySource.contains("enum ShareExtensionSurfaceFactory"))
        #expect(factorySource.contains("static func makeCardContainer"))
        #expect(factorySource.contains("static func makeInnerCardContainer"))
        #expect(factorySource.contains("static func makeTitledSectionContainer"))
        #expect(factorySource.contains("static func makeInsetDivider"))
        #expect(!factorySource.contains("NSExtensionItem"))
        #expect(!factorySource.contains("persistIncomingItems"))
        #expect(!factorySource.contains("ShareExtensionIntakeCoordinator"))
        #expect(controllerSource.contains("ShareExtensionSurfaceFactory.makeCardContainer"))
        #expect(controllerSource.contains("ShareExtensionSurfaceFactory.makeInsetDivider"))
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
