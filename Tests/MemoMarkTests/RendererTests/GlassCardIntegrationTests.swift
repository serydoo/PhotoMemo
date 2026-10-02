import CoreGraphics
import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers
import Testing
@testable import MemoMark

@Suite("GlassCard integration")
struct GlassCardIntegrationTests {
    @Test("Release authoring stays closed while registered GlassCard remains processable")
    func releaseAvailability() throws {
        let style = try JSONDecoder().decode(RecordCardPresentationStyle.self, from: Data("\"glassCard\"".utf8))
        #expect(!style.availability(isDebugBuild: false).isAuthorable)
        #expect(style.availability(isDebugBuild: false).isProcessable)
        #expect(style.availability(isDebugBuild: true).isAuthorable)
        #expect(RecordCardPresentationStyle.authorableStyles(isDebugBuild: false) == [.classicWhite, .minimal, .filmMark])
        #expect(RecordCardPresentationStyle.authorableStyles(isDebugBuild: true) == RecordCardPresentationStyle.allCases)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RecordCardPresentationStyle.self, from: Data("\"unknownStyle\"".utf8))
        }
    }

    @Test("Existing styles remain authorable and processable in every build", arguments: [
        RecordCardPresentationStyle.classicWhite, .minimal, .filmMark
    ])
    func existingStyleAvailability(style: RecordCardPresentationStyle) {
        for isDebugBuild in [false, true] {
            #expect(style.availability(isDebugBuild: isDebugBuild).isAuthorable)
            #expect(style.availability(isDebugBuild: isDebugBuild).isProcessable)
        }
    }

    @Test("The app selection entry uses the current build policy")
    func currentBuildSelection() {
#if DEBUG
        #expect(RecordCardPresentationStyle.selectableStyles == RecordCardPresentationStyle.authorableStyles(isDebugBuild: true))
#else
        #expect(RecordCardPresentationStyle.selectableStyles == RecordCardPresentationStyle.authorableStyles(isDebugBuild: false))
#endif
    }

    @Test("GlassCard has an independent durable route and four editable positions")
    func routeAndContentContract() throws {
        #expect(try JSONDecoder().decode(RecordCardPresentationStyle.self, from: Data("\"glassCard\"".utf8)) == .glassCard)
        #expect(CardRegion.editableRegions(for: .glassCard) == [.slotA, .slotB, .slotC, .slotD])
        #expect(RecordCardPresentationStyle.legacyTemplateBackedStyles.contains(.glassCard))
        #expect(RecordCardRenderer.destination(for: .glassCard) == .glassCard)
    }

    @Test("GlassCard template survives configuration round trip without changing Classic")
    func independentTemplatePersistence() throws {
        var glass = Template.classicWhite
        glass.leftTopArea.items = [.story]
        let editor = MemoryConfigurationRecord.Editor(
            template: .classicWhite,
            templatesByPresentationStyle: [.glassCard: glass],
            regionTemplateIDs: [:], memoryCopy: .init(usesCustomText: false, customText: "")
        )
        let decoded = try JSONDecoder().decode(MemoryConfigurationRecord.Editor.self, from: JSONEncoder().encode(editor))
        #expect(decoded.template(for: .glassCard).leftTopArea.items == [.story])
        #expect(decoded.template(for: .classicWhite) == .classicWhite)
        #expect(decoded.template(for: .minimal) == .classicWhite)
    }

    @Test("Same-canvas geometry remains encoder safe for odd dimensions")
    func encoderSafeGeometry() {
        #expect(GlassCardProductionRenderer.outputPixelSize(
            for: PhotoMetadata(imageWidth: 3213, imageHeight: 5712), fallbackSize: .zero
        ) == CGSize(width: 3214, height: 5712))
    }

    @Test("GlassCard artifact is a transparent same-canvas layer")
    @MainActor
    func staticArtifact() throws {
        let size = CGSize(width: 1080, height: 1440)
        let artifact = try RecordCardPresentationPlanner().artifact(for: card(text: "此刻"), canvasSize: size)
        #expect(artifact.canvasSize == size)
        #expect(artifact.photoFrame == CGRect(origin: .zero, size: size))
        #expect(artifact.canvasBackground == .transparent)
        #expect((artifact.backdropMaterial != nil) == GlassCardProductionRenderer.usesNativeMaterial)
        #expect(artifact.layers.count == 1)
        #expect(artifact.layers[0].image.width == 1080)
        #expect(artifact.layers[0].image.height < 300)
        let panel = GlassCardLayoutSpecification.panelFrame(canvasSize: size)
        let artifactPanel = CGRect(x: panel.minX, y: size.height - panel.maxY, width: panel.width, height: panel.height)
        #expect(artifact.layers[0].frame.contains(artifactPanel))
        #expect(artifact.layers[0].frame.minY == 0)
        _ = try artifact.validatedForEncoder()
    }

    @Test("Compact card preview renders the output-sized text plan")
    @MainActor
    func compactPreviewUsesOutputPlan() throws {
        let card = card(text: "Our first walk together, a memory to revisit.")
        let viewport = CGSize(width: 360, height: 480)
        let source = try ImageEdgeAssertionSupport.solidImage(
            width: 1080, height: 1440, red: 128, green: 128, blue: 128
        )
        let image = Image(decorative: source, scale: 1)
        let outputPlan = GlassCardProductionRenderer.resolve(card: card, canvasSize: CGSize(width: 1080, height: 1440))
        let viewportPlan = GlassCardProductionRenderer.resolve(card: card, canvasSize: viewport)
        #expect(outputPlan.slots[0].fit.outcome != viewportPlan.slots[0].fit.outcome)
        let expected = ZStack(alignment: .topLeading) {
            if GlassCardProductionRenderer.usesNativeMaterial {
                NativeBackdropMaterialCanvas(image: image, canvasSize: outputPlan.canvasSize,
                    material: GlassCardProductionRenderer.backdropMaterial(for: outputPlan))
            } else {
                image.resizable().scaledToFill().frame(width: outputPlan.canvasSize.width, height: outputPlan.canvasSize.height).clipped()
            }
            GlassCardOverlayLayer(presentation: outputPlan, badge: card.badge)
        }.frame(width: outputPlan.canvasSize.width, height: outputPlan.canvasSize.height, alignment: .topLeading)
            .scaleEffect(1.0 / 3, anchor: .topLeading)
            .frame(width: viewport.width, height: viewport.height, alignment: .topLeading)
        let expectedRenderer = ImageRenderer(content: expected.frame(width: viewport.width, height: viewport.height))
        let actualRenderer = ImageRenderer(content: GlassCardCardRenderer(image: image, card: card)
            .frame(width: viewport.width, height: viewport.height))
        expectedRenderer.scale = 1
        actualRenderer.scale = 1
        let expectedImage = try #require(expectedRenderer.cgImage)
        let actualImage = try #require(actualRenderer.cgImage)
        for (name, image) in [("preview-expected", expectedImage), ("preview-actual", actualImage)] {
            let data = NSMutableData()
            let destination = try #require(CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil))
            CGImageDestinationAddImage(destination, image, nil)
            #expect(CGImageDestinationFinalize(destination))
            Attachment.record(data as Data, named: name + ".png")
        }
        let expectedPixels = try #require(expectedImage.dataProvider?.data)
        let actualPixels = try #require(actualImage.dataProvider?.data)
        let actualData = actualPixels as Data
        let expectedData = expectedPixels as Data
        #expect(actualData.count == expectedData.count)
        // Fractional mark dimensions can differ by one 8-bit rounding level
        // across separate native SwiftUI raster hosts; glyph placement stays exact.
        let differences = zip(actualData, expectedData).map { abs(Int($0) - Int($1)) }
        #expect((differences.max() ?? 0) <= 1)
        #expect(Double(differences.reduce(0, +)) / Double(differences.count) < 0.001)
    }

    @Test("Configuration Center preview includes the output material", arguments: ConfigurationPreviewBackground.Orientation.allCases)
    @MainActor
    func configurationPreviewIncludesMaterial(orientation: ConfigurationPreviewBackground.Orientation) throws {
        let canvas = try #require(ConfigurationPreviewBackground.glassCardPixelSize(for: orientation))
        let viewport = CGSize(width: 360, height: 360 * canvas.height / canvas.width)
        let plan = GlassCardResolvedPresentation.resolve(
            content: .init(leftTop: "此刻", leftBottom: "", rightTop: "", rightBottom: ""),
            canvasSize: canvas
        )
        let image = Image(ConfigurationPreviewBackground.minimal.assetName(forOrientation: orientation))
        let expected = ZStack(alignment: .topLeading) {
            if GlassCardProductionRenderer.usesNativeMaterial {
                NativeBackdropMaterialCanvas(image: image, canvasSize: canvas,
                    material: GlassCardProductionRenderer.backdropMaterial(for: plan))
            } else {
                image.resizable().scaledToFill().frame(width: canvas.width, height: canvas.height).clipped()
            }
            GlassCardOverlayLayer(presentation: plan, badge: .appleClassic)
        }.frame(width: canvas.width, height: canvas.height, alignment: .topLeading)
            .scaleEffect(viewport.width / canvas.width, anchor: .topLeading)
            .frame(width: viewport.width, height: viewport.height, alignment: .topLeading)
        let actual = MemoryCardPreviewSurface(
            presentationStyle: .glassCard, logoMode: .appleMini,
            customLogoImagePath: nil, subjectAvatarLogoImagePath: nil,
            regionText: "此刻", timeText: "", contextText: "", memoryText: "",
            previewOrientation: orientation
        ).frame(width: viewport.width, height: viewport.height)
        let expectedRenderer = ImageRenderer(content: expected
            .clipShape(RoundedRectangle(cornerRadius: ConfigurationUI.cornerRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: ConfigurationUI.cornerRadius, style: .continuous)
                .stroke(ConfigurationUI.faintHairline))
            .shadow(color: ConfigurationUI.cardShadow, radius: 8, y: 3))
        let actualRenderer = ImageRenderer(content: actual)
        expectedRenderer.scale = 1
        actualRenderer.scale = 1
        let expectedImage = try #require(expectedRenderer.cgImage)
        let actualImage = try #require(actualRenderer.cgImage)
        // Sample the interior away from text, badge and view border/shadow.
        let panel = plan.geometry.panelFrame
        let scale = viewport.width / canvas.width
        let crop = CGRect(x: (panel.minX + panel.width * 0.8) * scale,
                          y: (panel.minY + panel.height * 0.35) * scale,
                          width: panel.width * 0.08 * scale, height: panel.height * 0.3 * scale).integral
        let expectedCrop = try #require(expectedImage.cropping(to: crop))
        let actualCrop = try #require(actualImage.cropping(to: crop))
        func pixels(_ image: CGImage) throws -> [UInt8] {
            var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
            let colorSpace = try #require(CGColorSpace(name: CGColorSpace.sRGB))
            try bytes.withUnsafeMutableBytes { buffer in
                let context = try #require(CGContext(
                    data: buffer.baseAddress, width: image.width, height: image.height,
                    bitsPerComponent: 8, bytesPerRow: image.width * 4,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                ))
                context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            }
            return bytes
        }
        let expectedBytes = try pixels(expectedCrop)
        let actualBytes = try pixels(actualCrop)
        for (name, output) in [("configuration-expected", expectedImage), ("configuration-actual", actualImage)] {
            let data = NSMutableData()
            let destination = try #require(CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil))
            CGImageDestinationAddImage(destination, output, nil)
            #expect(CGImageDestinationFinalize(destination))
            Attachment.record(data as Data, named: name + "-" + String(describing: orientation) + ".png")
        }
        let differences = zip(expectedBytes, actualBytes).map { abs(Int($0) - Int($1)) }
        // Separate SwiftUI hosting/clip paths introduce bounded 8-bit rounding.
        // Keep a tight pixel bound, and prove omitted glass lies outside it.
        let meanDifference = Double(differences.reduce(0, +)) / Double(differences.count)
        #expect((differences.max() ?? 0) <= 3)
        #expect(meanDifference < 0.5)
        if GlassCardProductionRenderer.usesNativeMaterial {
            let plainRenderer = ImageRenderer(content: image.resizable().scaledToFill()
                .frame(width: viewport.width, height: viewport.height).clipped())
            plainRenderer.scale = 1
            let plainImage = try #require(plainRenderer.cgImage)
            let plainCrop = try #require(plainImage.cropping(to: crop))
            let plainBytes = try pixels(plainCrop)
            let omittedDifference = zip(expectedBytes, plainBytes).reduce(0) { $0 + abs(Int($1.0) - Int($1.1)) }
            #expect(Double(omittedDifference) / Double(plainBytes.count) > 3)
        }
    }

    @Test("Incomplete content cannot produce a successful artifact")
    @MainActor
    func rejectsEmptyAndOverflow() {
        for text in ["", String(repeating: "长文内容", count: 300)] {
            #expect(throws: ProductionConfigurationContractError.self) {
                try RecordCardPresentationPlanner().artifact(for: card(text: text), canvasSize: CGSize(width: 1080, height: 1440))
            }
        }
    }

    @Test("Still export and Live Photo entry share the GlassCard artifact", arguments: [
        CGSize(width: 1080, height: 1440), CGSize(width: 1920, height: 1080)
    ])
    @MainActor
    func fileExportAndMotionGeometry(size: CGSize) throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("GlassCardExport-\(UUID())")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let sourceURL = folder.appendingPathComponent("source.jpg")
        let image = try ImageEdgeAssertionSupport.solidImage(
            width: Int(size.width), height: Int(size.height), red: 200, green: 200, blue: 200
        )
        try ImageEdgeAssertionSupport.writeJPEG(image, to: sourceURL)
        let original = try Data(contentsOf: sourceURL)
        let metadata = PhotoMetadata(imageWidth: Int(size.width), imageHeight: Int(size.height))
        let photo = SelectedPhoto(sourceURL: sourceURL, image: PlatformImage.photoMemoImage(cgImage: image), metadata: metadata)
        var card = card(text: "此刻")
        card.metadata = metadata
        let pipeline = RecordCardExportPipeline(namingResolver: OutputFileNamingResolver())
        let outputURL = try pipeline.export(photo: photo, card: card, to: folder.appendingPathComponent("output.jpg"))
        let output = try ImageEdgeAssertionSupport.image(at: outputURL)
        #expect(output.width == Int(size.width))
        #expect(output.height == Int(size.height))
        #expect(try Data(contentsOf: sourceURL) == original)

        let motionArtifact = try pipeline.renderLivePhotoOverlay(photo: photo, card: card)
        let geometry = try LivePhotoGeometryResolver().resolveGeometry(
            sourceStillURL: sourceURL, overlay: motionArtifact, outputStillType: .jpeg
        )
        #expect(geometry.canvas.canvasSize == size)
        #expect(geometry.canvas.photoFrame == CGRect(origin: .zero, size: size))

        // Bitmap cropping uses top-left pixel coordinates. The rail must be
        // at the bottom after the shared artifact compositor has drawn it.
        let bottom = try #require(output.cropping(to: CGRect(x: size.width * 0.2, y: size.height - size.width * 0.07, width: 1, height: 1)))
        let top = try #require(output.cropping(to: CGRect(x: size.width * 0.2, y: size.width * 0.07, width: 1, height: 1)))
        #expect(try ImageEdgeAssertionSupport.bottomRows(in: bottom, count: 1)[0].maximumRGB < 170)
        #expect(try ImageEdgeAssertionSupport.bottomRows(in: top, count: 1)[0].minimumRGB > 190)
    }

    private func card(text: String) -> RecordCard {
        var template = Template.classicWhite
        template.leftTopArea.items = [.story]
        template.leftBottomArea.items = []
        template.rightTopArea.items = []
        template.rightBottomArea.items = []
        return RecordCard(
            template: template, presentationStyle: .glassCard,
            metadata: PhotoMetadata(imageWidth: 1080, imageHeight: 1440),
            context: MetadataContext(), story: text
        )
    }
}
