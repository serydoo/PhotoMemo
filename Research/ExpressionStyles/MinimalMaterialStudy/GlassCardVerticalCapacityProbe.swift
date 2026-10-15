// Research-only landscape geometry candidate matrix.
import AppKit
import CoreGraphics
import Foundation
import SwiftUI
import ImageIO
import UniformTypeIdentifiers
import Testing
@testable import MemoMark

@Suite("GlassCard compatible vertical capacity")
struct GlassCardVerticalCapacityProbe {
    @Test("Compare landscape sizing, complete-string fit and native output")
    @MainActor
    func sizingMatrix() throws {
        var rows = ["mode,aspect,multiplier,language,repeats,slot,characters,outcome,displayFont,panelHeightFraction,capsuleAreaFraction"]
        for (aspect, size) in [("4x3", CGSize(width: 1440, height: 1080)), ("16x9", CGSize(width: 1920, height: 1080))] {
            for mode in ["proportional", "compatible"] {
            for multiplier: CGFloat in [1, 1.2, 1.4, size.width / size.height] {
                for (language, text) in [
                    ("zh", "第一次一起走过这条路，留下属于我们的回忆。"),
                    ("en", "Our first walk together, a memory to revisit."),
                    ("ja", "初めて一緒に歩いた道、大切な思い出を残す。"),
                    ("ko", "처음 함께 걸었던 길, 오래 간직할 추억.")
                ] {
                    for count in [1, 2, 4] {
                        let value = String(repeating: text, count: count)
                        let content = GlassCardContentProjection(leftTop: value, leftBottom: value, rightTop: value, rightBottom: value)
                        let baseline = GlassCardResolvedPresentation.resolve(content: content, canvasSize: size)
                        let plan = mode == "compatible"
                            ? compatiblePresentation(content: content, size: size, multiplier: multiplier)
                            : GlassCardResolvedPresentation.resolve(content: content, canvasSize: size, panelHeightMultiplier: multiplier)
                        if mode == "compatible" {
                            #expect(plan.geometry.leftTopFrame.minX == baseline.geometry.leftTopFrame.minX)
                            #expect(plan.geometry.leftTopFrame.width == baseline.geometry.leftTopFrame.width)
                            #expect(plan.geometry.rightTopFrame.width == baseline.geometry.rightTopFrame.width)
                            #expect(plan.geometry.badgeFrame.size == baseline.geometry.badgeFrame.size)
                            for index in plan.slots.indices {
                                #expect(plan.slots[index].text == baseline.slots[index].text)
                                if baseline.slots[index].fit.outcome == .fits {
                                    #expect(plan.slots[index].fit.outcome == .fits)
                                }
                                if multiplier == 1 {
                                    #expect(plan.geometry == baseline.geometry)
                                    #expect(plan.slots[index].fit == baseline.slots[index].fit)
                                }
                            }
                        }
                        let panel = plan.geometry.panelFrame
                        let radius = panel.height * GlassCardLayoutSpecification.layout.cornerRadiusToPanelHeight
                        let area = panel.width * panel.height - (4 - CGFloat.pi) * radius * radius
                        #expect(plan.geometry.leftTopFrame.maxX < plan.geometry.badgeFrame.minX)
                        #expect(plan.geometry.badgeFrame.maxX < plan.geometry.dividerFrame.minX)
                        #expect(plan.geometry.dividerFrame.maxX < plan.geometry.rightTopFrame.minX)
                        for (index, slot) in plan.slots.enumerated() {
                            rows.append("\(mode),\(aspect),\(multiplier),\(language),\(count),\(index),\(value.count),\(slot.fit.outcome),\(slot.fit.pointSize * 360 / size.width),\(panel.height / size.height),\(area / (size.width * size.height))")
                        }
                    }
                }
            }
        }
        }
        #expect(rows.count == 769)
        Attachment.record(Data(rows.joined(separator: "\n").utf8), named: "vertical-capacity.csv")
        let orientation = ConfigurationPreviewBackground.Orientation.landscape
        let source = try #require(NSImage(named: ConfigurationPreviewBackground.minimal.assetName(forOrientation: orientation))?
            .cgImage(forProposedRect: nil, context: nil, hints: nil))
        let size = try #require(ConfigurationPreviewBackground.glassCardPixelSize(for: orientation))
        var outputs: [CGImage] = []
        let factors: [CGFloat] = [1, 1.2, 1.4, size.width / size.height]
        for factor in factors {
            let plan = compatiblePresentation(content: .init(leftTop: "一起走过的秋天", leftBottom: "相伴第365天",
                rightTop: "2026.10.01", rightBottom: "今天，也值得记住"), size: size, multiplier: factor)
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
                    Text("Compatible vertical multiplier \(String(format: "%.3f", Double(factors[index])))").font(.system(size: 14)).foregroundStyle(.black)
                    Image(decorative: outputs[index], scale: 1).resizable().frame(width: 600, height: 600 * size.height / size.width)
                }
            }
        }.padding(12).background(Color.white)
        let renderer = ImageRenderer(content: comparison)
        renderer.scale = 1
        Attachment.record(try png(try #require(renderer.cgImage)), named: "vertical-capacity-comparison.png")
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
