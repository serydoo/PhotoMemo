// Research-only macOS test harness. Temporarily copy to RendererTests to run.
// A passing probe means measurements completed, not visual acceptance.
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import MemoMark

@Suite("GlassCard appearance measurements")
struct GlassCardAppearanceMeasurementProbe {
    @Test("Isolate system-font metrics at the minimum scale")
    func fontScaleMetrics() {
        var rows = ["language,shortEdge,fontName,pointSize,frameWidth,lineWidth,normalizedLineWidth,ascent,descent,leading,rowHeight"]
        for (language, value) in [("zh", "第一次一起走过这条路，留下属于我们的回忆。"), ("en", "Our first walk together, a memory to revisit.")] {
            for edge: CGFloat in [360, 1080, 4284] {
                let size = CGSize(width: edge, height: edge * 4 / 3)
                let geometry = GlassCardLayoutSpecification.resolvedGeometry(canvasSize: size)
                let pointSize = geometry.panelFrame.height * GlassCardLayoutSpecification.layout.primaryFontToPanelHeight * 1.12 * 0.72
                let font = GlassCardTextFitSpecification.font(pointSize: pointSize, isPrimary: true)
                let text = NSAttributedString(string: value, attributes: [kCTFontAttributeName as NSAttributedString.Key: font])
                let line = CTLineCreateWithAttributedString(text)
                var ascent: CGFloat = 0
                var descent: CGFloat = 0
                var leading: CGFloat = 0
                let width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
                rows.append("\(language),\(Int(edge)),\(CTFontCopyPostScriptName(font)),\(pointSize),\(geometry.leftTopFrame.width),\(width),\(width / edge),\(ascent),\(descent),\(leading),\(geometry.leftTopFrame.height)")
            }
        }
        Attachment.record(Data(rows.joined(separator: "\n").utf8), named: "font-scale-metrics.csv")
    }

    @Test("Measure actual fixed-material pixels over uniform SDR backgrounds")
    @MainActor
    func materialPixels() throws {
        var rows = ["width,height,sourceGray,slot,minLuminance,maxLuminance,peakPixelContrast,pointSize"]
        for size in [CGSize(width: 360, height: 480), CGSize(width: 1080, height: 1440)] {
            var template = Template.classicWhite
            template.leftTopArea.items = [.story]
            template.leftBottomArea.items = [.title]
            template.rightTopArea.items = [.story]
            template.rightBottomArea.items = [.title]
            let card = RecordCard(template: template, presentationStyle: .glassCard,
                metadata: PhotoMetadata(imageWidth: Int(size.width), imageHeight: Int(size.height)),
                context: MetadataContext(), title: "HHHHHH", story: "HHHHHH")
            let plan = GlassCardProductionRenderer.resolve(card: card, canvasSize: size)
            #expect(!plan.isContentOverflowing)
            let artifact = try RecordCardPresentationPlanner().artifact(for: card, canvasSize: size)
            Attachment.record(try png(artifact.layers[0].image), named: "overlay-\(Int(size.width)).png")
            for gray: UInt8 in [0, 128, 255] {
                let source = try ImageEdgeAssertionSupport.solidImage(width: Int(size.width), height: Int(size.height), red: gray, green: gray, blue: gray)
                let output = try #require(MemoMarkRenderedImageArtifactGuard.composingSourcePhoto(source, with: artifact))
                Attachment.record(try png(output), named: "composed-\(Int(size.width))-gray-\(gray).png")
                for (index, slot) in plan.slots.enumerated() {
                    let region = slot.frame.offsetBy(dx: plan.geometry.panelFrame.minX, dy: plan.geometry.panelFrame.minY).integral
                    let crop = try #require(output.cropping(to: region))
                    let lumas = try luminances(crop)
                    let low = try #require(lumas.min())
                    let high = try #require(lumas.max())
                    rows.append("\(Int(size.width)),\(Int(size.height)),\(gray),\(index),\(low),\(high),\((high + 0.05) / (low + 0.05)),\(slot.fit.pointSize)")
                }
            }
        }
        Attachment.record(Data(rows.joined(separator: "\n").utf8), named: "material-pixels.csv")
    }

    @Test("Measure multilingual complete-string fit across preview and output scales")
    func textFitMatrix() {
        let fixtures = [
            ("zh", "第一次一起走过这条路，留下属于我们的回忆。"),
            ("en", "Our first walk together, a memory to revisit."),
            ("ja", "初めて一緒に歩いた道、大切な思い出を残す。"),
            ("ko", "처음 함께 걸었던 길, 우리의 소중한 추억."),
            ("de", "Unser erster gemeinsamer Spaziergang bleibt in Erinnerung."),
            ("fr", "Notre première promenade ensemble, un souvenir précieux.")
        ]
        var rows = ["language,repetitions,orientation,shortEdge,slot,characters,outcome,pointSize,normalizedPointSize"]
        for (language, text) in fixtures {
            for count in 1...4 {
                let value = String(repeating: text, count: count)
                let content = GlassCardContentProjection(leftTop: value, leftBottom: value, rightTop: value, rightBottom: value)
                for edge: CGFloat in [360, 1080, 4284] {
                    for portrait in [true, false] {
                        let size = portrait ? CGSize(width: edge, height: edge * 4 / 3) : CGSize(width: edge * 4 / 3, height: edge)
                        let plan = GlassCardResolvedPresentation.resolve(content: content, canvasSize: size)
                        for (slot, result) in plan.slots.enumerated() {
                            rows.append("\(language),\(count),\(portrait ? "portrait" : "landscape"),\(Int(edge)),\(slot),\(value.count),\(result.fit.outcome),\(result.fit.pointSize),\(result.fit.pointSize / edge)")
                            #expect(result.text == value)
                        }
                    }
                }
            }
        }
        Attachment.record(Data(rows.joined(separator: "\n").utf8), named: "text-fit-matrix.csv")
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
