import AVFoundation
import CoreGraphics
import CoreImage
import Foundation
import Testing
@testable import MemoMark

@Suite("Live Photo video composition service")
struct LivePhotoVideoCompositionServiceTests {

    @Test("Native backdrop follows motion and preserves canonical output geometry and foreground")
    func nativeBackdropSamplesEveryFrame() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("NativeBackdropVideo-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let source = folder.appendingPathComponent("source.mov")
        try await makeSampleVideo(at: source, size: CGSize(width: 80, height: 60),
            frameColors: [.red, .red, .green, .green], framesPerSecond: 2)
        let ink = try makeSolidColorImage(color: .init(red: 255, green: 255, blue: 255, alpha: 255),
            size: CGSize(width: 8, height: 8))
        let artifact = try PresentationArtifact(canvasSize: CGSize(width: 160, height: 120),
            photoFrame: CGRect(x: 0, y: 0, width: 160, height: 120),
            layers: [.init(frame: CGRect(x: 70, y: 18, width: 8, height: 8), image: ink)],
            canvasBackground: .transparent,
            backdropMaterial: .init(frame: CGRect(x: 8, y: 8, width: 144, height: 24),
                renderFrame: CGRect(x: 0, y: 0, width: 160, height: 50), cornerRadius: 12))
        let output = try await LivePhotoVideoCompositionService().composeVideo(sourceVideoURL: source,
            overlay: artifact, outputURL: folder.appendingPathComponent("output.mov"))
        let asset = AVURLAsset(url: output)
        Attachment.record(try Data(contentsOf: output), named: "native-backdrop-motion.mov")
        let track = try #require(try await asset.loadTracks(withMediaType: .video).first)
        #expect(try await track.load(.naturalSize) == artifact.canvasSize)
        let first = try await frameImage(from: asset, at: CMTime(seconds: 0.25, preferredTimescale: 600))
        let later = try await frameImage(from: asset, at: CMTime(seconds: 1.25, preferredTimescale: 600))
        let rail = CGRect(x: 30, y: 14, width: 16, height: 12)
        let firstRail = averageColor(in: first, rect: rail)
        let laterRail = averageColor(in: later, rect: rail)
        let firstPhoto = averageColor(in: first, rect: CGRect(x: 30, y: 70, width: 30, height: 20))
        let laterPhoto = averageColor(in: later, rect: CGRect(x: 30, y: 70, width: 30, height: 20))
        let firstChange = abs(Int(firstPhoto.red) - Int(firstRail.red))
            + abs(Int(firstPhoto.green) - Int(firstRail.green)) + abs(Int(firstPhoto.blue) - Int(firstRail.blue))
        let laterChange = abs(Int(laterPhoto.red) - Int(laterRail.red))
            + abs(Int(laterPhoto.green) - Int(laterRail.green)) + abs(Int(laterPhoto.blue) - Int(laterRail.blue))
        // Native glass adapts tint; it does not promise a fixed per-channel darkening.
        #expect(firstChange > 15)
        #expect(laterChange > 15)
        #expect(Int(firstRail.red) > Int(laterRail.red) + 40)
        #expect(Int(laterRail.green) > Int(firstRail.green) + 40)
        for frame in [first, later] {
            let white = averageColor(in: frame, rect: CGRect(x: 72, y: 20, width: 4, height: 4))
            #expect(white.red > 230 && white.green > 230 && white.blue > 230)
        }
        let inputAsset = AVURLAsset(url: source)
        let sourceFirst = try await frameImage(from: inputAsset, at: CMTime(seconds: 0.25, preferredTimescale: 600))
        let sourceLater = try await frameImage(from: inputAsset, at: CMTime(seconds: 1.25, preferredTimescale: 600))
        let sourceRed = averageColor(in: sourceFirst, rect: CGRect(x: 15, y: 35, width: 15, height: 10))
        let sourceGreen = averageColor(in: sourceLater, rect: CGRect(x: 15, y: 35, width: 15, height: 10))
        let controlArtifact = try PresentationArtifact(canvasSize: artifact.canvasSize,
            photoFrame: artifact.photoFrame, layers: artifact.layers, canvasBackground: artifact.canvasBackground)
        let controlURL = try await LivePhotoVideoCompositionService().composeVideo(sourceVideoURL: source,
            overlay: controlArtifact, outputURL: folder.appendingPathComponent("control.mov"))
        let controlAsset = AVURLAsset(url: controlURL)
        for (name, media) in [("source", inputAsset), ("native", asset), ("control", controlAsset)] {
            let track = try #require(try await media.loadTracks(withMediaType: .video).first)
            let descriptions = try await track.load(.formatDescriptions)
            let description = try #require(descriptions.first)
            Attachment.record(Data(String(describing: CMFormatDescriptionGetExtensions(description)).utf8), named: "\(name)-format.txt")
        }
        let controlFirst = try await frameImage(from: controlAsset, at: CMTime(seconds: 0.25, preferredTimescale: 600))
        let controlLater = try await frameImage(from: controlAsset, at: CMTime(seconds: 1.25, preferredTimescale: 600))
        let controlRed = averageColor(in: controlFirst, rect: CGRect(x: 30, y: 70, width: 30, height: 20))
        let controlGreen = averageColor(in: controlLater, rect: CGRect(x: 30, y: 70, width: 30, height: 20))
        Attachment.record(try JSONSerialization.data(withJSONObject: [
            "sourceRed": sourceRed.red, "nativeRed": firstPhoto.red, "controlRed": controlRed.red,
            "sourceGreen": sourceGreen.green, "nativeGreen": laterPhoto.green, "controlGreen": controlGreen.green
        ], options: [.sortedKeys]), named: "native-source-control-color.json")
        #expect(abs(Int(firstPhoto.red) - Int(controlRed.red)) <= 3)
        #expect(abs(Int(laterPhoto.green) - Int(controlGreen.green)) <= 3)
    }

    @Test("Native backdrop preserves asymmetric source orientation")
    func nativeBackdropPreservesRotatedSource() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("NativeRotation-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let source = folder.appendingPathComponent("source.mov")
        try await makeSampleVideo(at: source, size: CGSize(width: 80, height: 60),
            frameColors: [.red, .red, .green, .green], framesPerSecond: 2,
            preferredTransform: CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: 60, ty: 0), topHalfBlue: true)
        let ink = try makeSolidColorImage(color: .red, size: CGSize(width: 2, height: 2))
        let artifact = try PresentationArtifact(canvasSize: CGSize(width: 120, height: 160),
            photoFrame: CGRect(x: 0, y: 0, width: 120, height: 160),
            layers: [.init(frame: CGRect(x: 8, y: 8, width: 2, height: 2), image: ink)],
            canvasBackground: .transparent,
            backdropMaterial: .init(frame: CGRect(x: 8, y: 8, width: 104, height: 24),
                renderFrame: CGRect(x: 0, y: 0, width: 120, height: 50), cornerRadius: 12))
        let output = try await LivePhotoVideoCompositionService().composeVideo(sourceVideoURL: source,
            overlay: artifact, outputURL: folder.appendingPathComponent("native.mov"))
        let control = try PresentationArtifact(canvasSize: artifact.canvasSize,
            photoFrame: artifact.photoFrame, layers: artifact.layers, canvasBackground: .transparent)
        let reference = try await LivePhotoVideoCompositionService().composeVideo(sourceVideoURL: source,
            overlay: control, outputURL: folder.appendingPathComponent("control.mov"))
        for seconds in [0.25, 1.25] {
            let time = CMTime(seconds: seconds, preferredTimescale: 600)
            let actual = try await frameImage(from: AVURLAsset(url: output), at: time)
            let expected = try await frameImage(from: AVURLAsset(url: reference), at: time)
            for rect in [CGRect(x: 15, y: 80, width: 20, height: 30), CGRect(x: 85, y: 80, width: 20, height: 30)] {
                let lhs = averageColor(in: actual, rect: rect)
                let rhs = averageColor(in: expected, rect: rect)
                #expect(abs(Int(lhs.red) - Int(rhs.red)) <= 5)
                #expect(abs(Int(lhs.green) - Int(rhs.green)) <= 5)
                #expect(abs(Int(lhs.blue) - Int(rhs.blue)) <= 5)
            }
        }
    }

    @Test("Composes a video with a fixed footer while preserving motion in the photo area")
    func composesVideoWithFixedFooterAndDynamicPhotoArea() async throws {
        let temporaryFolder =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "LivePhotoVideoCompositionServiceTests-\(UUID().uuidString)",
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

        let sourceVideoURL =
            temporaryFolder.appendingPathComponent(
                "source.mov"
            )
        try await makeSampleVideo(
            at: sourceVideoURL,
            size: CGSize(width: 40, height: 30),
            frameColors: [
                .red,
                RGBAColor(red: 255, green: 255, blue: 0, alpha: 255),
                .green,
                RGBAColor(red: 255, green: 0, blue: 255, alpha: 255)
            ],
            framesPerSecond: 2
        )

        let outputVideoURL =
            temporaryFolder.appendingPathComponent(
                "output.mov"
            )
        let footerImage =
            try makeSolidColorImage(
                color: .blue,
                size: CGSize(width: 40, height: 10)
            )
        let descriptor =
            try FixedFooterOverlayDescriptor(
                canvasSize: CGSize(width: 40, height: 40),
                photoFrame: CGRect(x: 0, y: 10, width: 40, height: 30),
                footerFrame: CGRect(x: 0, y: 0, width: 40, height: 10),
                footerImage: footerImage
            )

        let resultURL =
            try await LivePhotoVideoCompositionService()
            .composeVideo(
                sourceVideoURL: sourceVideoURL,
                overlay: descriptor,
                outputURL: outputVideoURL
            )

        let asset =
            AVURLAsset(url: resultURL)
        let loadedVideoTracks =
            try await asset.loadTracks(
                withMediaType: .video
            )
        let videoTrack =
            try #require(
                loadedVideoTracks.first
            )
        let outputSize =
            try await videoTrack.load(
                .naturalSize
            )

        #expect(
            Int(outputSize.width) == 40
        )
        #expect(
            Int(outputSize.height) == 40
        )

        let firstFrame =
            try await frameImage(
                from: asset,
                at: CMTime(
                    seconds: 0.25,
                    preferredTimescale: 600
                )
            )
        let laterFrame =
            try await frameImage(
                from: asset,
                at: CMTime(
                    seconds: 1.25,
                    preferredTimescale: 600
                )
            )

        let firstFooterAverage =
            averageColor(
                in: firstFrame,
                rect: CGRect(
                    x: 0,
                    y: 0,
                    width: 40,
                    height: 10
                )
            )
        let laterFooterAverage =
            averageColor(
                in: laterFrame,
                rect: CGRect(
                    x: 0,
                    y: 0,
                    width: 40,
                    height: 10
                )
            )
        let firstPhotoAverage =
            averageColor(
                in: firstFrame,
                rect: CGRect(
                    x: 0,
                    y: 10,
                    width: 40,
                    height: 30
                )
            )
        let laterPhotoAverage =
            averageColor(
                in: laterFrame,
                rect: CGRect(
                    x: 0,
                    y: 10,
                    width: 40,
                    height: 30
                )
            )

        #expect(
            colorDistance(
                firstFooterAverage,
                laterFooterAverage
            ) <= 8
        )
        #expect(
            colorDistance(
                firstPhotoAverage,
                laterPhotoAverage
            ) >= 40
        )
        #expect(
            colorDistance(
                firstFooterAverage,
                firstPhotoAverage
            ) >= 40
        )
    }

    @Test("Generic video output strips Live Photo pairing metadata")
    func genericVideoOutputStripsLivePhotoPairingMetadata() async throws {
        let temporaryFolder =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "LivePhotoVideoCompositionServiceTests-\(UUID().uuidString)",
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

        let sourceVideoURL =
            temporaryFolder.appendingPathComponent(
                "source.mov"
            )
        let expectedIdentifier =
            "2AB295AF-CFD8-4C47-9579-90249E28F68F"

        try await makeSampleVideo(
            at: sourceVideoURL,
            size: CGSize(width: 40, height: 30),
            frameColors: [
                .red
            ],
            framesPerSecond: 1,
            metadata: [
                quickTimeMetadataItem(
                    identifier:
                        .quickTimeMetadataContentIdentifier,
                    value:
                        expectedIdentifier
                )
            ]
        )

        let outputVideoURL =
            temporaryFolder.appendingPathComponent(
                "output.mov"
            )
        let descriptor =
            try FixedFooterOverlayDescriptor(
                canvasSize: CGSize(width: 40, height: 40),
                photoFrame: CGRect(x: 0, y: 10, width: 40, height: 30),
                footerFrame: CGRect(x: 0, y: 0, width: 40, height: 10),
                footerImage:
                    makeSolidColorImage(
                        color: .blue,
                        size: CGSize(width: 40, height: 10)
                    )
            )

        let resultURL =
            try await LivePhotoVideoCompositionService()
            .composeVideo(
                sourceVideoURL: sourceVideoURL,
                overlay: descriptor,
                outputURL: outputVideoURL
            )

        let resultAsset =
            AVURLAsset(url: resultURL)
        let resultMetadata =
            try await resultAsset.load(.metadata)
        let contentIdentifier =
            resultMetadata.first {
                $0.identifier
                    == .quickTimeMetadataContentIdentifier
            }

        #expect(contentIdentifier == nil)
    }

    @Test("Paired video metadata fails closed without a generated identity")
    func pairedVideoMetadataFailsClosedWithoutGeneratedIdentity() async throws {
        let descriptor =
            try FixedFooterOverlayDescriptor(
                canvasSize: CGSize(width: 40, height: 40),
                photoFrame: CGRect(x: 0, y: 10, width: 40, height: 30),
                footerFrame: CGRect(x: 0, y: 0, width: 40, height: 10),
                footerImage: makeSolidColorImage(
                    color: .blue,
                    size: CGSize(width: 40, height: 10)
                )
            )

        do {
            _ = try await LivePhotoVideoCompositionService()
                .metadataForExport(
                    sourceMetadata: [
                        quickTimeMetadataItem(
                            identifier: .quickTimeMetadataContentIdentifier,
                            value: "source-identifier-must-not-be-reused"
                        )
                    ],
                    sourceVideoURL: URL(fileURLWithPath: "/tmp/source.mov"),
                    outputURL: URL(fileURLWithPath: "/tmp/output.mov"),
                    preparedOverlay: descriptor,
                    requiresPairingIdentity: true
                )
            Issue.record("Expected paired metadata generation to fail closed")
        } catch let error as LivePhotoVideoCompositionError {
            #expect(error == .pairingIdentityMissing)
        } catch {
            Issue.record("Received unexpected error: \(error)")
        }
    }

    @Test("Builds export metadata through the VNext MOV metadata contract")
    func buildsExportMetadataThroughVNextMOVMetadataContract() async throws {
        let sourceVideoURL =
            URL(fileURLWithPath: "/tmp/source.mov")
        let outputVideoURL =
            URL(fileURLWithPath: "/tmp/output.mov")
        let descriptor =
            try FixedFooterOverlayDescriptor(
                canvasSize: CGSize(width: 40, height: 40),
                photoFrame: CGRect(x: 0, y: 10, width: 40, height: 30),
                footerFrame: CGRect(x: 0, y: 0, width: 40, height: 10),
                footerImage:
                    makeSolidColorImage(
                        color: .blue,
                        size: CGSize(width: 40, height: 10)
                    )
            )
        let expectedIdentifier =
            "2AB295AF-CFD8-4C47-9579-90249E28F68F"
        let metadata = [
            quickTimeMetadataItem(
                identifier:
                    .quickTimeMetadataContentIdentifier,
                value:
                    expectedIdentifier
            ),
            quickTimeMetadataItem(
                identifier:
                    .quickTimeMetadataCreationDate,
                value:
                    "2026-06-25T10:11:12+0800"
            )
        ]

        let exportMetadata =
            try await LivePhotoVideoCompositionService()
            .metadataForExport(
                sourceMetadata: metadata,
                sourceVideoURL: sourceVideoURL,
                outputURL: outputVideoURL,
                preparedOverlay: descriptor
            )
        let contentIdentifiers =
            exportMetadata.filter {
                $0.identifier == .quickTimeMetadataContentIdentifier
            }
        let creationDate =
            exportMetadata.first {
                $0.identifier == .quickTimeMetadataCreationDate
            }

        #expect(contentIdentifiers.isEmpty)
        #expect(
            try await creationDate?.load(.stringValue)
            == "2026-06-25T10:11:12+0800"
        )
    }

    @Test("Uses a generated Live Photo pairing identity when export metadata receives a plan")
    func usesGeneratedLivePhotoPairingIdentityForExportMetadata() async throws {
        let sourceVideoURL =
            URL(fileURLWithPath: "/tmp/source.mov")
        let outputVideoURL =
            URL(fileURLWithPath: "/tmp/output.mov")
        let descriptor =
            try FixedFooterOverlayDescriptor(
                canvasSize: CGSize(width: 40, height: 40),
                photoFrame: CGRect(x: 0, y: 10, width: 40, height: 30),
                footerFrame: CGRect(x: 0, y: 0, width: 40, height: 10),
                footerImage:
                    makeSolidColorImage(
                        color: .blue,
                        size: CGSize(width: 40, height: 10)
                    )
            )
        let metadata = [
            quickTimeMetadataItem(
                identifier:
                    .quickTimeMetadataContentIdentifier,
                value:
                    "source-pair-id"
            )
        ]
        let identityPlan =
            try LivePhotoPairingIdentityPlanner(
                generateIdentifier: {
                    "2AB295AF-CFD8-4C47-9579-90249E28F68F"
                }
            )
            .plan()

        let exportMetadata =
            try await LivePhotoVideoCompositionService()
            .metadataForExport(
                sourceMetadata: metadata,
                sourceVideoURL: sourceVideoURL,
                outputURL: outputVideoURL,
                preparedOverlay: descriptor,
                pairingIdentityPlan:
                    identityPlan
            )
        let contentIdentifier =
            exportMetadata.first {
                $0.identifier == .quickTimeMetadataContentIdentifier
            }

        #expect(
            try await contentIdentifier?.load(.stringValue)
            == "2AB295AF-CFD8-4C47-9579-90249E28F68F"
        )
    }

    @Test("Rejects unreadable source videos safely")
    func rejectsUnreadableSourceVideosSafely() async throws {
        let descriptor =
            try FixedFooterOverlayDescriptor(
                canvasSize: CGSize(width: 40, height: 40),
                photoFrame: CGRect(x: 0, y: 10, width: 40, height: 30),
                footerFrame: CGRect(x: 0, y: 0, width: 40, height: 10),
                footerImage: makeSolidColorImage(
                    color: .blue,
                    size: CGSize(width: 40, height: 10)
                )
            )
        let sourceVideoURL =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "missing-\(UUID().uuidString).mov"
            )
        let outputVideoURL =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "output-\(UUID().uuidString).mov"
            )

        do {
            _ = try await LivePhotoVideoCompositionService()
                .composeVideo(
                    sourceVideoURL: sourceVideoURL,
                    overlay: descriptor,
                    outputURL: outputVideoURL
                )
            Issue.record(
                "Expected unreadable source video to be rejected"
            )
        } catch let error as LivePhotoVideoCompositionError {
            #expect(
                error == .sourceVideoUnreadable
            )
        } catch {
            Issue.record(
                "Received unexpected error: \(error)"
            )
        }
    }

    @Test("Rejects odd canvas heights supplied outside the Layout Engine")
    func rejectsOddCanvasHeightsOutsideLayoutEngine() throws {
        let descriptor =
            try FixedFooterOverlayDescriptor(
                canvasSize: CGSize(width: 40, height: 41),
                photoFrame: CGRect(x: 0, y: 11, width: 40, height: 30),
                footerFrame: CGRect(x: 0, y: 0, width: 40, height: 11),
                footerImage: makeSolidColorImage(
                    color: .blue,
                    size: CGSize(width: 40, height: 11)
                )
            )

        do {
            _ = try descriptor.validatedForEncoder()
            Issue.record("Expected odd canvas geometry to be rejected")
        } catch let error as LivePhotoVideoCompositionError {
            #expect(error == .invalidOverlayGeometry)
        } catch {
            Issue.record("Received unexpected error: \(error)")
        }
    }

    @Test("Video transform preserves aspect ratio when filling the renderer photo frame")
    func videoTransformPreservesAspectRatioWhenFillingPhotoFrame() {
        let transform =
            AVFoundationLivePhotoVideoCompositionInputPreparer()
            .resolvedVideoTransform(
                preferredTransform: .identity,
                naturalSize:
                    CGSize(width: 20, height: 10),
                targetFrame:
                    CGRect(x: 0, y: 10, width: 40, height: 40)
            )
        let transformedRect =
            CGRect(
                origin: .zero,
                size:
                    CGSize(width: 20, height: 10)
            )
            .applying(transform)

        #expect(
            abs(
                transformedRect.width
                / transformedRect.height
                - 2
            ) < 0.001
        )
        #expect(
            transformedRect.height >= 40
        )
        #expect(
            transformedRect.width >= 40
        )
        #expect(
            abs(
                transformedRect.midX - 20
            ) < 0.001
        )
        #expect(
            abs(
                transformedRect.midY - 30
            ) < 0.001
        )
    }

    @Test("Maps Foundation canvas coordinates into AV video render coordinates")
    func mapsFoundationCanvasCoordinatesIntoAVVideoRenderCoordinates() {
        let preparer =
            AVFoundationLivePhotoVideoCompositionInputPreparer()
        let renderFrame =
            preparer.videoRenderFrame(
                for:
                    CGRect(
                        x: 0,
                        y: 10,
                        width: 40,
                        height: 30
                    ),
                canvasSize:
                    CGSize(
                        width: 40,
                        height: 40
                    )
            )

        #expect(
            renderFrame
            == CGRect(
                x: 0,
                y: 0,
                width: 40,
                height: 30
            )
        )

        let transform =
            preparer.resolvedVideoTransform(
                preferredTransform: .identity,
                naturalSize:
                    CGSize(
                        width: 40,
                        height: 30
                    ),
                targetFrame:
                    renderFrame
            )
        let transformedRect =
            CGRect(
                origin: .zero,
                size:
                    CGSize(
                        width: 40,
                        height: 30
                    )
            )
            .applying(transform)

        #expect(
            abs(transformedRect.minY) < 0.001
        )
        #expect(
            abs(transformedRect.maxY - 30) < 0.001
        )
    }
}

private extension LivePhotoVideoCompositionServiceTests {

    struct RGBAColor:
        Equatable,
        Sendable {
        let red: UInt8
        let green: UInt8
        let blue: UInt8
        let alpha: UInt8

        static let red = RGBAColor(
            red: 255,
            green: 0,
            blue: 0,
            alpha: 255
        )
        static let green = RGBAColor(
            red: 0,
            green: 255,
            blue: 0,
            alpha: 255
        )
        static let blue = RGBAColor(
            red: 0,
            green: 0,
            blue: 255,
            alpha: 255
        )
    }

    func makeSampleVideo(
        at url: URL,
        size: CGSize,
        frameColors: [RGBAColor],
        framesPerSecond: Int32,
        metadata: [AVMetadataItem] = [],
        preferredTransform: CGAffineTransform = .identity,
        topHalfBlue: Bool = false
    ) async throws {
        try? FileManager.default.removeItem(
            at: url
        )

        let writer =
            try AVAssetWriter(
                outputURL: url,
                fileType: .mov
            )
        writer.metadata = metadata

        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height)
        ]
        let input =
            AVAssetWriterInput(
                mediaType: .video,
                outputSettings: settings
            )
        input.expectsMediaDataInRealTime = false
        input.transform = preferredTransform

        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String:
                Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String:
                Int(size.width),
            kCVPixelBufferHeightKey as String:
                Int(size.height)
        ]
        let adaptor =
            AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: input,
                sourcePixelBufferAttributes:
                    attributes
            )

        guard writer.canAdd(input) else {
            Issue.record(
                "Unable to add video input to AVAssetWriter"
            )
            return
        }

        writer.add(input)
        #expect(writer.startWriting())
        writer.startSession(atSourceTime: .zero)

        let frameDuration =
            CMTime(
                value: 1,
                timescale: framesPerSecond
            )

        for (index, color) in
            frameColors.enumerated() {
            while !input.isReadyForMoreMediaData {
                try await Task.sleep(
                    nanoseconds: 10_000_000
                )
            }

            let presentationTime =
                CMTimeMultiply(
                    frameDuration,
                    multiplier: Int32(index)
                )
            let buffer =
                try makePixelBuffer(
                    color: color,
                    size: size, topHalfBlue: topHalfBlue
                )
            #expect(
                adaptor.append(
                    buffer,
                    withPresentationTime:
                        presentationTime
                )
            )
        }

        input.markAsFinished()

        await withCheckedContinuation {
            continuation in
            writer.finishWriting {
                continuation.resume()
            }
        }

        #expect(writer.status == .completed)
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

    func makePixelBuffer(
        color: RGBAColor,
        size: CGSize,
        topHalfBlue: Bool = false
    ) throws -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let status =
            CVPixelBufferCreate(
                nil,
                Int(size.width),
                Int(size.height),
                kCVPixelFormatType_32ARGB,
                nil,
                &pixelBuffer
            )
        guard
            status == kCVReturnSuccess,
            let pixelBuffer
        else {
            throw NSError(
                domain: "LivePhotoVideoCompositionServiceTests",
                code: Int(status)
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

        let bytesPerRow =
            CVPixelBufferGetBytesPerRow(
                pixelBuffer
            )
        let width =
            CVPixelBufferGetWidth(
                pixelBuffer
            )
        let height =
            CVPixelBufferGetHeight(
                pixelBuffer
            )

        let baseAddress =
            try #require(
                CVPixelBufferGetBaseAddress(
                    pixelBuffer
                )
            )
        let pointer =
            baseAddress.assumingMemoryBound(
                to: UInt8.self
            )

        for row in 0 ..< height {
            for column in 0 ..< width {
                let offset =
                    row * bytesPerRow
                    + column * 4
                let color = topHalfBlue && row < height / 2 ? RGBAColor.blue : color
                pointer[offset] = color.alpha
                pointer[offset + 1] = color.red
                pointer[offset + 2] = color.green
                pointer[offset + 3] = color.blue
            }
        }

        return pixelBuffer
    }

    func makeSolidColorImage(
        color: RGBAColor,
        size: CGSize
    ) throws -> CGImage {
        let colorSpace =
            CGColorSpaceCreateDeviceRGB()
        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var data =
            [UInt8](
                repeating: 0,
                count: bytesPerRow * height
            )

        for index in stride(
            from: 0,
            to: data.count,
            by: 4
        ) {
            data[index] = color.red
            data[index + 1] = color.green
            data[index + 2] = color.blue
            data[index + 3] = color.alpha
        }

        let provider =
            try #require(
                CGDataProvider(
                    data: Data(data) as CFData
                )
            )
        let bitmapInfo =
            CGBitmapInfo(
                rawValue:
                    CGImageAlphaInfo
                    .premultipliedLast
                    .rawValue
            )

        return try #require(
            CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo,
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        )
    }

    func frameImage(
        from asset: AVAsset,
        at time: CMTime
    ) async throws -> CGImage {
        let generator =
            AVAssetImageGenerator(
                asset: asset
            )
        generator.appliesPreferredTrackTransform =
            true
        generator.requestedTimeToleranceAfter = .zero
        generator.requestedTimeToleranceBefore = .zero

        let image = try await generator.image(at: time).image
        // AVFoundation may vend RGBA or BGRA CGImages. Pixel assertions use one explicit byte order.
        let context = try #require(CGContext(data: nil, width: image.width, height: image.height,
            bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return try #require(context.makeImage())
    }

    func videoFrameImages(
        from asset: AVAsset
    ) async throws -> [CGImage] {
        let tracks =
            try await asset.loadTracks(withMediaType: .video)
        let track = try #require(tracks.first)
        let reader = try AVAssetReader(asset: asset)
        let output =
            AVAssetReaderTrackOutput(
                track: track,
                outputSettings: [
                    kCVPixelBufferPixelFormatTypeKey as String:
                        Int(kCVPixelFormatType_32BGRA)
                ]
            )
        guard reader.canAdd(output) else {
            throw NSError(
                domain: "LivePhotoVideoCompositionServiceTests",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Unable to add output for frame inspection"
                ]
            )
        }
        reader.add(output)
        #expect(reader.startReading())

        let context = CIContext()
        var images: [CGImage] = []
        while let sampleBuffer = output.copyNextSampleBuffer() {
            let pixelBuffer = try #require(
                CMSampleBufferGetImageBuffer(sampleBuffer)
            )
            let image =
                CIImage(cvPixelBuffer: pixelBuffer)
            let cgImage = try #require(
                context.createCGImage(image, from: image.extent)
            )
            images.append(cgImage)
        }

        #expect(reader.status == .completed)
        return images
    }

    func pixelColor(
        in image: CGImage,
        at point: CGPoint
    ) -> RGBAColor {
        guard
            let dataProvider =
                image.dataProvider
        else {
            return .init(
                red: 0,
                green: 0,
                blue: 0,
                alpha: 0
            )
        }

        let data =
            dataProvider.data
        let bytes =
            CFDataGetBytePtr(data)

        guard
            let bytes
        else {
            return .init(
                red: 0,
                green: 0,
                blue: 0,
                alpha: 0
            )
        }

        let x =
            min(
                max(Int(point.x), 0),
                image.width - 1
            )
        let yFromBottom =
            min(
                max(Int(point.y), 0),
                image.height - 1
            )
        let y =
            image.height - 1 - yFromBottom
        let offset =
            y * image.bytesPerRow
            + x * 4

        return RGBAColor(
            red: bytes[offset],
            green: bytes[offset + 1],
            blue: bytes[offset + 2],
            alpha: bytes[offset + 3]
        )
    }

    func averageColor(
        in image: CGImage,
        rect: CGRect
    ) -> RGBAColor {
        let minX =
            max(Int(rect.minX), 0)
        let maxX =
            min(
                Int(rect.maxX),
                image.width
            )
        let minY =
            max(Int(rect.minY), 0)
        let maxY =
            min(
                Int(rect.maxY),
                image.height
            )

        guard
            minX < maxX,
            minY < maxY
        else {
            return .init(
                red: 0,
                green: 0,
                blue: 0,
                alpha: 0
            )
        }

        var redTotal = 0
        var greenTotal = 0
        var blueTotal = 0
        var alphaTotal = 0
        var count = 0

        for x in minX ..< maxX {
            for y in minY ..< maxY {
                let color =
                    pixelColor(
                        in: image,
                        at: CGPoint(
                            x: x,
                            y: y
                        )
                    )
                redTotal += Int(color.red)
                greenTotal += Int(color.green)
                blueTotal += Int(color.blue)
                alphaTotal += Int(color.alpha)
                count += 1
            }
        }

        return RGBAColor(
            red: UInt8(redTotal / max(count, 1)),
            green: UInt8(greenTotal / max(count, 1)),
            blue: UInt8(blueTotal / max(count, 1)),
            alpha: UInt8(alphaTotal / max(count, 1))
        )
    }

    func colorDistance(
        _ lhs: RGBAColor,
        _ rhs: RGBAColor
    ) -> Int {
        abs(Int(lhs.red) - Int(rhs.red))
            + abs(Int(lhs.green) - Int(rhs.green))
            + abs(Int(lhs.blue) - Int(rhs.blue))
    }
}
