import CoreGraphics
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Presentation artifact renderer-neutral contract")
struct PresentationArtifactRendererNeutralContractTests {

    @Test("Artifact preserves an arbitrary layer stack and canvas policy when geometry is replaced")
    func preservesLayerStackAndCanvasPolicyWhenGeometryIsReplaced() throws {
        let footerImage = try makeSolidImage(
            width: 20,
            height: 10
        )
        let badgeImage = try makeSolidImage(
            width: 8,
            height: 8
        )
        let titleImage = try makeSolidImage(
            width: 12,
            height: 4
        )

        let artifact = try PresentationArtifact(
            canvasSize: CGSize(width: 100, height: 100),
            photoFrame: CGRect(x: 0, y: 20, width: 100, height: 80),
            footerFrame: CGRect(x: 0, y: 0, width: 100, height: 20),
            footerImage: footerImage,
            canvasBackground: .opaqueWhite,
            layers: [
                .init(
                    frame: CGRect(x: 10, y: 4, width: 20, height: 8),
                    image: badgeImage,
                    zIndex: 10,
                    opacity: 0.9
                ),
                .init(
                    frame: CGRect(x: 42, y: 5, width: 30, height: 10),
                    image: titleImage,
                    zIndex: 20,
                    opacity: 1
                )
            ]
        )

        let replaced = try artifact.replacingGeometry(
            canvasSize: CGSize(width: 200, height: 200),
            photoFrame: CGRect(x: 0, y: 40, width: 200, height: 160),
            footerFrame: CGRect(x: 0, y: 0, width: 200, height: 40)
        )

        #expect(replaced.canvasSize == CGSize(width: 200, height: 200))
        #expect(replaced.photoFrame == CGRect(x: 0, y: 40, width: 200, height: 160))
        #expect(replaced.footerFrame == CGRect(x: 0, y: 0, width: 200, height: 40))
        #expect(replaced.placement == .footer)
        #expect(replaced.canvasBackground == .opaqueWhite)
        #expect(replaced.layers.count == 2)
        #expect(replaced.layers[0].frame == CGRect(x: 20, y: 8, width: 40, height: 16))
        #expect(replaced.layers[1].frame == CGRect(x: 84, y: 10, width: 60, height: 20))
        #expect(replaced.layers[0].image.width == badgeImage.width)
        #expect(replaced.layers[0].image.height == badgeImage.height)
        #expect(replaced.layers[0].zIndex == 10)
        #expect(replaced.layers[0].opacity == 0.9)
        #expect(replaced.layers[1].image.width == titleImage.width)
        #expect(replaced.layers[1].image.height == titleImage.height)
        #expect(replaced.layers[1].zIndex == 20)
        #expect(replaced.layers[1].opacity == 1)
    }

    @Test("Footer artifacts default to an opaque canvas and expose the footer as a layer")
    func footerArtifactsDefaultToOpaqueCanvasAndExposeFooterAsLayer() throws {
        let footerImage = try makeSolidImage(width: 40, height: 10)
        let artifact = try PresentationArtifact(
            canvasSize: CGSize(width: 40, height: 40),
            photoFrame: CGRect(x: 0, y: 10, width: 40, height: 30),
            footerFrame: CGRect(x: 0, y: 0, width: 40, height: 10),
            footerImage: footerImage
        )

        #expect(artifact.canvasBackground == .opaqueWhite)
        #expect(artifact.placement == .footer)
        #expect(artifact.layers.count == 1)
        #expect(artifact.layers[0].frame == artifact.footerFrame)
        #expect(artifact.layers[0].image.width == footerImage.width)
        #expect(artifact.layers[0].image.height == footerImage.height)
    }

    @Test("Floating artifacts keep the full source canvas and allow photo-layer overlap")
    func floatingArtifactUsesSameCanvas() throws {
        let overlayImage = try makeSolidImage(width: 100, height: 100)
        let canvas = CGRect(x: 0, y: 0, width: 100, height: 100)
        let artifact = try PresentationArtifact(
            canvasSize: CGSize(width: 100, height: 100),
            photoFrame: canvas,
            footerFrame: canvas,
            footerImage: overlayImage,
            placement: .floating,
            canvasBackground: .transparent,
            layers: [.init(frame: canvas, image: overlayImage, zIndex: 100)]
        )

        #expect(artifact.placement == .floating)
        #expect(artifact.photoFrame == canvas)
        #expect(artifact.canvasBackground == .transparent)
        #expect(artifact.photoFrame.intersection(artifact.footerFrame) == canvas)
        _ = try artifact.validatedForEncoder()
    }

    @Test("Static export compositor draws floating artifact layers by frame")
    func staticExportCompositorDrawsFloatingLayersByFrame() throws {
        let sourceImage = try makeSolidImage(
            width: 40,
            height: 30,
            color: .red
        )
        let layerImage = try makeSolidImage(
            width: 8,
            height: 6,
            color: .blue
        )
        let layerFrame = CGRect(x: 28, y: 4, width: 8, height: 6)
        let artifact = try PresentationArtifact(
            canvasSize: CGSize(width: 40, height: 30),
            photoFrame: CGRect(x: 0, y: 0, width: 40, height: 30),
            footerFrame: layerFrame,
            footerImage: layerImage,
            placement: .floating,
            canvasBackground: .transparent,
            layers: [
                .init(frame: layerFrame, image: layerImage, zIndex: 100)
            ]
        )

        let composed = try #require(
            PhotoMemoRenderedImageArtifactGuard.composingSourcePhoto(
                sourceImage,
                with: artifact
            )
        )

        #expect(composed.width == 40)
        #expect(composed.height == 30)
        #expect(
            colorDistance(
                averageColor(
                    in: composed,
                    rect: layerFrame
                ),
                .blue
            ) <= 4
        )
        #expect(
            colorDistance(
                averageColor(
                    in: composed,
                    rect: CGRect(x: 0, y: 12, width: 12, height: 10)
                ),
                .red
            ) <= 4
        )
    }

    @Test("Still and video composers consume artifact layers and background policy")
    func stillAndVideoComposersConsumeArtifactLayersAndBackgroundPolicy() throws {
        let stillSource = try sourceFile(
            "Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/LivePhotoStillImageCompositionService.swift"
        )
        let videoSource = try sourceFile(
            "Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/LivePhotoVideoCompositionService.swift"
        )

        for source in [stillSource, videoSource] {
            #expect(source.contains("preparedOverlay.layers"))
            #expect(source.contains("preparedOverlay.canvasBackground"))
            #expect(!source.contains("presentationStyle"))
            #expect(!source.contains("RecordCardRenderer"))
            #expect(!source.contains(".minimal"))
            #expect(!source.contains(".classicWhite"))
        }
    }

    @Test("Live Photo pair composition resolves one geometry for still and paired video")
    func pairCompositionResolvesOneGeometryForStillAndPairedVideo() throws {
        let source = try sourceFile(
            "Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/LivePhotoVideoCompositionService.swift"
        )

        #expect(source.contains("let geometry ="))
        #expect(source.contains("geometry:"))
        #expect(source.contains("composePairedVideo"))
        #expect(source.contains("pairingIdentityPlan"))
        #expect(!source.contains("presentationStyle"))
        #expect(!source.contains(".minimal"))
        #expect(!source.contains(".classicWhite"))
    }

    @Test("Media processing route does not branch on a concrete renderer style")
    func mediaProcessingRouteDoesNotBranchOnConcreteRendererStyle() throws {
        let mediaSources = [
            "Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/LivePhotoGeometryResolver.swift",
            "Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/LivePhotoRenderOutputGeometry.swift",
            "Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/LivePhotoVideoCompositionInput.swift",
            "Source/PhotoMemo/PhotoMemo/Services/LivePhotoBatchTaskProcessor.swift"
        ]

        for relativePath in mediaSources {
            let source = try sourceFile(relativePath)
            #expect(!source.contains("presentationStyle"))
            #expect(!source.contains("RecordCardRenderer"))
            #expect(!source.contains(".minimal"))
            #expect(!source.contains(".classicWhite"))
            #expect(!source.contains("composeFloatingVideo"))
            #expect(!source.contains("renderMinimalLivePhotoOverlay"))
        }
    }
}

private extension PresentationArtifactRendererNeutralContractTests {

    struct RGBAColor:
        Equatable,
        Sendable {
        let red: UInt8
        let green: UInt8
        let blue: UInt8
        let alpha: UInt8

        static let white = RGBAColor(red: 255, green: 255, blue: 255, alpha: 255)
        static let red = RGBAColor(red: 255, green: 0, blue: 0, alpha: 255)
        static let blue = RGBAColor(red: 0, green: 0, blue: 255, alpha: 255)
    }

    func makeSolidImage(
        width: Int,
        height: Int,
        color: RGBAColor = .white
    ) throws -> CGImage {
        let bytesPerRow = width * 4
        var data = [UInt8](repeating: 0, count: bytesPerRow * height)
        for offset in stride(from: 0, to: data.count, by: 4) {
            data[offset] = color.red
            data[offset + 1] = color.green
            data[offset + 2] = color.blue
            data[offset + 3] = color.alpha
        }
        let provider = try #require(
            CGDataProvider(data: Data(data) as CFData)
        )
        return try #require(
            CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(
                    rawValue: CGImageAlphaInfo.premultipliedLast.rawValue
                ),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        )
    }

    func averageColor(
        in image: CGImage,
        rect: CGRect
    ) -> RGBAColor {
        guard let data = image.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            return RGBAColor(red: 0, green: 0, blue: 0, alpha: 0)
        }

        let minX = max(Int(rect.minX), 0)
        let maxX = min(Int(rect.maxX), image.width)
        let minY = max(Int(rect.minY), 0)
        let maxY = min(Int(rect.maxY), image.height)
        var redTotal = 0
        var greenTotal = 0
        var blueTotal = 0
        var alphaTotal = 0
        var count = 0

        for x in minX..<maxX {
            for yFromBottom in minY..<maxY {
                let y = image.height - 1 - yFromBottom
                let offset = y * image.bytesPerRow + x * 4
                redTotal += Int(bytes[offset])
                greenTotal += Int(bytes[offset + 1])
                blueTotal += Int(bytes[offset + 2])
                alphaTotal += Int(bytes[offset + 3])
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

    func sourceFile(_ relativePath: String) throws -> String {
        try String(
            contentsOf: sourceURL(relativePath),
            encoding: .utf8
        )
    }

    func sourceURL(_ relativePath: String) -> URL {
        let testsDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
        let repositoryRoot = testsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return repositoryRoot.appendingPathComponent(relativePath)
    }
}
