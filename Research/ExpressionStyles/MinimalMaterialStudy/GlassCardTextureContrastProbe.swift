// Research-only paired-pixel measurement. No production defaults change.
import AppKit
import CoreGraphics
import Foundation
import SwiftUI
import ImageIO
import UniformTypeIdentifiers
import Testing
@testable import MemoMark

@Suite("GlassCard texture contrast")
struct GlassCardTextureContrastProbe {
    @Test("Measure glyph-core contrast against the same background coordinates")
    @MainActor
    func pairedPixelContrast() throws {
        var rows = ["shortEdge,pattern,surfaceAlpha,secondaryOpacity,slot,maskFraction,corePixels,minimum,p10,median"]
        for edge: CGFloat in [360, 1080] {
            let size = CGSize(width: edge, height: edge * 4 / 3)
            let content = GlassCardContentProjection(leftTop: "HHHHHH", leftBottom: "HHHHHH", rightTop: "HHHHHH", rightBottom: "HHHHHH")
            let plan = GlassCardResolvedPresentation.resolve(content: content, canvasSize: size)
            let empty = GlassCardResolvedPresentation.resolve(content: .init(leftTop: "", leftBottom: "", rightTop: "", rightBottom: ""), canvasSize: size)
            for (alpha, opacity) in [(0.42, 0.78), (0.56, 0.96), (0.62, 0.78)] {
                let base = GlassCardProductionRenderer.recipe
                func recipe(_ mask: Bool) -> GlassCardMaterialRecipe {
                    let clear = GlassCardMaterialRecipe.RGBA(red: 0, green: 0, blue: 0, alpha: 0)
                    return .init(researchID: "texture-probe", surface: mask ? clear : .init(red: 0, green: 0, blue: 0, alpha: alpha),
                        keyline: mask ? clear : base.keyline, shadow: mask ? clear : base.shadow,
                        keylineWidthToPanelHeight: base.keylineWidthToPanelHeight,
                        shadowRadiusToPanelHeight: base.shadowRadiusToPanelHeight,
                        shadowOffsetToPanelHeight: base.shadowOffsetToPanelHeight)
                }
                let ink = try layer(plan, recipe: recipe(false), opacity: opacity)
                let backing = try layer(empty, recipe: recipe(false), opacity: opacity)
                let mask = try layer(plan, recipe: recipe(true), opacity: opacity)
                for pattern in ["bright-checker", "full-checker", "fine-stripes", "gradient"] {
                    let source = try texture(size: size, pattern: pattern)
                    func composite(_ image: CGImage) throws -> CGImage {
                        let artifact = try PresentationArtifact(canvasSize: size, photoFrame: CGRect(origin: .zero, size: size),
                            layers: [.init(frame: plan.artifactOverlayFrame, image: image, zIndex: 100)], canvasBackground: .transparent)
                        return try #require(MemoMarkRenderedImageArtifactGuard.composingSourcePhoto(source, with: artifact))
                    }
                    let output = try composite(ink)
                    let background = try composite(backing)
                    for (index, slot) in plan.slots.enumerated() {
                        let region = slot.frame.offsetBy(dx: plan.geometry.panelFrame.minX, dy: plan.geometry.panelFrame.minY).integral
                        let maskRegion = region.offsetBy(dx: 0, dy: -plan.overlayFrame.minY)
                        let maskBytes = try rgba(try #require(mask.cropping(to: maskRegion)))
                        let front = try rgba(try #require(output.cropping(to: region)))
                        let back = try rgba(try #require(background.cropping(to: region)))
                        #expect(front.count == back.count && front.count == maskBytes.count)
                        for maskFraction in [0.75, 0.90] {
                        let threshold = maskFraction * (slot.isPrimary ? 0.96 : opacity) * 255
                        var contrasts: [Double] = []
                        for pixel in stride(from: 0, to: front.count, by: 4) where Double(maskBytes[pixel + 3]) >= threshold {
                            let f = luma(front, pixel), b = luma(back, pixel)
                            contrasts.append((max(f, b) + 0.05) / (min(f, b) + 0.05))
                        }
                        contrasts.sort()
                        #expect(!contrasts.isEmpty)
                        let minimum = try #require(contrasts.first)
                        let p10 = contrasts[Int(Double(contrasts.count - 1) * 0.10)]
                        let median = contrasts[contrasts.count / 2]
                        rows.append("\(Int(edge)),\(pattern),\(alpha),\(opacity),\(index),\(maskFraction),\(contrasts.count),\(minimum),\(p10),\(median)")
                        }
                        if edge == 1080 && index == 0 && pattern == "bright-checker" {
                            Attachment.record(try png(try #require(output.cropping(to: region))), named: "texture-a\(alpha)-o\(opacity)-glyph-crop.png")
                        }
                    }
                }
            }
        }
        #expect(rows.count == 193)
        Attachment.record(Data(rows.joined(separator: "\n").utf8), named: "texture-contrast.csv")
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

    private func texture(size: CGSize, pattern: String) throws -> CGImage {
        let width = Int(size.width), height = Int(size.height)
        var bytes = [UInt8](repeating: 255, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let value: UInt8
                switch pattern {
                case "bright-checker": value = ((x / 8 + y / 8) % 2 == 0) ? 180 : 255
                case "full-checker": value = ((x / 8 + y / 8) % 2 == 0) ? 0 : 255
                case "fine-stripes": value = x % 4 < 2 ? 180 : 255
                default: value = UInt8(x * 255 / (width - 1))
                }
                let i = (y * width + x) * 4
                bytes[i] = value; bytes[i + 1] = value; bytes[i + 2] = value
            }
        }
        let provider = try #require(CGDataProvider(data: Data(bytes) as CFData))
        return try #require(CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent))
    }

    private func rgba(_ image: CGImage) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let context = try #require(CGContext(data: &bytes, width: image.width, height: image.height,
            bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return bytes
    }

    private func luma(_ bytes: [UInt8], _ i: Int) -> Double {
        func linear(_ b: UInt8) -> Double {
            let v = Double(b) / 255
            return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(bytes[i]) + 0.7152 * linear(bytes[i + 1]) + 0.0722 * linear(bytes[i + 2])
    }

    private func png(_ image: CGImage) throws -> Data {
        let bytes = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(bytes, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        return bytes as Data
    }

}
