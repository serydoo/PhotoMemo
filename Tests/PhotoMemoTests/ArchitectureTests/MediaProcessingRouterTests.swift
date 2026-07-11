import Foundation
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("Media processing router")
struct MediaProcessingRouterTests {

    @Test("Routes standard still-image inputs to the still-image path")
    func routesStandardStillImageInputs() {
        let decision = MediaProcessingRouter().decision(
            for: MediaProcessingInputDescriptor(
                contentType: .heic,
                pixelWidth: 4032,
                pixelHeight: 3024
            )
        )

        #expect(decision.route == .stillImage)
        #expect(decision.rejectionReason == nil)
    }

    @Test("Routes RAW inputs to the RAW still-image path")
    func routesRawInputs() throws {
        let rawType =
            try #require(
                UTType(filenameExtension: "dng")
            )

        let decision = MediaProcessingRouter().decision(
            for: MediaProcessingInputDescriptor(
                contentType: rawType,
                pixelWidth: 4032,
                pixelHeight: 3024
            )
        )

        #expect(decision.route == .rawStillImage)
        #expect(decision.rejectionReason == nil)
    }

    @Test("Routes broad image declarations with RAW filename to the RAW path")
    func routesBroadImageDeclarationsWithRAWFilename() {
        let decision = MediaProcessingRouter().decision(
            for: MediaProcessingInputDescriptor(
                contentType: .image,
                fileURL:
                    URL(
                        fileURLWithPath:
                            "/tmp/IMG_9001.DNG"
                    ),
                pixelWidth: 8064,
                pixelHeight: 6048
            )
        )

        #expect(decision.route == .rawStillImage)
        #expect(decision.rejectionReason == nil)
    }

    @Test("Routes explicit Live Photo assets to the Live Photo path")
    func routesExplicitLivePhotoAssets() {
        let decision = MediaProcessingRouter().decision(
            for: MediaProcessingInputDescriptor(
                contentType: .heic,
                pixelWidth: 4032,
                pixelHeight: 3024,
                isLivePhotoAsset: true
            )
        )

        #expect(decision.route == .livePhoto)
        #expect(decision.rejectionReason == nil)
    }

    @Test("Routes Live Photo content type to the Live Photo path")
    func routesLivePhotoContentType() throws {
        let livePhotoType =
            try #require(
                UTType("com.apple.live-photo")
            )

        let decision = MediaProcessingRouter().decision(
            for: MediaProcessingInputDescriptor(
                contentType: livePhotoType,
                pixelWidth: 4032,
                pixelHeight: 3024
            )
        )

        #expect(decision.route == .livePhoto)
        #expect(decision.rejectionReason == nil)
    }

    @Test("Rejects unsupported formats through the existing input-policy reason")
    func rejectsUnsupportedFormats() {
        let decision = MediaProcessingRouter().decision(
            for: MediaProcessingInputDescriptor(
                contentType: .gif,
                pixelWidth: 1200,
                pixelHeight: 1200
            )
        )

        #expect(decision.route == .unsupported)
        #expect(decision.rejectionReason == .unsupportedFormat)
    }

    @Test("Rejects oversized still images before they reach processing")
    func rejectsOversizedStillImages() {
        let decision = MediaProcessingRouter().decision(
            for: MediaProcessingInputDescriptor(
                contentType: .jpeg,
                pixelWidth: 9000,
                pixelHeight: 6000
            )
        )

        #expect(decision.route == .unsupported)
        #expect(decision.rejectionReason == .oversizedPixelDimension)
    }
}
