// Research-only harness. Run in the macOS test target; remove the temporary copy afterwards.
import CoreGraphics
import AppKit
import Foundation
import ImageIO
import SwiftUI
import Testing
import UniformTypeIdentifiers
@testable import MemoMark

@Suite("GlassCard material candidate screening")
struct GlassCardMaterialCandidateProbe {
    @Test("Compare actual SDR candidate composites and reproduce the production baseline")
    @MainActor
    func candidatePixels() throws {
        var rows = ["shortEdge,surfaceAlpha,secondaryOpacity,sourceGray,slot,minLuminance,maxLuminance,peakPixelContrast"]
        for edge: CGFloat in [360, 1080] {
            let size = CGSize(width: edge, height: edge * 4 / 3)
            let content = GlassCardContentProjection(leftTop: "HHHHHH", leftBottom: "HHHHHH", rightTop: "HHHHHH", rightBottom: "HHHHHH")
            let plan = GlassCardResolvedPresentation.resolve(content: content, canvasSize: size)
            #expect(!plan.isContentOverflowing)
            for alpha in [0.42, 0.50, 0.56, 0.62] {
                for opacity in [0.78, 0.96] {
                    let base = GlassCardProductionRenderer.recipe
                    let recipe = GlassCardMaterialRecipe(
                        researchID: "candidate", surface: .init(red: 0, green: 0, blue: 0, alpha: alpha),
                        keyline: base.keyline, shadow: base.shadow,
                        keylineWidthToPanelHeight: base.keylineWidthToPanelHeight,
                        shadowRadiusToPanelHeight: base.shadowRadiusToPanelHeight,
                        shadowOffsetToPanelHeight: base.shadowOffsetToPanelHeight
                    )
                    let frame = plan.overlayFrame
                    let renderer = ImageRenderer(content: GlassCardOverlayLayer(
                        presentation: plan, badge: nil, recipe: recipe, secondaryTextOpacity: opacity
                    ).offset(y: -frame.minY)
                        .frame(width: frame.width, height: frame.height, alignment: .topLeading).clipped())
                    renderer.scale = 1
                    renderer.proposedSize = .init(frame.size)
                    renderer.isOpaque = false
                    let overlay = try #require(renderer.cgImage)
                    let artifact = try PresentationArtifact(canvasSize: size,
                        photoFrame: CGRect(origin: .zero, size: size),
                        layers: [.init(frame: plan.artifactOverlayFrame, image: overlay, zIndex: 100)],
                        canvasBackground: .transparent)
                    for gray: UInt8 in [0, 128, 255] {
                        let source = try ImageEdgeAssertionSupport.solidImage(width: Int(size.width), height: Int(size.height), red: gray, green: gray, blue: gray)
                        let output = try #require(MemoMarkRenderedImageArtifactGuard.composingSourcePhoto(source, with: artifact))
                        if edge == 1080 && gray == 255 {
                            Attachment.record(try png(output), named: "candidate-a\(alpha)-text\(opacity)-white.png")
                        }
                        for (index, slot) in plan.slots.enumerated() {
                            let region = slot.frame.offsetBy(dx: plan.geometry.panelFrame.minX, dy: plan.geometry.panelFrame.minY).integral
                            let crop = try #require(output.cropping(to: region))
                            let values = try luminances(crop)
                            let low = try #require(values.min())
                            let high = try #require(values.max())
                            let contrast = (high + 0.05) / (low + 0.05)
                            if edge == 1080 && gray == 255 && alpha == 0.42 && opacity == 0.78 {
                                #expect(abs(contrast - (slot.isPrimary ? 3.2496 : 2.6943)) < 0.02)
                            }
                            rows.append("\(Int(edge)),\(alpha),\(opacity),\(gray),\(index),\(low),\(high),\(contrast)")
                        }
                    }
                }
            }
        }
        #expect(rows.count == 193)
        Attachment.record(Data(rows.joined(separator: "\n").utf8), named: "material-candidates.csv")
    }

    @Test("Render a local calibration photograph comparison without changing the default")
    @MainActor
    func calibrationComparison() throws {
        for orientation in ConfigurationPreviewBackground.Orientation.allCases {
            let name = ConfigurationPreviewBackground.minimal.assetName(forOrientation: orientation)
            let source = try #require(NSImage(named: name)?.cgImage(forProposedRect: nil, context: nil, hints: nil))
            let size = try #require(ConfigurationPreviewBackground.glassCardPixelSize(for: orientation))
            let plan = GlassCardResolvedPresentation.resolve(content: .init(
                leftTop: "一起走过的秋天", leftBottom: "相伴第 365 天",
                rightTop: "2026.10.01", rightBottom: "今天，也值得记住"
            ), canvasSize: size)
            #expect(!plan.isContentOverflowing)
            var outputs: [CGImage] = []
            for (alpha, opacity) in [(0.42, 0.78), (0.56, 0.96), (0.62, 0.78)] {
                let base = GlassCardProductionRenderer.recipe
                let recipe = GlassCardMaterialRecipe(researchID: "candidate",
                    surface: .init(red: 0, green: 0, blue: 0, alpha: alpha),
                    keyline: base.keyline, shadow: base.shadow,
                    keylineWidthToPanelHeight: base.keylineWidthToPanelHeight,
                    shadowRadiusToPanelHeight: base.shadowRadiusToPanelHeight,
                    shadowOffsetToPanelHeight: base.shadowOffsetToPanelHeight)
                let frame = plan.overlayFrame
                let renderer = ImageRenderer(content: GlassCardOverlayLayer(presentation: plan,
                    badge: nil, recipe: recipe, secondaryTextOpacity: opacity)
                    .offset(y: -frame.minY)
                    .frame(width: frame.width, height: frame.height, alignment: .topLeading).clipped())
                renderer.scale = 1
                renderer.proposedSize = .init(frame.size)
                let overlay = try #require(renderer.cgImage)
                let artifact = try PresentationArtifact(canvasSize: size,
                    photoFrame: CGRect(origin: .zero, size: size),
                    layers: [.init(frame: plan.artifactOverlayFrame, image: overlay, zIndex: 100)],
                    canvasBackground: .transparent)
                outputs.append(try #require(MemoMarkRenderedImageArtifactGuard.composingSourcePhoto(source, with: artifact)))
            }
            let labels = ["Baseline 0.42 / 0.78", "Candidate 0.56 / 0.96", "Candidate 0.62 / 0.78"]
            let height = 360 * size.height / size.width
            let comparison = HStack(alignment: .top, spacing: 12) {
                ForEach(outputs.indices, id: \.self) { index in
                    VStack(spacing: 8) {
                        Text(labels[index]).font(.system(size: 14)).foregroundStyle(.black)
                        Image(decorative: outputs[index], scale: 1).resizable()
                            .frame(width: 360, height: height)
                    }
                }
            }.padding(12).background(Color.white)
            let renderer = ImageRenderer(content: comparison)
            renderer.scale = 1
            Attachment.record(try png(try #require(renderer.cgImage)), named: "calibration-\(orientation.rawValue)-comparison.png")
        }
    }

    private func png(_ image: CGImage) throws -> Data {
        let bytes = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(bytes, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        return bytes as Data
    }

    // Color-convert measured output into explicit sRGB; extrema in an H glyph
    // crop are a diagnostic upper bound, not a general glyph/background mask.
    private func luminances(_ image: CGImage) throws -> [Double] {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let context = try #require(CGContext(data: &bytes, width: image.width, height: image.height,
            bitsPerComponent: 8, bytesPerRow: image.width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        func linear(_ byte: UInt8) -> Double {
            let value = Double(byte) / 255
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return stride(from: 0, to: bytes.count, by: 4).map {
            0.2126 * linear(bytes[$0]) + 0.7152 * linear(bytes[$0 + 1]) + 0.0722 * linear(bytes[$0 + 2])
        }
    }
}
