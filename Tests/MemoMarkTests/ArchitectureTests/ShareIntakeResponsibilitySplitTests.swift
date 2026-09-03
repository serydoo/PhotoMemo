import Foundation
import Testing
import UniformTypeIdentifiers
@testable import MemoMark

@Suite("Share intake responsibility split")
struct ShareIntakeResponsibilitySplitTests {

    @Test("Provider selector prioritizes Live Photo and keeps media truth explicit")
    func providerSelectorPrioritizesLivePhoto() throws {
        let livePhotoType =
            try #require(
                MemoMarkShareProviderTypeSelection
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
            MemoMarkShareProviderTypeSelection
            .preferredImportTypeIdentifier(
                from: registeredTypes
            ) == livePhotoType
        )
        #expect(
            MemoMarkShareProviderTypeSelection
            .preferredImageTypeIdentifier(
                from: registeredTypes
            ) == UTType.jpeg.identifier
        )
        #expect(
            MemoMarkShareProviderTypeSelection
            .supportsLivePhoto(
                registeredTypes
            )
        )
        #expect(
            MemoMarkShareProviderTypeSelection
            .preferredImportTypeIdentifier(
                from: staticTypes
            ) == UTType.jpeg.identifier
        )
        #expect(
            !MemoMarkShareProviderTypeSelection
            .supportsLivePhoto(
                staticTypes
            )
        )
    }

    @Test("Live Photo static payloads remain available as recovery transport for motion-preserving output")
    func livePhotoStaticFallbackRemainsAvailableForIdentityRecovery() {
        #expect(
            LivePhotoStaticFallbackPolicy
                .shouldStopAfterLiveRepresentationFailure(
                    errorCode: 3010,
                    mediaOutputModeRawValue:
                        MediaOutputMode
                        .originalFormat
                        .rawValue
                ) == false
        )
        #expect(
            LivePhotoStaticFallbackPolicy
                .shouldStopAfterLiveRepresentationFailure(
                    errorCode: 3010,
                    mediaOutputModeRawValue: nil
                ) == false
        )
        #expect(
            LivePhotoStaticFallbackPolicy
            .shouldStopAfterLiveRepresentationFailure(
                errorCode: 3010,
                mediaOutputModeRawValue:
                        MediaOutputMode
                    .staticImage
                    .rawValue
            ) == false
        )
        #expect(
            LivePhotoStaticFallbackPolicy
            .shouldStopAfterLiveRepresentationFailure(
                errorCode: 3010,
                mediaOutputModeRawValue: nil,
                livePhotoPolicyRawValue:
                    MemoryConfigurationRecord
                    .Output
                    .LivePhotoPolicy
                    .staticImageOnly
                    .rawValue
            ) == false
        )
        #expect(
            LivePhotoStaticFallbackPolicy
            .shouldStopAfterLiveRepresentationFailure(
                errorCode: 3001,
                mediaOutputModeRawValue:
                    MediaOutputMode
                    .originalFormat
                    .rawValue
            ) == false
        )
    }

    @Test("Share intake freezes the output policy before loading providers and uses recoverable Live Photo static handoff")
    func shareIntakeConnectsOutputPolicyToRecoverableLivePhotoStaticHandoff() throws {
        let source = try [
            "Source/MemoMark/MemoMark/iOS/ShareExtension/MemoMarkShareExtensionIntakeService.swift",
            "Source/MemoMark/MemoMark/iOS/ShareExtension/ShareManagedFileImporter.swift"
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
                "recordStaticLivePhotoPayloadIfNeeded"
            )
        )
        #expect(!source.contains("livePhotoStaticFallbackRejected"))
        #expect(!source.contains("static fallback is not permitted"))
    }

    @Test("Share intake declares four focused collaborators")
    func shareIntakeDeclaresFourFocusedCollaborators() throws {
        let expectations = [
            (
                "Source/MemoMark/MemoMark/iOS/ShareExtension/ShareItemProviderLoader.swift",
                "struct ShareItemProviderLoader"
            ),
            (
                "Source/MemoMark/MemoMark/iOS/ShareExtension/ShareManagedFileImporter.swift",
                "struct ShareManagedFileImporter"
            ),
            (
                "Source/MemoMark/MemoMark/iOS/ShareExtension/ShareLivePhotoRecovery.swift",
                "struct ShareLivePhotoRecovery"
            ),
            (
                "Source/MemoMark/MemoMark/iOS/ShareExtension/ShareIntakeDiagnostics.swift",
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
                "Source/MemoMark/MemoMark/iOS/ShareExtension/MemoMarkShareExtensionIntakeService.swift"
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
                "Source/MemoMark/MemoMark/iOS/ShareExtension/ShareManagedFileImporter.swift"
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

    @Test("Managed importer delegates source materialization while preserving file-first orchestration")
    func managedImporterDelegatesSourceMaterialization() throws {
        let importerSource = try sourceText(
            relativePath:
                "Source/MemoMark/MemoMark/iOS/ShareExtension/ShareManagedFileImporter.swift"
        )
        let materializerSource = try sourceText(
            relativePath:
                "Source/MemoMark/MemoMark/iOS/ShareExtension/ShareManagedImportMaterializer.swift"
        )

        #expect(importerSource.contains("ShareManagedImportMaterializer"))
        #expect(!importerSource.contains("MemoMarkImageFileReadiness"))
        #expect(!importerSource.contains("createManagedCopyDetailed"))
        #expect(
            materializerSource.contains(
                "struct ShareManagedImportMaterializer"
            )
        )
        #expect(materializerSource.contains("createManagedCopyDetailed"))
        #expect(materializerSource.contains("fromData: data"))
        #expect(materializerSource.contains("SHA256.hash"))
        #expect(
            materializerSource.contains(
                "recordSourcePreparationIfNeeded"
            )
        )
        #expect(
            materializerSource.contains(
                "recordSourceUnavailableIfNeeded"
            )
        )
    }

    @Test("Managed importer bounds provider waits and records timeout reasons")
    func managedImporterBoundsProviderWaits() throws {
        let source = try sourceText(
            relativePath:
                "Source/MemoMark/MemoMark/iOS/ShareExtension/ShareManagedFileImporter.swift"
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

    @Test("Provider completion arbitration keeps continuations and timeout tasks out of generic reference types")
    func providerCompletionGateAvoidsGenericReferenceState() throws {
        let source = try sourceText(
            relativePath:
                "Source/MemoMark/MemoMark/iOS/ShareExtension/ShareManagedFileImporter.swift"
        )
        let gateStart = try #require(
            source.range(
                of:
                    "private final class ShareProviderCompletionGate"
            )?.lowerBound
        )
        let importerStart = try #require(
            source.range(
                of: "@MainActor\nstruct ShareManagedFileImporter"
            )?.lowerBound
        )
        let gateSource = source[gateStart..<importerStart]

        #expect(
            source.contains(
                "private final class ShareProviderTimeoutTask"
            )
        )
        #expect(
            !source.contains(
                "ShareProviderContinuationGate<Value>"
            )
        )
        #expect(
            !gateSource.contains(
                "CheckedContinuation"
            )
        )
        #expect(
            !gateSource.contains(
                "Task<Void, Never>?"
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
        MemoMarkTestPaths.repositoryRoot
            .appendingPathComponent(
                relativePath
            )
    }
}
