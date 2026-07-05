#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Media decode layer contract")
struct MediaDecodeLayerContractTests {

    @Test("PhotoImportService delegates preview image decoding to media decode layer")
    func photoImportServiceDelegatesPreviewImageDecodingToMediaDecodeLayer() throws {
        let source =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/Services/PhotoImportService.swift"
            )

        let forbiddenDecodeDetails = [
            "CGImageSourceCreateWithURL(",
            "CGImageSourceCreateWithData(",
            "CGImageSourceCreateThumbnailAtIndex(",
            "CIImage(",
            "PlatformImage.loadPhotoMemoImage(",
            "Data(contentsOf:",
        ]

        let leakedDecodeDetails =
            forbiddenDecodeDetails
            .filter {
                source.contains($0)
            }

        #expect(
            leakedDecodeDetails.isEmpty,
            "PhotoImportService still contains decode details: \(leakedDecodeDetails)"
        )
        #expect(
            source.contains(
                "MediaDecodeService"
            )
        )
    }

    @Test("Share Extension delegates preview image decoding to media decode layer")
    func shareExtensionDelegatesPreviewImageDecodingToMediaDecodeLayer() throws {
        let source =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift"
            )

        let forbiddenDecodeDetails = [
            "CGImageSourceCreateWithURL(",
            "CGImageSourceCreateThumbnailAtIndex(",
        ]

        let leakedDecodeDetails =
            forbiddenDecodeDetails
            .filter {
                source.contains($0)
            }

        #expect(
            leakedDecodeDetails.isEmpty,
            "Share Extension still contains preview decode details: \(leakedDecodeDetails)"
        )
        #expect(
            source.contains(
                "MediaDecodeService"
            )
        )
    }

    @Test("Renderers stay isolated from source media format decisions")
    func renderersStayIsolatedFromSourceMediaFormatDecisions() throws {
        let rendererSources =
            try sourceTexts(
                relativeDirectory:
                    "Source/PhotoMemo/PhotoMemo/Renderers"
            )

        let forbiddenFormatDecisions = [
            "CGImageSource",
            "CIImage(",
            "UTType",
            ".heic",
            ".tiff",
            ".jpeg",
            "\"heic\"",
            "\"tiff\"",
            "\"dng\"",
            "\"raw\"",
            "isRAW",
            "isRaw",
            "DNG",
            "ProRAW",
        ]

        let leakedFormatDecisions =
            rendererSources
            .flatMap { source in
                forbiddenFormatDecisions
                    .filter {
                        source.text.contains($0)
                    }
                    .map {
                        "\(source.relativePath): \($0)"
                    }
            }

        #expect(
            leakedFormatDecisions.isEmpty,
            "Renderer source media format decisions leaked into renderers: \(leakedFormatDecisions)"
        )
    }
}

private extension MediaDecodeLayerContractTests {

    struct SourceText {

        let relativePath: String

        let text: String
    }

    func sourceText(
        relativePath: String
    ) throws -> String {
        try String(
            contentsOf:
                sourceURL(relativePath: relativePath),
            encoding: .utf8
        )
    }

    func sourceURL(
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
            .appendingPathComponent(relativePath)
    }

    func sourceTexts(
        relativeDirectory: String
    ) throws -> [SourceText] {
        let directoryURL =
            sourceURL(
                relativePath:
                    relativeDirectory
            )

        let fileURLs =
            try FileManager.default
            .contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil
            )
            .filter {
                $0.pathExtension == "swift"
            }

        return try fileURLs.map { fileURL in
            let relativePath =
                "\(relativeDirectory)/\(fileURL.lastPathComponent)"

            return SourceText(
                relativePath:
                    relativePath,
                text:
                    try sourceText(
                        relativePath:
                            relativePath
                    )
            )
        }
    }
}
#endif
