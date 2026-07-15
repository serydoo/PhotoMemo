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
                "PhotoMemoRenderedImageArtifactGuard.swift",
                "enum PhotoMemoRenderedImageArtifactGuard"
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
                "Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift"
        )

        #expect(source.contains("func export("))
        #expect(source.contains("func exportToTemporaryFile("))
        #expect(source.contains("private let namingResolver: OutputFileNamingResolver"))
        #expect(source.contains("private let pipeline: RecordCardExportPipeline"))
        #expect(!source.contains("enum PhotoMemoRenderedImageArtifactGuard"))
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

        #expect(pipeline.contains("let content = RecordCardRenderer("))
        #expect(pipeline.contains("ClassicWhiteRenderer"))
        #expect(pipeline.contains("PhotoMemoRenderedImageArtifactGuard"))
        #expect(namingResolver.contains("PhotoFileNameResolver"))
        #expect(namingResolver.contains("PHAssetResource.assetResources"))
        #expect(imageWriter.contains("CGImageDestinationCreateWithURL"))
        #expect(imageWriter.contains("ImageIOStillImageMetadataCleanup"))
        #expect(imageWriter.contains("JPEGExifUserCommentPatcher.patchIfNeeded"))
        #expect(commentPatcher.contains("Data(\"UNICODE\\0\".utf8)"))
        #expect(commentPatcher.contains(".utf16BigEndian"))
        #expect(commentPatcher.contains("options: .atomic"))
    }
}

private extension RecordCardExportResponsibilityContractTests {

    func serviceSource(_ fileName: String) throws -> String {
        try sourceText(
            relativePath:
                "Source/PhotoMemo/PhotoMemo/Services/\(fileName)"
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
