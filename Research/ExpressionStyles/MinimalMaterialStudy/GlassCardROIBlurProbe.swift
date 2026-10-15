// Research-only source-aware ROI study. Production compositor remains unchanged.
import AppKit
import CoreGraphics
import CoreImage
import Foundation
import SwiftUI
import ImageIO
import UniformTypeIdentifiers
import Testing
@testable import MemoMark

@Suite("GlassCard ROI blur")
struct GlassCardROIBlurProbe {
    @Test("Measure bounded source detail suppression with outside-panel and halo controls")
    @MainActor
    func roiBlur() throws {
        let size = CGSize(width: 1920, height: 1080)
        let plan = compatiblePresentation(content: .init(leftTop: "HHHHHH", leftBottom: "HHHHHH", rightTop: "HHHHHH", rightBottom: "HHHHHH"), size: size, multiplier: 1.4)
        let empty = compatiblePresentation(content: .init(leftTop: "", leftBottom: "", rightTop: "", rightBottom: ""), size: size, multiplier: 1.4)
        let base = GlassCardProductionRenderer.recipe
        let clear = GlassCardMaterialRecipe.RGBA(red: 0, green: 0, blue: 0, alpha: 0)
        func recipe(_ mask: Bool) -> GlassCardMaterialRecipe {
            .init(researchID: "roi-blur", surface: mask ? clear : .init(red: 0, green: 0, blue: 0, alpha: 0.56),
                keyline: mask ? clear : base.keyline, shadow: mask ? clear : base.shadow,
                keylineWidthToPanelHeight: base.keylineWidthToPanelHeight, shadowRadiusToPanelHeight: base.shadowRadiusToPanelHeight,
                shadowOffsetToPanelHeight: base.shadowOffsetToPanelHeight)
        }
        let ink = try layer(plan, recipe: recipe(false), opacity: 0.96)
        let backing = try layer(empty, recipe: recipe(false), opacity: 0.96)
        let mask = try layer(plan, recipe: recipe(true), opacity: 0.96)
        var rows = ["pattern,radius,haloBytes,slot,corePixels,minimum,p10,backgroundStdDev,horizontalDifference,haloMaxByteDifference,outsideMaxByteDifference"]
        for pattern in ["white", "bright-checker", "full-checker", "fine-stripes", "gradient"] {
            let source = pattern == "white" ? try ImageEdgeAssertionSupport.solidImage(width: 1920, height: 1080, red: 255, green: 255, blue: 255)
                : try texture(size: size, pattern: pattern)
            for fraction: CGFloat in [0, 0.025, 0.05, 0.10] {
                let radius = plan.geometry.panelFrame.height * fraction
                let result = try blurredSource(source, panel: plan.geometry.panelFrame, radius: radius)
                #expect(result.outsideDifference == 0)
                #expect(result.haloDifference <= 1)
                if pattern == "white" {
                    let original = try rgba(source), filtered = try rgba(result.image)
                    #expect(zip(original, filtered).map { abs(Int($0) - Int($1)) }.max()! <= 1)
                }
                func composite(_ layer: CGImage) throws -> CGImage {
                    let artifact = try PresentationArtifact(canvasSize: size, photoFrame: CGRect(origin: .zero, size: size),
                        layers: [.init(frame: plan.artifactOverlayFrame, image: layer, zIndex: 100)], canvasBackground: .transparent)
                    return try #require(MemoMarkRenderedImageArtifactGuard.composingSourcePhoto(result.image, with: artifact))
                }
                let output = try composite(ink), background = try composite(backing)
                for (index, slot) in plan.slots.enumerated() {
                    let region = slot.frame.offsetBy(dx: plan.geometry.panelFrame.minX, dy: plan.geometry.panelFrame.minY).integral
                    let front = try rgba(try #require(output.cropping(to: region)))
                    let backImage = try #require(background.cropping(to: region))
                    let back = try rgba(backImage)
                    let maskBytes = try rgba(try #require(mask.cropping(to: region.offsetBy(dx: 0, dy: -plan.overlayFrame.minY))))
                    #expect(front.count == back.count && back.count == maskBytes.count)
                    var contrasts: [Double] = []
                    let lumas = stride(from: 0, to: back.count, by: 4).map { luma(back, $0) }
                    let mean = lumas.reduce(0, +) / Double(lumas.count)
                    let deviation = sqrt(lumas.map { pow($0 - mean, 2) }.reduce(0, +) / Double(lumas.count))
                    var differences: [Double] = []
                    for y in 0..<backImage.height {
                        for x in 1..<backImage.width {
                            differences.append(abs(lumas[y * backImage.width + x] - lumas[y * backImage.width + x - 1]))
                        }
                    }
                    for pixel in stride(from: 0, to: front.count, by: 4) where Double(maskBytes[pixel+3]) >= 0.90 * 0.96 * 255 {
                        let f = luma(front, pixel), b = luma(back, pixel)
                        contrasts.append((max(f,b)+0.05)/(min(f,b)+0.05))
                    }
                    contrasts.sort()
                    #expect(!contrasts.isEmpty)
                    rows.append("\(pattern),\(radius),\(result.haloBytes),\(index),\(contrasts.count),\(try #require(contrasts.first)),\(contrasts[Int(Double(contrasts.count-1)*0.1)]),\(deviation),\(differences.reduce(0,+)/Double(differences.count)),\(result.haloDifference),\(result.outsideDifference)")
                }
                if pattern == "bright-checker" {
                    Attachment.record(try png(try #require(output.cropping(to: plan.geometry.panelFrame.integral))), named: "roi-radius-\(String(format: "%.2f", Double(radius)))-rail.png")
                }
            }
        }
        #expect(rows.count == 81)
        Attachment.record(Data(rows.joined(separator: "\n").utf8), named: "roi-blur.csv")
    }

    @Test("Compare bounded blur on the locally bundled calibration photograph")
    @MainActor
    func calibrationBlur() throws {
        let orientation = ConfigurationPreviewBackground.Orientation.landscape
        let raw = try #require(NSImage(named: ConfigurationPreviewBackground.minimal.assetName(forOrientation: orientation))?
            .cgImage(forProposedRect: nil, context: nil, hints: nil))
        let size = try #require(ConfigurationPreviewBackground.glassCardPixelSize(for: orientation))
        // Explicit research normalization to the encoder-safe canvas; the bundled file is untouched.
        let context = try #require(CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8,
            bytesPerRow: Int(size.width)*4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        context.interpolationQuality = .high
        context.draw(raw, in: CGRect(origin: .zero, size: size))
        let source = try #require(context.makeImage())
        let plan = compatiblePresentation(content: .init(leftTop: "一起走过的秋天", leftBottom: "相伴第365天",
            rightTop: "2026.10.01", rightBottom: "今天，也值得记住"), size: size, multiplier: 1.4)
        #expect(!plan.isContentOverflowing)
        let base = GlassCardProductionRenderer.recipe
        let recipe = GlassCardMaterialRecipe(researchID: "roi-calibration", surface: .init(red: 0, green: 0, blue: 0, alpha: 0.56),
            keyline: base.keyline, shadow: base.shadow, keylineWidthToPanelHeight: base.keylineWidthToPanelHeight,
            shadowRadiusToPanelHeight: base.shadowRadiusToPanelHeight, shadowOffsetToPanelHeight: base.shadowOffsetToPanelHeight)
        let overlay = try layer(plan, recipe: recipe, opacity: 0.96)
        var outputs: [CGImage] = []
        var evidence: [[String: Double]] = []
        for radius in [CGFloat.zero, plan.geometry.panelFrame.height * 0.025] {
            let result = try blurredSource(source, panel: plan.geometry.panelFrame, radius: radius)
            #expect(result.outsideDifference == 0)
            #expect(result.haloDifference <= 1)
            let artifact = try PresentationArtifact(canvasSize: size, photoFrame: CGRect(origin: .zero, size: size),
                layers: [.init(frame: plan.artifactOverlayFrame, image: overlay, zIndex: 100)], canvasBackground: .transparent)
            outputs.append(try #require(MemoMarkRenderedImageArtifactGuard.composingSourcePhoto(result.image, with: artifact)))
            evidence.append(["radius":Double(radius),"haloRGBABytes":Double(result.haloBytes),
                "haloMaxByteDifference":Double(result.haloDifference),"outsideMaxByteDifference":Double(result.outsideDifference)])
        }
        let comparison = VStack(spacing: 12) {
            ForEach(outputs.indices, id: \.self) { index in
                VStack(spacing: 6) {
                    Text(index == 0 ? "Fixed material, no blur" : "Same material, bounded ROI blur")
                        .font(.system(size: 14)).foregroundStyle(.black)
                    Image(decorative: outputs[index], scale: 1).resizable().frame(width: 600, height: 600*size.height/size.width)
                }
            }
        }.padding(12).background(Color.white)
        let renderer = ImageRenderer(content: comparison)
        renderer.scale = 1
        Attachment.record(try png(try #require(renderer.cgImage)), named: "roi-calibration-comparison.png")
        Attachment.record(try JSONSerialization.data(withJSONObject: evidence, options: [.prettyPrinted,.sortedKeys]), named: "roi-calibration-controls.json")
    }

    private func blurredSource(_ source: CGImage, panel: CGRect, radius: CGFloat) throws -> (image: CGImage, haloBytes: Int, haloDifference: Int, outsideDifference: Int) {
        if radius == 0 { return (source, 0, 0, 0) }
        let bounds = CGRect(x: 0, y: 0, width: source.width, height: source.height)
        let halo = ceil(4 * radius + 2)
        let crop = panel.insetBy(dx: -halo, dy: -halo).integral.intersection(bounds)
        let patch = try #require(source.cropping(to: crop))
        let color = CGColorSpace(name: CGColorSpace.sRGB)!
        let ciContext = CIContext(options: [.workingColorSpace: color, .outputColorSpace: color, .cacheIntermediates: false])
        func blurred(_ image: CGImage) -> CIImage {
            CIImage(cgImage: image).clampedToExtent().applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: radius])
        }
        let patchExtent = CGRect(x: 0, y: 0, width: patch.width, height: patch.height)
        let filtered = try #require(ciContext.createCGImage(blurred(patch), from: patchExtent, format: .RGBA8, colorSpace: color))
        let worldCrop = CGRect(x: crop.minX, y: bounds.height-crop.maxY, width: crop.width, height: crop.height)
        let reference = try #require(ciContext.createCGImage(blurred(source), from: worldCrop, format: .RGBA8, colorSpace: color))
        let a = try rgba(filtered), b = try rgba(reference)
        let interior = panel.offsetBy(dx: -crop.minX, dy: -crop.minY).integral
        var haloDifference = 0
        for y in Int(interior.minY)..<Int(interior.maxY) {
            for x in Int(interior.minX)..<Int(interior.maxX) {
                let i = (y * patch.width + x) * 4
                for channel in 0..<3 { haloDifference = max(haloDifference, abs(Int(a[i+channel])-Int(b[i+channel]))) }
            }
        }
        func context() throws -> CGContext {
            try #require(CGContext(data: nil, width: source.width, height: source.height, bitsPerComponent: 8, bytesPerRow: source.width*4,
                space: color, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        }
        let target = try context()
        target.draw(source, in: bounds)
        let panelBottom = CGRect(x: panel.minX, y: bounds.height-panel.maxY, width: panel.width, height: panel.height)
        let path = CGPath(roundedRect: panelBottom, cornerWidth: panel.height/2, cornerHeight: panel.height/2, transform: nil)
        target.saveGState(); target.addPath(path); target.clip()
        target.draw(filtered, in: worldCrop); target.restoreGState()
        let result = try #require(target.makeImage())
        let panelMask = try context()
        panelMask.addPath(path); panelMask.setFillColor(CGColor(gray: 1, alpha: 1)); panelMask.fillPath()
        let coverage = try rgba(try #require(panelMask.makeImage()))
        let original = try rgba(source), processed = try rgba(result)
        var outsideDifference = 0
        for i in stride(from: 0, to: original.count, by: 4) where coverage[i+3] == 0 {
            for channel in 0..<4 { outsideDifference = max(outsideDifference, abs(Int(original[i+channel])-Int(processed[i+channel]))) }
        }
        return (result, patch.width*patch.height*4, haloDifference, outsideDifference)
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
