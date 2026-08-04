import Foundation
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("Share intake responsibility split")
struct ShareIntakeResponsibilitySplitTests {

    @Test("Provider selector prioritizes Live Photo and preserves static fallback")
    func providerSelectorPrioritizesLivePhoto() throws {
        let livePhotoType =
            try #require(
                PhotoMemoShareProviderTypeSelection
                .livePhotoTypeIdentifiers
                .first
            )
        let registeredTypes = [
            UTType.jpeg.identifier,
            livePhotoType,
            UTType.png.identifier
        ]
        let staticTypes = [
            UTType.plainText.identifier,
            UTType.jpeg.identifier
        ]

        #expect(
            PhotoMemoShareProviderTypeSelection
            .preferredImportTypeIdentifier(
                from: registeredTypes
            ) == livePhotoType
        )
        #expect(
            PhotoMemoShareProviderTypeSelection
            .preferredImageTypeIdentifier(
                from: registeredTypes
            ) == UTType.jpeg.identifier
        )
        #expect(
            PhotoMemoShareProviderTypeSelection
            .supportsLivePhoto(
                registeredTypes
            )
        )
        #expect(
            PhotoMemoShareProviderTypeSelection
            .preferredImportTypeIdentifier(
                from: staticTypes
            ) == UTType.jpeg.identifier
        )
        #expect(
            !PhotoMemoShareProviderTypeSelection
            .supportsLivePhoto(
                staticTypes
            )
        )
    }

    @Test("Original-format Live Photo intake stops after a provider timeout instead of silently becoming static")
    func originalFormatStopsAfterLivePhotoProviderTimeout() {
        #expect(
            LivePhotoStaticFallbackPolicy
                .shouldStopAfterLiveRepresentationFailure(
                    errorCode: 3010,
                    mediaOutputModeRawValue:
                        V1MediaOutputMode
                        .originalFormat
                        .rawValue
                )
        )
        #expect(
            LivePhotoStaticFallbackPolicy
                .shouldStopAfterLiveRepresentationFailure(
                    errorCode: 3010,
                    mediaOutputModeRawValue: nil
                )
        )
        #expect(
            !LivePhotoStaticFallbackPolicy
            .shouldStopAfterLiveRepresentationFailure(
                errorCode: 3010,
                mediaOutputModeRawValue:
                    V1MediaOutputMode
                    .staticImage
                    .rawValue
            )
        )
        #expect(
            !LivePhotoStaticFallbackPolicy
            .shouldStopAfterLiveRepresentationFailure(
                errorCode: 3010,
                mediaOutputModeRawValue: nil,
                livePhotoPolicyRawValue:
                    MemoryConfigurationRecord
                    .Output
                    .LivePhotoPolicy
                    .staticImageOnly
                    .rawValue
            )
        )
        #expect(
            !LivePhotoStaticFallbackPolicy
            .shouldStopAfterLiveRepresentationFailure(
                errorCode: 3001,
                mediaOutputModeRawValue:
                    V1MediaOutputMode
                    .originalFormat
                    .rawValue
            )
        )
    }

    @Test("Share intake freezes the output policy before loading providers and stops original-format timeout fallback")
    func shareIntakeConnectsOutputPolicyToProviderTimeoutHandling() throws {
        let source = try [
            "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareManagedFileImporter.swift"
        ]
        .map {
            try sourceText(
                relativePath: $0
            )
        }
        .joined(separator: "\n")

        #expect(
            source.contains(
                "let configurationSnapshot ="
            )
        )
        #expect(
            source.contains(
                "mediaOutputModeRawValue:"
            )
        )
        #expect(
            source.contains(
                "livePhotoPolicyRawValue:"
            )
        )
        #expect(
            source.contains(
                "shouldStopAfterLiveRepresentationFailure("
            )
        )
        #expect(
            source.contains(
                "return .failed(\n                    failureContext"
            )
        )
    }

    @Test("Share intake declares four focused collaborators")
    func shareIntakeDeclaresFourFocusedCollaborators() throws {
        let expectations = [
            (
                "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareItemProviderLoader.swift",
                "struct ShareItemProviderLoader"
            ),
            (
                "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareManagedFileImporter.swift",
                "struct ShareManagedFileImporter"
            ),
            (
                "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareLivePhotoRecovery.swift",
                "struct ShareLivePhotoRecovery"
            ),
            (
                "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareIntakeDiagnostics.swift",
                "struct ShareIntakeDiagnostics"
            )
        ]

        for (relativePath, declaration) in expectations {
            let url = sourceURL(relativePath: relativePath)
            try #require(
                FileManager.default.fileExists(
                    atPath: url.path
                )
            )
            let source = try String(
                contentsOf: url,
                encoding: .utf8
            )
            #expect(source.contains(declaration))
        }
    }

    @Test("Share intake facade delegates extracted responsibilities")
    func shareIntakeFacadeDelegatesExtractedResponsibilities() throws {
        let source = try sourceText(
            relativePath:
                "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift"
        )

        #expect(source.contains("ShareItemProviderLoader"))
        #expect(source.contains("ShareManagedFileImporter"))
        #expect(source.contains("ShareLivePhotoRecovery"))
        #expect(source.contains("ShareIntakeDiagnostics"))
        #expect(!source.contains("func loadFileRepresentationResult("))
        #expect(!source.contains("func loadFallbackItem("))
        #expect(!source.contains("func livePhotoBundleReadiness("))
        #expect(!source.contains("func recordProviderDiagnostics("))
    }

    @Test("Managed importer preserves file-first fallback order")
    func managedImporterPreservesFileFirstFallbackOrder() throws {
        let source = try sourceText(
            relativePath:
                "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareManagedFileImporter.swift"
        )

        let fileRepresentationIndex = try #require(
            source.range(
                of: "loadFileRepresentationResult"
            )?.lowerBound
        )
        let itemFallbackIndex = try #require(
            source.range(
                of: "loadFallbackItem"
            )?.lowerBound
        )

        #expect(
            fileRepresentationIndex
            < itemFallbackIndex
        )
    }

    @Test("Managed importer bounds provider waits and records timeout reasons")
    func managedImporterBoundsProviderWaits() throws {
        let source = try sourceText(
            relativePath:
                "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareManagedFileImporter.swift"
        )

        #expect(
            source.contains(
                "providerLoadTimeoutNanoseconds"
            )
        )
        #expect(
            source.contains(
                "15_000_000_000"
            )
        )
        #expect(
            source.contains(
                "loadFileRepresentation.timeout"
            )
        )
        #expect(
            source.contains(
                "loadItem.timeout"
            )
        )
        #expect(
            source.contains(
                "progress.cancel()"
            )
        )
        #expect(
            source.contains(
                "extensionProviderLoadTimedOut"
            )
        )
    }

    private func sourceText(
        relativePath: String
    ) throws -> String {
        try String(
            contentsOf:
                sourceURL(
                    relativePath: relativePath
                ),
            encoding: .utf8
        )
    }

    private func sourceURL(
        relativePath: String
    ) -> URL {
        let testsDirectory =
            URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
        let repositoryRoot =
            testsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        return repositoryRoot
            .appendingPathComponent(
                relativePath
            )
    }
}
