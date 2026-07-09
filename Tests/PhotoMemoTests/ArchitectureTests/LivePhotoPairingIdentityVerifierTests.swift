import AVFoundation
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("Live Photo pairing identity verifier")
struct LivePhotoPairingIdentityVerifierTests {

    @Test("Builds one generated pairing identity plan for both Live Photo resources")
    func buildsGeneratedPairingIdentityPlan() throws {
        let planner =
            LivePhotoPairingIdentityPlanner(
                generateIdentifier: {
                    " 2AB295AF-CFD8-4C47-9579-90249E28F68F "
                }
            )

        let plan =
            try planner.plan()

        #expect(
            plan.pairingIdentifier
            == "2AB295AF-CFD8-4C47-9579-90249E28F68F"
        )
    }

    @Test("Rejects non-UUID generated pairing identifiers")
    func rejectsNonUUIDGeneratedPairingIdentifiers() throws {
        let planner =
            LivePhotoPairingIdentityPlanner(
                generateIdentifier: {
                    "generated-pair-id"
                }
            )

        do {
            _ = try planner.plan()
            Issue.record(
                "Expected non-UUID Live Photo pairing identifiers to be rejected"
            )
        } catch let error as LivePhotoPairingIdentityPlanningError {
            #expect(
                error == .invalidPairingIdentifier(
                    "generated-pair-id"
                )
            )
        } catch {
            Issue.record(
                "Received unexpected error: \(error)"
            )
        }
    }

    @Test("Extracts Apple still-image content identifier from MakerApple metadata")
    func extractsStillContentIdentifierFromMakerAppleMetadata() throws {
        let identifier =
            LivePhotoPairingIdentityVerifier
            .stillContentIdentifier(
                from: [
                    "{MakerApple}": [
                        17: "2AB295AF-CFD8-4C47-9579-90249E28F68F"
                    ]
                ]
            )

        #expect(
            identifier
            == "2AB295AF-CFD8-4C47-9579-90249E28F68F"
        )
    }

    @Test("Extracts paired-video content identifier from QuickTime metadata")
    func extractsVideoContentIdentifierFromQuickTimeMetadata() async throws {
        let expectedIdentifier =
            "2AB295AF-CFD8-4C47-9579-90249E28F68F"

        let identifier =
            try await LivePhotoPairingIdentityVerifier
            .videoContentIdentifier(
                from: [
                    quickTimeMetadataItem(
                        identifier:
                            .quickTimeMetadataContentIdentifier,
                        value:
                            expectedIdentifier
                    )
                ]
            )

        #expect(
            identifier
            == expectedIdentifier
        )
    }

    @Test("Rejects still-image files that do not contain a pairing identifier")
    func rejectsStillImageFilesMissingContentIdentifier() async throws {
        let temporaryFolder =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "LivePhotoPairingIdentityVerifierTests-\(UUID().uuidString)",
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
                "pair.jpg"
            )
        let videoURL =
            temporaryFolder.appendingPathComponent(
                "pair.mov"
            )

        try writeStillImage(
            at: stillURL,
            contentIdentifier:
                nil
        )
        try await writeVideo(
            at: videoURL,
            contentIdentifier:
                "2AB295AF-CFD8-4C47-9579-90249E28F68F"
        )

        do {
            _ = try await LivePhotoPairingIdentityVerifier()
                .verifyPair(
                    stillPhotoURL: stillURL,
                    pairedVideoURL: videoURL
                )
            Issue.record(
                "Expected a still image without a pairing identifier to be rejected"
            )
        } catch let error as LivePhotoPairingIdentityVerificationError {
            #expect(
                error == .stillContentIdentifierMissing
            )
        } catch {
            Issue.record(
                "Received unexpected error: \(error)"
            )
        }
    }

    @Test("Rejects mismatched still and video content identifiers")
    func rejectsMismatchedStillAndVideoContentIdentifiers() async throws {
        let verifier =
            LivePhotoPairingIdentityVerifier()

        do {
            _ = try verifier.validate(
                stillContentIdentifier:
                    "still-id",
                pairedVideoContentIdentifier:
                    "video-id"
            )
            Issue.record(
                "Expected mismatched identifiers to be rejected"
            )
        } catch let error as LivePhotoPairingIdentityVerificationError {
            #expect(
                error
                == .contentIdentifierMismatch(
                    still: "still-id",
                    pairedVideo: "video-id"
                )
            )
        } catch {
            Issue.record(
                "Received unexpected error: \(error)"
            )
        }
    }
}

private extension LivePhotoPairingIdentityVerifierTests {

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

    func writeStillImage(
        at url: URL,
        contentIdentifier: String?
    ) throws {
        let image =
            try makeSolidColorImage()
        let properties: [String: Any]

        if let contentIdentifier {
            properties = [
                "{MakerApple}": [
                    17:
                        contentIdentifier
                ]
            ]
        } else {
            properties = [:]
        }

        let destination =
            try #require(
                CGImageDestinationCreateWithURL(
                    url as CFURL,
                    UTType.jpeg.identifier as CFString,
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

    func makeSolidColorImage() throws -> CGImage {
        let width = 8
        let height = 8
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
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
                    "LivePhotoPairingIdentityVerifierTests",
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
