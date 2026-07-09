import Foundation
import AVFoundation
import CoreGraphics
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("Live Photo asset readback verification")
struct LivePhotoAssetReadbackVerificationTests {

    @Test("Reports generated Live Photo file identity and metadata readiness")
    func reportsGeneratedLivePhotoFileIdentityAndMetadataReadiness() {
        let report =
            LivePhotoFileReadbackReport(
                stillPhotoURL:
                    URL(fileURLWithPath: "/tmp/output.heic"),
                pairedVideoURL:
                    URL(fileURLWithPath: "/tmp/output.mov"),
                stillPixelWidth: 4032,
                stillPixelHeight: 3704,
                pairedVideoPixelWidth: 4032,
                pairedVideoPixelHeight: 3704,
                pairedVideoDuration: 2.7,
                stillContentIdentifier:
                    "2AB295AF-CFD8-4C47-9579-90249E28F68F",
                pairedVideoContentIdentifier:
                    "2AB295AF-CFD8-4C47-9579-90249E28F68F",
                stillCaptureDateOriginal:
                    "2026:06:25 12:34:56",
                stillGPSLatitude: 34.414,
                stillGPSLongitude: 115.656,
                quickTimeCreationDate:
                    "2026-06-25T10:11:12+0800"
            )

        #expect(
            report.isPairingIdentifierMatched
        )
        #expect(
            report.hasMatchingStillAndVideoDimensions
        )
        #expect(
            report.hasCaptureDate
        )
        #expect(
            report.hasGPSLocation
        )
        #expect(
            report.hasQuickTimeCreationDate
        )
        #expect(
            report.satisfiesGeneratedLivePhotoFileContract
        )
    }

    @Test("Builds a file readback report from generated HEIC and MOV files")
    func buildsFileReadbackReportFromGeneratedFiles() async throws {
        let temporaryFolder =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "LivePhotoAssetReadbackVerificationTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: temporaryFolder,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(
                at: temporaryFolder
            )
        }

        let stillURL =
            temporaryFolder.appendingPathComponent(
                "pair.heic"
            )
        let videoURL =
            temporaryFolder.appendingPathComponent(
                "pair.mov"
            )
        let pairingIdentifier =
            "2AB295AF-CFD8-4C47-9579-90249E28F68F"

        try writeStillImage(
            at: stillURL,
            pairingIdentifier:
                pairingIdentifier
        )
        try await writeVideo(
            at: videoURL,
            contentIdentifier:
                pairingIdentifier
        )

        let report =
            try await LivePhotoFileReadbackReporter()
            .report(
                stillPhotoURL:
                    stillURL,
                pairedVideoURL:
                    videoURL
            )

        #expect(
            report.stillContentIdentifier
            == pairingIdentifier
        )
        #expect(
            report.pairedVideoContentIdentifier
            == pairingIdentifier
        )
        #expect(
            report.isPairingIdentifierMatched
        )
        #expect(
            report.stillPixelWidth == 8
        )
        #expect(
            report.stillPixelHeight == 8
        )
        #expect(
            report.pairedVideoPixelWidth == 8
        )
        #expect(
            report.pairedVideoPixelHeight == 8
        )
    }

    @Test("Accepts only image assets that Photos marks as Live Photo with paired resources")
    func acceptsOnlyImageAssetsMarkedAsLivePhotoWithPairedResources() {
        let validReport =
            LivePhotoAssetReadbackReport(
                localIdentifier: "asset-1",
                pixelWidth: 4032,
                pixelHeight: 3704,
                duration: 2.7,
                isImageAsset: true,
                isLivePhoto: true,
                resources: [
                    LivePhotoAssetReadbackResource(
                        kind: .photo,
                        originalFilename: "IMG_6093.HEIC",
                        uniformTypeIdentifier:
                            "public.heic"
                    ),
                    LivePhotoAssetReadbackResource(
                        kind: .pairedVideo,
                        originalFilename: "IMG_6093.mov",
                        uniformTypeIdentifier:
                            "com.apple.quicktime-movie"
                    )
                ]
            )
        let stillOnlyReport =
            LivePhotoAssetReadbackReport(
                localIdentifier: "asset-2",
                pixelWidth: 4032,
                pixelHeight: 3704,
                duration: 0,
                isImageAsset: true,
                isLivePhoto: false,
                resources: [
                    LivePhotoAssetReadbackResource(
                        kind: .photo,
                        originalFilename: "IMG_6093.HEIC",
                        uniformTypeIdentifier:
                            "public.heic"
                    )
                ]
            )
        let unpairedLiveMarkedReport =
            LivePhotoAssetReadbackReport(
                localIdentifier: "asset-3",
                pixelWidth: 4032,
                pixelHeight: 3704,
                duration: 0,
                isImageAsset: true,
                isLivePhoto: true,
                resources: [
                    LivePhotoAssetReadbackResource(
                        kind: .photo,
                        originalFilename: "IMG_6093.HEIC",
                        uniformTypeIdentifier:
                            "public.heic"
                    )
                ]
            )

        #expect(
            validReport
            .satisfiesLivePhotoPairingContract
        )
        #expect(
            !stillOnlyReport
            .satisfiesLivePhotoPairingContract
        )
        #expect(
            !unpairedLiveMarkedReport
            .satisfiesLivePhotoPairingContract
        )
    }
}

private extension LivePhotoAssetReadbackVerificationTests {

    func writeStillImage(
        at url: URL,
        pairingIdentifier: String
    ) throws {
        let width = 8
        let height = 8
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
        let image =
            try #require(
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
        let properties: [CFString: Any] = [
            kCGImagePropertyPixelWidth:
                width,
            kCGImagePropertyPixelHeight:
                height,
            kCGImagePropertyMakerAppleDictionary: [
                "17":
                    pairingIdentifier
            ],
            kCGImagePropertyExifDictionary: [
                kCGImagePropertyExifDateTimeOriginal:
                    "2026:06:25 12:34:56"
            ],
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitude:
                    34.414,
                kCGImagePropertyGPSLongitude:
                    115.656
            ]
        ]
        let destination =
            try #require(
                CGImageDestinationCreateWithURL(
                    url as CFURL,
                    UTType.heic.identifier as CFString,
                    1,
                    nil
                )
            )

        CGImageDestinationAddImage(
            destination,
            image,
            properties as CFDictionary
        )
        #expect(
            CGImageDestinationFinalize(destination)
        )
    }

    func writeVideo(
        at url: URL,
        contentIdentifier: String
    ) async throws {
        try? FileManager.default.removeItem(
            at: url
        )

        let writer =
            try AVAssetWriter(
                outputURL: url,
                fileType: .mov
            )
        writer.metadata = [
            quickTimeMetadataItem(
                identifier:
                    .quickTimeMetadataContentIdentifier,
                value:
                    contentIdentifier
            ),
            quickTimeMetadataItem(
                identifier:
                    .quickTimeMetadataCreationDate,
                value:
                    "2026-06-25T10:11:12+0800"
            )
        ]

        let input =
            AVAssetWriterInput(
                mediaType: .video,
                outputSettings: [
                    AVVideoCodecKey:
                        AVVideoCodecType.h264,
                    AVVideoWidthKey:
                        8,
                    AVVideoHeightKey:
                        8
                ]
            )
        let adaptor =
            AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: input,
                sourcePixelBufferAttributes: [
                    kCVPixelBufferPixelFormatTypeKey as String:
                        Int(kCVPixelFormatType_32ARGB),
                    kCVPixelBufferWidthKey as String:
                        8,
                    kCVPixelBufferHeightKey as String:
                        8
                ]
            )

        #expect(
            writer.canAdd(input)
        )
        writer.add(input)
        #expect(
            writer.startWriting()
        )
        writer.startSession(atSourceTime: .zero)

        let pixelBuffer =
            try makePixelBuffer()
        #expect(
            adaptor.append(
                pixelBuffer,
                withPresentationTime: .zero
            )
        )
        input.markAsFinished()

        await withCheckedContinuation {
            continuation in
            writer.finishWriting {
                continuation.resume()
            }
        }

        #expect(
            writer.status == .completed
        )
    }

    func quickTimeMetadataItem(
        identifier: AVMetadataIdentifier,
        value: String
    ) -> AVMetadataItem {
        let item =
            AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as NSString
        item.dataType =
            kCMMetadataBaseDataType_UTF8 as String

        return item.copy() as! AVMetadataItem
    }

    func makePixelBuffer() throws -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let status =
            CVPixelBufferCreate(
                nil,
                8,
                8,
                kCVPixelFormatType_32ARGB,
                nil,
                &pixelBuffer
            )
        guard
            status == kCVReturnSuccess,
            let pixelBuffer
        else {
            throw NSError(
                domain:
                    "LivePhotoAssetReadbackVerificationTests",
                code:
                    Int(status)
            )
        }

        CVPixelBufferLockBaseAddress(
            pixelBuffer,
            []
        )
        defer {
            CVPixelBufferUnlockBaseAddress(
                pixelBuffer,
                []
            )
        }

        memset(
            CVPixelBufferGetBaseAddress(pixelBuffer),
            255,
            CVPixelBufferGetDataSize(pixelBuffer)
        )

        return pixelBuffer
    }
}
