// Research-only candidate output/display diagnostics. No production policy changes.
import AppKit
import CoreGraphics
import Foundation
import SwiftUI
import ImageIO
import UniformTypeIdentifiers
import Testing
@testable import MemoMark

@Suite("GlassCard vertical candidate display")
struct GlassCardVerticalDisplayProbe {
    @Test("Compare candidate glyph retention and paired contrast after actual output resizing")
    @MainActor
    func candidateDisplay() throws {
        var rows = ["aspect,multiplier,fixture,displayWidth,rasterDensity,pattern,slot,displayFont,corePixels90,maxNormalizedAlpha,sampledInkMass,pixels50,minimum,p10,median"]
        for (aspect, size) in [("4x3", CGSize(width: 1440, height: 1080)), ("16x9", CGSize(width: 1920, height: 1080))] {
            for factor: CGFloat in [1, 1.2, 1.4] {
                for (fixture, text) in [("H", "HHHHHH"), ("zh", "相伴365天")] {
                    let plan = compatiblePresentation(content: .init(leftTop: text, leftBottom: text, rightTop: text, rightBottom: text), size: size, multiplier: factor)
                    let empty = compatiblePresentation(content: .init(leftTop: "", leftBottom: "", rightTop: "", rightBottom: ""), size: size, multiplier: factor)
                    #expect(!plan.isContentOverflowing)
                    let base = GlassCardProductionRenderer.recipe
                    let clear = GlassCardMaterialRecipe.RGBA(red: 0, green: 0, blue: 0, alpha: 0)
                    func recipe(mask: Bool) -> GlassCardMaterialRecipe {
                        .init(researchID: "candidate-display", surface: mask ? clear : .init(red: 0, green: 0, blue: 0, alpha: 0.56),
                            keyline: mask ? clear : base.keyline, shadow: mask ? clear : base.shadow,
                            keylineWidthToPanelHeight: base.keylineWidthToPanelHeight,
                            shadowRadiusToPanelHeight: base.shadowRadiusToPanelHeight,
                            shadowOffsetToPanelHeight: base.shadowOffsetToPanelHeight)
                    }
                    let maskRenderer = ImageRenderer(content: GlassCardOverlayLayer(presentation: plan, badge: nil,
                        recipe: recipe(mask: true), secondaryTextOpacity: 0.96))
                    maskRenderer.scale = 1
                    maskRenderer.proposedSize = .init(size)
                    let mask = try #require(maskRenderer.cgImage)
                    let ink = try layer(plan, recipe: recipe(mask: false), opacity: 0.96)
                    let backing = try layer(empty, recipe: recipe(mask: false), opacity: 0.96)
                    for pattern in ["white", "bright-checker"] {
                        let source = pattern == "white"
                            ? try ImageEdgeAssertionSupport.solidImage(width: Int(size.width), height: Int(size.height), red: 255, green: 255, blue: 255)
                            : try texture(size: size, pattern: pattern)
                        func composite(_ layer: CGImage) throws -> CGImage {
                            let artifact = try PresentationArtifact(canvasSize: size, photoFrame: CGRect(origin: .zero, size: size),
                                layers: [.init(frame: plan.artifactOverlayFrame, image: layer, zIndex: 100)], canvasBackground: .transparent)
                            return try #require(MemoMarkRenderedImageArtifactGuard.composingSourcePhoto(source, with: artifact))
                        }
                        let output = try composite(ink), background = try composite(backing)
                        for width: CGFloat in [320, 360, 600] {
                            for density: CGFloat in [1, 3] {
                                let scale = width * density / size.width
                                let target = CGSize(width: width * density, height: (size.height * scale).rounded())
                                let sampledMask = try resize(mask, size: target)
                                let sampledOutput = try resize(output, size: target)
                                let sampledBackground = try resize(background, size: target)
                                for (index, slot) in plan.slots.enumerated() {
                                    let frame = slot.frame.offsetBy(dx: plan.geometry.panelFrame.minX, dy: plan.geometry.panelFrame.minY)
                                    let region = CGRect(x: frame.minX * scale, y: frame.minY * scale, width: frame.width * scale, height: frame.height * scale)
                                        .integral.intersection(CGRect(origin: .zero, size: target))
                                    let maskBytes = try rgba(try #require(sampledMask.cropping(to: region)))
                                    let front = try rgba(try #require(sampledOutput.cropping(to: region)))
                                    let back = try rgba(try #require(sampledBackground.cropping(to: region)))
                                    #expect(maskBytes.count == front.count && front.count == back.count)
                                    let maskValues = stride(from: 3, to: maskBytes.count, by: 4).map { Double(maskBytes[$0]) / (255 * 0.96) }
                                    var contrasts: [Double] = []
                                    for pixel in stride(from: 0, to: front.count, by: 4) where Double(maskBytes[pixel + 3]) >= 0.90 * 0.96 * 255 {
                                        let f = luma(front, pixel), b = luma(back, pixel)
                                        contrasts.append((max(f, b) + 0.05) / (min(f, b) + 0.05))
                                    }
                                    contrasts.sort()
                                    let minimum = contrasts.first.map { String($0) } ?? "NA"
                                    let p10 = contrasts.isEmpty ? "NA" : String(contrasts[Int(Double(contrasts.count - 1) * 0.10)])
                                    let median = contrasts.isEmpty ? "NA" : String(contrasts[contrasts.count / 2])
                                    rows.append("\(aspect),\(factor),\(fixture),\(Int(width)),\(Int(density)),\(pattern),\(index),\(slot.fit.pointSize * width / size.width),\(contrasts.count),\(try #require(maskValues.max())),\(maskValues.reduce(0, +) / Double(density * density)),\(maskValues.filter { $0 >= 0.50 }.count),\(minimum),\(p10),\(median)")
                                }
                                if aspect == "16x9" && fixture == "zh" && width == 360 && density == 1 {
                                    let top = max(0, floor(plan.geometry.panelFrame.minY * scale - 4))
                                    let crop = CGRect(x: 0, y: top, width: target.width, height: target.height - top)
                                    Attachment.record(try png(try #require(sampledOutput.cropping(to: crop))), named: "display-m\(factor)-\(pattern)-360-1x.png")
                                }
                            }
                        }
                    }
                }
            }
        }
        #expect(rows.count == 577)
        Attachment.record(Data(rows.joined(separator: "\n").utf8), named: "vertical-display.csv")
    }

    private func resize(_ image: CGImage, size: CGSize) throws -> CGImage {
        let context = try #require(CGContext(data: nil, width: Int(size.width), height: Int(size.height),
            bitsPerComponent: 8, bytesPerRow: Int(size.width) * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(origin: .zero, size: size))
        return try #require(context.makeImage())
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

    // Experimental resolved input only. Production continues using the default Layout.
    private func compatiblePresentation(content: GlassCardContentProjection, size: CGSize, multiplier: CGFloat) -> GlassCardResolvedPresentation {
        let original = GlassCardLayoutSpecification.resolvedGeometry(canvasSize: size)
        let taller = GlassCardLayoutSpecification.resolvedGeometry(canvasSize: size, panelHeightMultiplier: multiplier)
        func row(_ horizontal: CGRect, _ vertical: CGRect) -> CGRect {
            CGRect(x: horizontal.minX, y: vertical.minY, width: horizontal.width, height: vertical.height)
        }
        let geometry = GlassCardLayoutSpecification.ResolvedGeometry(
            panelFrame: taller.panelFrame,
            leftTopFrame: row(original.leftTopFrame, taller.leftTopFrame),
            leftBottomFrame: row(original.leftBottomFrame, taller.leftBottomFrame),
            badgeFrame: CGRect(x: original.badgeFrame.minX, y: (taller.panelFrame.height - original.badgeFrame.height) / 2,
                width: original.badgeFrame.width, height: original.badgeFrame.height),
            dividerFrame: CGRect(x: original.dividerFrame.minX, y: taller.dividerFrame.minY,
                width: original.dividerFrame.width, height: taller.dividerFrame.height),
            rightTopFrame: row(original.rightTopFrame, taller.rightTopFrame),
            rightBottomFrame: row(original.rightBottomFrame, taller.rightBottomFrame)
        )
        let layout = GlassCardLayoutSpecification.layout
        let values: [(String, CGRect, Bool)] = [(content.leftTop, geometry.leftTopFrame, true),
            (content.leftBottom, geometry.leftBottomFrame, false), (content.rightTop, geometry.rightTopFrame, true),
            (content.rightBottom, geometry.rightBottomFrame, false)]
        let actualMultiplier = taller.panelFrame.height / original.panelFrame.height
        return GlassCardResolvedPresentation(canvasSize: size, geometry: geometry, slots: values.map { text, frame, primary in
            let pointSize = taller.panelFrame.height * (primary ? layout.primaryFontToPanelHeight : layout.secondaryFontToPanelHeight) * (primary ? 1.12 : 1.04)
            let minimumScale = (primary ? 0.72 : 0.70) / actualMultiplier
            return .init(text: text, frame: frame, isPrimary: primary,
                fit: GlassCardTextFitSpecification.resolve(text: text, frame: frame.size, pointSize: pointSize,
                    isPrimary: primary, lineLimit: 1, minimumScale: minimumScale))
        }, isEmpty: content.isEmpty)
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

    private func png(_ image: CGImage) throws -> Data {
        let bytes = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(bytes, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        return bytes as Data
    }

}
