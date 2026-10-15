// Research-only landscape geometry candidate matrix.
import AppKit
import CoreGraphics
import Foundation
import SwiftUI
import ImageIO
import UniformTypeIdentifiers
import Testing
@testable import MemoMark

@Suite("GlassCard landscape sizing")
struct GlassCardLandscapeSizingProbe {
    @Test("Compare landscape sizing, complete-string fit and native output")
    @MainActor
    func sizingMatrix() throws {
        var rows = ["aspect,multiplier,language,repeats,slot,characters,outcome,displayFont,panelHeightFraction,capsuleAreaFraction"]
        for (aspect, size) in [("4x3", CGSize(width: 1440, height: 1080)), ("16x9", CGSize(width: 1920, height: 1080))] {
            for multiplier: CGFloat in [1, 1.2, 1.4, size.width / size.height] {
                for (language, text) in [
                    ("zh", "第一次一起走过这条路，留下属于我们的回忆。"),
                    ("en", "Our first walk together, a memory to revisit."),
                    ("ja", "初めて一緒に歩いた道、大切な思い出を残す。"),
                    ("ko", "처음 함께 걸었던 길, 오래 간직할 추억.")
                ] {
                    for count in [1, 2, 4] {
                        let value = String(repeating: text, count: count)
                        let plan = GlassCardResolvedPresentation.resolve(content: .init(leftTop: value, leftBottom: value,
                            rightTop: value, rightBottom: value), canvasSize: size, panelHeightMultiplier: multiplier)
                        let panel = plan.geometry.panelFrame
                        let radius = panel.height * GlassCardLayoutSpecification.layout.cornerRadiusToPanelHeight
                        let area = panel.width * panel.height - (4 - CGFloat.pi) * radius * radius
                        #expect(plan.geometry.leftTopFrame.maxX < plan.geometry.badgeFrame.minX)
                        #expect(plan.geometry.badgeFrame.maxX < plan.geometry.dividerFrame.minX)
                        #expect(plan.geometry.dividerFrame.maxX < plan.geometry.rightTopFrame.minX)
                        for (index, slot) in plan.slots.enumerated() {
                            rows.append("\(aspect),\(multiplier),\(language),\(count),\(index),\(value.count),\(slot.fit.outcome),\(slot.fit.pointSize * 360 / size.width),\(panel.height / size.height),\(area / (size.width * size.height))")
                        }
                    }
                }
            }
        }
        #expect(rows.count == 385)
        Attachment.record(Data(rows.joined(separator: "\n").utf8), named: "landscape-sizing.csv")
        let orientation = ConfigurationPreviewBackground.Orientation.landscape
        let source = try #require(NSImage(named: ConfigurationPreviewBackground.minimal.assetName(forOrientation: orientation))?
            .cgImage(forProposedRect: nil, context: nil, hints: nil))
        let size = try #require(ConfigurationPreviewBackground.glassCardPixelSize(for: orientation))
        var outputs: [CGImage] = []
        let factors: [CGFloat] = [1, 1.2, 1.4, size.width / size.height]
        for factor in factors {
            let plan = GlassCardResolvedPresentation.resolve(content: .init(leftTop: "一起走过的秋天", leftBottom: "相伴第365天",
                rightTop: "2026.10.01", rightBottom: "今天，也值得记住"), canvasSize: size, panelHeightMultiplier: factor)
            #expect(!plan.isContentOverflowing)
            let base = GlassCardProductionRenderer.recipe
            let recipe = GlassCardMaterialRecipe(researchID: "sizing-comparison", surface: .init(red: 0, green: 0, blue: 0, alpha: 0.56),
                keyline: base.keyline, shadow: base.shadow, keylineWidthToPanelHeight: base.keylineWidthToPanelHeight,
                shadowRadiusToPanelHeight: base.shadowRadiusToPanelHeight, shadowOffsetToPanelHeight: base.shadowOffsetToPanelHeight)
            let overlay = try layer(plan, recipe: recipe, opacity: 0.96)
            let artifact = try PresentationArtifact(canvasSize: size, photoFrame: CGRect(origin: .zero, size: size),
                layers: [.init(frame: plan.artifactOverlayFrame, image: overlay, zIndex: 100)], canvasBackground: .transparent)
            outputs.append(try #require(MemoMarkRenderedImageArtifactGuard.composingSourcePhoto(source, with: artifact)))
        }
        let comparison = VStack(spacing: 12) {
            ForEach(outputs.indices, id: \.self) { index in
                VStack(spacing: 6) {
                    Text("Panel multiplier \(String(format: "%.3f", Double(factors[index])))").font(.system(size: 14)).foregroundStyle(.black)
                    Image(decorative: outputs[index], scale: 1).resizable().frame(width: 600, height: 600 * size.height / size.width)
                }
            }
        }.padding(12).background(Color.white)
        let renderer = ImageRenderer(content: comparison)
        renderer.scale = 1
        Attachment.record(try png(try #require(renderer.cgImage)), named: "landscape-sizing-comparison.png")
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
