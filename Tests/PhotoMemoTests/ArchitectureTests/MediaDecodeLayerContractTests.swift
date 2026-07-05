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
}

private extension MediaDecodeLayerContractTests {

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
}
#endif
