// Research-only native output raster downsampling, not a UIKit acceptance test.
import AppKit
import CoreGraphics
import Foundation
import SwiftUI
import ImageIO
import UniformTypeIdentifiers
import Testing
@testable import MemoMark

@Suite("GlassCard output downsampling")
struct GlassCardOutputDownsamplingProbe {
    @Test("Measure full-size output glyph survival at explicit display densities")
    @MainActor
    func displayMatrix() throws {
        var rows = ["orientation,fixture,displayWidth,rasterDensity,slot,fittedDisplayFont,maxRelativeCoverage,pixels75,pixels90"]
        for (orientation, size) in [
            ("portrait3x4", CGSize(width: 1080, height: 1440)),
            ("landscape4x3", CGSize(width: 1440, height: 1080)),
            ("portrait9x16", CGSize(width: 1080, height: 1920)),
            ("landscape16x9", CGSize(width: 1920, height: 1080))
        ] {
            for (fixture, text) in [("H", "HHHHHH"), ("zh", "相伴365天")] {
                let plan = GlassCardResolvedPresentation.resolve(content: .init(leftTop: text, leftBottom: text, rightTop: text, rightBottom: text), canvasSize: size)
                #expect(!plan.isContentOverflowing)
                let base = GlassCardProductionRenderer.recipe
                let clear = GlassCardMaterialRecipe.RGBA(red: 0, green: 0, blue: 0, alpha: 0)
                let maskRecipe = GlassCardMaterialRecipe(researchID: "display-mask", surface: clear, keyline: clear, shadow: clear,
                    keylineWidthToPanelHeight: base.keylineWidthToPanelHeight, shadowRadiusToPanelHeight: base.shadowRadiusToPanelHeight,
                    shadowOffsetToPanelHeight: base.shadowOffsetToPanelHeight)
                let maskRenderer = ImageRenderer(content: GlassCardOverlayLayer(presentation: plan, badge: nil,
                    recipe: maskRecipe, secondaryTextOpacity: 0.96))
                maskRenderer.scale = 1
                maskRenderer.proposedSize = .init(size)
                let mask = try #require(maskRenderer.cgImage)
                let candidate = GlassCardMaterialRecipe(researchID: "display-candidate", surface: .init(red: 0, green: 0, blue: 0, alpha: 0.56),
                    keyline: base.keyline, shadow: base.shadow, keylineWidthToPanelHeight: base.keylineWidthToPanelHeight,
                    shadowRadiusToPanelHeight: base.shadowRadiusToPanelHeight, shadowOffsetToPanelHeight: base.shadowOffsetToPanelHeight)
                let overlay = try layer(plan, recipe: candidate, opacity: 0.96)
                let artifact = try PresentationArtifact(canvasSize: size, photoFrame: CGRect(origin: .zero, size: size),
                    layers: [.init(frame: plan.artifactOverlayFrame, image: overlay, zIndex: 100)], canvasBackground: .transparent)
                let source = try ImageEdgeAssertionSupport.solidImage(width: Int(size.width), height: Int(size.height), red: 255, green: 255, blue: 255)
                let output = try #require(MemoMarkRenderedImageArtifactGuard.composingSourcePhoto(source, with: artifact))
                for displayWidth: CGFloat in [320, 360, 600] {
                    for density: CGFloat in [1, 3] {
                        let scale = displayWidth * density / size.width
                        let target = CGSize(width: displayWidth * density, height: (size.height * scale).rounded())
                        let scaledMask = try resize(mask, size: target)
                        for (index, slot) in plan.slots.enumerated() {
                            let sourceRect = slot.frame.offsetBy(dx: plan.geometry.panelFrame.minX, dy: plan.geometry.panelFrame.minY)
                            let rect = CGRect(x: sourceRect.minX * scale, y: sourceRect.minY * scale,
                                width: sourceRect.width * scale, height: sourceRect.height * scale).integral
                                .intersection(CGRect(origin: .zero, size: target))
                            let bytes = try rgba(try #require(scaledMask.cropping(to: rect)))
                            let alphas = stride(from: 3, to: bytes.count, by: 4).map { Double(bytes[$0]) / (255 * 0.96) }
                            let maximum = try #require(alphas.max())
                            rows.append("\(orientation),\(fixture),\(Int(displayWidth)),\(Int(density)),\(index),\(slot.fit.pointSize * displayWidth / size.width),\(maximum),\(alphas.filter { $0 >= 0.75 }.count),\(alphas.filter { $0 >= 0.90 }.count)")
                        }
                        if fixture == "zh" && displayWidth == 360 && density == 1 {
                            let scaled = try resize(output, size: target)
                            let panel = plan.geometry.panelFrame
                            let crop = CGRect(x: 0, y: max(0, floor(panel.minY * scale - 4)), width: target.width,
                                height: target.height - max(0, floor(panel.minY * scale - 4)))
                            Attachment.record(try png(try #require(scaled.cropping(to: crop))), named: "downsample-\(orientation)-360-1x.png")
                        }
                    }
                }
            }
        }
        #expect(rows.count == 193)
        Attachment.record(Data(rows.joined(separator: "\n").utf8), named: "output-downsampling.csv")
    }

    private func resize(_ image: CGImage, size: CGSize) throws -> CGImage {
        let context = try #require(CGContext(data: nil, width: Int(size.width), height: Int(size.height),
            bitsPerComponent: 8, bytesPerRow: Int(size.width) * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(origin: .zero, size: size))
        return try #require(context.makeImage())
    }

    @MainActor
    private func layer(_ plan: GlassCardResolvedPresentation, recipe: GlassCardMaterialRecipe, opacity: Double) throws -> CGImage {
        let frame = plan.overlayFrame
        let renderer = ImageRenderer(content: GlassCardOverlayLayer(presentation: plan, badge: nil,
            recipe: recipe, secondaryTextOpacity: opacity).offset(y: -frame.minY)
            .frame(width: frame.width, height: frame.height, alignment: .topLeading).clipped())
        renderer.scale = 1
        renderer.proposedSize = .init(frame.size)
        return try #require(renderer.cgImage)
    }

    private func rgba(_ image: CGImage) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let context = try #require(CGContext(data: &bytes, width: image.width, height: image.height,
            bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return bytes
    }

    private func png(_ image: CGImage) throws -> Data {
        let bytes = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(bytes, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        return bytes as Data
    }

}
