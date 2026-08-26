import Foundation
import Testing

@Suite("Record-card export responsibility boundaries")
struct RecordCardExportResponsibilityContractTests {

    @Test("Export responsibilities live in focused source files")
    func exportResponsibilitiesLiveInFocusedSourceFiles() throws {
        let expectedDeclarations = [
            (
                "RecordCardExportPipeline.swift",
                "final class RecordCardExportPipeline"
            ),
            (
                "OutputFileNamingResolver.swift",
                "struct OutputFileNamingResolver"
            ),
            (
                "MetadataPreservingImageWriter.swift",
                "final class MetadataPreservingImageWriter"
            ),
            (
                "JPEGExifUserCommentPatcher.swift",
                "struct JPEGExifUserCommentPatcher"
            ),
            (
                "MemoMarkRenderedImageArtifactGuard.swift",
                "enum MemoMarkRenderedImageArtifactGuard"
            )
        ]

        for (fileName, declaration) in expectedDeclarations {
            let source = try serviceSource(fileName)
            #expect(source.contains(declaration))
        }
    }

    @Test("Record-card export service remains a facade")
    func recordCardExportServiceRemainsAFacade() throws {
        let source = try sourceText(
            relativePath:
                "Source/MemoMark/MemoMark/Services/RecordCardExportService.swift"
        )

        #expect(source.contains("func export("))
        #expect(source.contains("func exportToTemporaryFile("))
        #expect(source.contains("private let namingResolver: OutputFileNamingResolver"))
        #expect(source.contains("private let pipeline: RecordCardExportPipeline"))
        #expect(!source.contains("enum MemoMarkRenderedImageArtifactGuard"))
    }

    @Test("Focused collaborators retain export ownership")
    func focusedCollaboratorsRetainExportOwnership() throws {
        let pipeline =
            try serviceSource(
                "RecordCardExportPipeline.swift"
            )
        let namingResolver =
            try serviceSource(
                "OutputFileNamingResolver.swift"
            )
        let imageWriter =
            try serviceSource(
                "MetadataPreservingImageWriter.swift"
            )
        let commentPatcher =
            try serviceSource(
                "JPEGExifUserCommentPatcher.swift"
            )

        #expect(pipeline.contains("private let presentationPlanner = RecordCardPresentationPlanner()"))
        #expect(pipeline.contains("presentationPlanner.content("))
        #expect(pipeline.contains("presentationPlanner.outputPixelSize("))
        #expect(pipeline.contains("MemoMarkRenderedImageArtifactGuard"))
        #expect(namingResolver.contains("PhotoFileNameResolver"))
        #expect(namingResolver.contains("PHAssetResource.assetResources"))
        #expect(imageWriter.contains("CGImageDestinationCreateWithURL"))
        #expect(imageWriter.contains("ImageIOStillImageMetadataCleanup"))
        #expect(imageWriter.contains("JPEGExifUserCommentPatcher.patchIfNeeded"))
        #expect(commentPatcher.contains("Data(\"UNICODE\\0\".utf8)"))
        #expect(commentPatcher.contains(".utf16BigEndian"))
        #expect(commentPatcher.contains("options: .atomic"))
    }

    @Test("Static export uses one renderer-independent preservation path")
    func staticExportUsesOneRendererIndependentPreservationPath() throws {
        let pipeline = try serviceSource("RecordCardExportPipeline.swift")

        #expect(!pipeline.contains("if card.presentationStyle == .minimal"))
        #expect(!pipeline.contains("RecordCardRenderer"))
        #expect(pipeline.contains("MemoMarkRenderedImageArtifactGuard"))
    }

    @Test("Motion-preserving Live Photo derives one appended output geometry")
    func motionPreservingLivePhotoUsesSharedOutputGeometry() throws {
        let processor = try serviceSource("LivePhotoBatchTaskProcessor.swift")
        let exportPipeline = try serviceSource("RecordCardExportPipeline.swift")

        #expect(processor.contains("renderLivePhotoOverlay"))
        #expect(exportPipeline.contains("sourcePhotoPixelSize"))
        #expect(!exportPipeline.contains("renderMinimalLivePhotoOverlay"))
        #expect(!processor.contains("card.presentationStyle == .minimal"))
    }
}

private extension RecordCardExportResponsibilityContractTests {

    func serviceSource(_ fileName: String) throws -> String {
        try sourceText(
            relativePath:
                "Source/MemoMark/MemoMark/Services/\(fileName)"
        )
    }

    func sourceText(relativePath: String) throws -> String {
        try String(
            contentsOf:
                sourceURL(relativePath: relativePath),
            encoding: .utf8
        )
    }

    func sourceURL(relativePath: String) -> URL {
        let testsDirectory =
            URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
        let repositoryRoot =
            testsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        return repositoryRoot.appendingPathComponent(relativePath)
    }
}
