import CoreGraphics
import Foundation
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("Live Photo pair composition service")
struct LivePhotoPairCompositionServiceTests {

    @Test("Creates one pairing identity plan and passes it to still and video composition")
    func passesOneGeneratedPairingIdentityToStillAndVideoComposition() async throws {
        let expectedIdentifier =
            "2AB295AF-CFD8-4C47-9579-90249E28F68F"
        let stillComposer =
            StubPairingStillComposer()
        let videoComposer =
            StubPairingVideoComposer()
        let geometryResolver =
            StubLivePhotoGeometryResolver(
                geometry:
                    sampleCanonicalGeometry()
            )
        let service =
            LivePhotoPairCompositionService(
                pairingIdentityPlanner:
                    LivePhotoPairingIdentityPlanner {
                        expectedIdentifier
                    },
                geometryResolver:
                    geometryResolver,
                stillComposer:
                    stillComposer,
                videoComposer:
                    videoComposer
            )
        let overlay =
            try FixedFooterOverlayDescriptor(
                canvasSize: CGSize(width: 40, height: 40),
                photoFrame: CGRect(x: 0, y: 10, width: 40, height: 30),
                footerFrame: CGRect(x: 0, y: 0, width: 40, height: 10),
                footerImage:
                    makeSolidColorImage(
                        size: CGSize(width: 40, height: 10)
                    )
            )
        let outputFolder =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "LivePhotoPairCompositionServiceTests-\(UUID().uuidString)",
                isDirectory: true
            )
        let sourceStillURL =
            outputFolder.appendingPathComponent(
                "source.heic"
            )
        let sourceVideoURL =
            outputFolder.appendingPathComponent(
                "source.mov"
            )
        let outputStillURL =
            outputFolder.appendingPathComponent(
                "output.heic"
            )
        let outputVideoURL =
            outputFolder.appendingPathComponent(
                "output.mov"
            )

        let result =
            try await service.composePair(
                sourceStillURL:
                    sourceStillURL,
                sourceVideoURL:
                    sourceVideoURL,
                overlay:
                    overlay,
                outputStillURL:
                    outputStillURL,
                outputVideoURL:
                    outputVideoURL,
                outputStillType:
                    .heic
            )

        #expect(
            result.pairingIdentityPlan.pairingIdentifier
            == expectedIdentifier
        )
        #expect(
            stillComposer.receivedPairingIdentifiers
            == [
                expectedIdentifier
            ]
        )
        #expect(
            videoComposer.receivedPairingIdentifiers
            == [
                expectedIdentifier
            ]
        )
        #expect(result.stillPhotoURL == outputStillURL)
        #expect(result.pairedVideoURL == outputVideoURL)
    }

    @Test("Resolves CanonicalGeometry once and passes it unchanged to still and video composition")
    func passesOneResolvedCanonicalGeometryToStillAndVideoComposition() async throws {
        let expectedGeometry =
            sampleCanonicalGeometry()
        let geometryResolver =
            StubLivePhotoGeometryResolver(
                geometry:
                    expectedGeometry
            )
        let stillComposer =
            StubPairingStillComposer()
        let videoComposer =
            StubPairingVideoComposer()
        let service =
            LivePhotoPairCompositionService(
                geometryResolver:
                    geometryResolver,
                stillComposer:
                    stillComposer,
                videoComposer:
                    videoComposer
            )
        let overlay =
            try FixedFooterOverlayDescriptor(
                canvasSize: CGSize(width: 40, height: 40),
                photoFrame: CGRect(x: 0, y: 10, width: 40, height: 30),
                footerFrame: CGRect(x: 0, y: 0, width: 40, height: 10),
                footerImage:
                    makeSolidColorImage(
                        size: CGSize(width: 40, height: 10)
                    )
            )
        let outputFolder =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "LivePhotoPairCompositionServiceTests-\(UUID().uuidString)",
                isDirectory: true
            )
        let sourceStillURL =
            outputFolder.appendingPathComponent(
                "source.heic"
            )
        let sourceVideoURL =
            outputFolder.appendingPathComponent(
                "source.mov"
            )

        _ = try await service.composePair(
            sourceStillURL:
                sourceStillURL,
            sourceVideoURL:
                sourceVideoURL,
            overlay:
                overlay,
            outputStillURL:
                outputFolder
                .appendingPathComponent("output.heic"),
            outputVideoURL:
                outputFolder
                .appendingPathComponent("output.mov"),
            outputStillType:
                .heic
        )

        #expect(
            geometryResolver.receivedStillURLs
            == [
                sourceStillURL
            ]
        )
        #expect(
            stillComposer.receivedGeometries
            == [
                expectedGeometry
            ]
        )
        #expect(
            videoComposer.receivedGeometries
            == [
                expectedGeometry
            ]
        )
    }

    @Test("Passes output description only to still-image composition")
    func passesOutputDescriptionOnlyToStillImageComposition() async throws {
        let stillComposer =
            StubPairingStillComposer()
        let videoComposer =
            StubPairingVideoComposer()
        let service =
            LivePhotoPairCompositionService(
                geometryResolver:
                    StubLivePhotoGeometryResolver(
                        geometry:
                            sampleCanonicalGeometry()
                    ),
                stillComposer:
                    stillComposer,
                videoComposer:
                    videoComposer
            )
        let overlay =
            try FixedFooterOverlayDescriptor(
                canvasSize: CGSize(width: 40, height: 40),
                photoFrame: CGRect(x: 0, y: 10, width: 40, height: 30),
                footerFrame: CGRect(x: 0, y: 0, width: 40, height: 10),
                footerImage:
                    makeSolidColorImage(
                        size: CGSize(width: 40, height: 10)
                    )
            )
        let outputFolder =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "LivePhotoPairCompositionServiceTests-\(UUID().uuidString)",
                isDirectory: true
            )
        let expectedDescription =
            "右下智能模块说明"

        _ = try await service.composePair(
            sourceStillURL:
                outputFolder
                .appendingPathComponent("source.heic"),
            sourceVideoURL:
                outputFolder
                .appendingPathComponent("source.mov"),
            overlay:
                overlay,
            outputStillURL:
                outputFolder
                .appendingPathComponent("output.heic"),
            outputVideoURL:
                outputFolder
                .appendingPathComponent("output.mov"),
            outputStillType:
                .heic,
            outputDescription:
                expectedDescription
        )

        #expect(
            stillComposer.receivedOutputDescriptions
            == [
                expectedDescription
            ]
        )
        #expect(
            videoComposer.receivedOutputDescriptions
            .isEmpty
        )
    }
}

private final class StubPairingStillComposer:
    LivePhotoStillImagePairingComposing {

    private(set) var receivedPairingIdentifiers:
        [String] = []
    private(set) var receivedGeometries:
        [CanonicalGeometry] = []
    private(set) var receivedOutputDescriptions:
        [String] = []

    func composeStillImage(
        sourceStillURL: URL,
        geometry: CanonicalGeometry,
        overlay: FixedFooterOverlayDescriptor,
        outputURL: URL,
        outputType: UTType,
        pairingIdentifier: String?,
        outputDescription: String?
    ) throws -> URL {

        receivedGeometries.append(
            geometry
        )

        if let pairingIdentifier {
            receivedPairingIdentifiers.append(
                pairingIdentifier
            )
        }

        if let outputDescription {
            receivedOutputDescriptions.append(
                outputDescription
            )
        }

        return outputURL
    }
}

private final class StubPairingVideoComposer:
    LivePhotoVideoPairingComposing {

    private(set) var receivedPairingIdentifiers:
        [String] = []
    private(set) var receivedGeometries:
        [CanonicalGeometry] = []
    private(set) var receivedOutputDescriptions:
        [String] = []

    func composeVideo(
        sourceVideoURL: URL,
        geometry: CanonicalGeometry,
        overlay: FixedFooterOverlayDescriptor,
        outputURL: URL,
        pairingIdentityPlan:
            LivePhotoPairingIdentityPlan?
    ) async throws -> URL {

        receivedGeometries.append(
            geometry
        )

        if let pairingIdentifier =
            pairingIdentityPlan?.pairingIdentifier {
            receivedPairingIdentifiers.append(
                pairingIdentifier
            )
        }

        return outputURL
    }
}

private final class StubLivePhotoGeometryResolver:
    LivePhotoGeometryResolving {

    private let geometry:
        CanonicalGeometry
    private(set) var receivedStillURLs:
        [URL] = []

    init(
        geometry: CanonicalGeometry
    ) {
        self.geometry =
            geometry
    }

    func resolveGeometry(
        sourceStillURL: URL,
        overlay: FixedFooterOverlayDescriptor,
        outputStillType: UTType
    ) throws -> CanonicalGeometry {
        _ = overlay
        _ = outputStillType

        receivedStillURLs.append(
            sourceStillURL
        )

        return geometry
    }
}

private func sampleCanonicalGeometry() -> CanonicalGeometry {
    CanonicalGeometry(
        facts:
            MediaGeometryFacts(
                rawPixelSize:
                    CGSize(width: 40, height: 30),
                displaySize:
                    CGSize(width: 40, height: 30),
                orientation:
                    .up
            ),
        canvas:
            CanvasGeometry(
                canvasSize:
                    CGSize(width: 40, height: 40),
                photoFrame:
                    CGRect(x: 0, y: 0, width: 40, height: 30),
                footerFrame:
                    CGRect(x: 0, y: 30, width: 40, height: 10)
            )
    )
}

private func makeSolidColorImage(
    size: CGSize
) throws -> CGImage {
    let width = Int(size.width)
    let height = Int(size.height)
    let bytesPerPixel = 4
    let bytesPerRow =
        width * bytesPerPixel
    let data =
        Data(
            repeating: 255,
            count: bytesPerRow * height
        )
    let provider =
        try #require(
            CGDataProvider(
                data: data as CFData
            )
        )

    return try #require(
        CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space:
                CGColorSpaceCreateDeviceRGB(),
            bitmapInfo:
                CGBitmapInfo(
                    rawValue:
                        CGImageAlphaInfo
                        .premultipliedLast
                        .rawValue
                ),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    )
}
