import Foundation
import Testing

@Suite("Media Geometry architecture")
struct MediaGeometryArchitectureTests {

    @Test("Live Photo composers never observe media geometry")
    func livePhotoComposersNeverObserveMediaGeometry() throws {
        let sourceRoot =
            try repositoryRoot()
            .appendingPathComponent(
                "Source/PhotoMemo/PhotoMemo/MediaPipelineVNext",
                isDirectory: true
            )
        let composerFiles = [
            "LivePhotoStillImageCompositionService.swift",
            "LivePhotoVideoCompositionService.swift"
        ]
        let forbiddenTokens = [
            "import ImageIO",
            "import PhotoKit",
            "CGImageSource",
            "CGImageSourceCreateWithURL",
            "CGImageSourceCopyPropertiesAtIndex",
            "CGImageSourceCreateThumbnailAtIndex",
            "CGImageSourceCreateImageAtIndex",
            "PHAsset",
            "AVAssetTrack",
            ".naturalSize",
            ".preferredTransform",
            "preferredTransform:",
            "naturalSize:"
        ]

        for fileName in composerFiles {
            let fileURL =
                sourceRoot
                .appendingPathComponent(
                    fileName
                )
            let source =
                try String(
                    contentsOf: fileURL,
                    encoding: .utf8
                )
            let violations =
                forbiddenTokens
                .filter {
                    source.contains($0)
                }

            #expect(
                violations.isEmpty,
                "\(fileName) observes media geometry: \(violations)"
            )
        }
    }
}

private extension MediaGeometryArchitectureTests {

    func repositoryRoot() throws -> URL {
        URL(
            fileURLWithPath: #filePath
        )
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    }
}
