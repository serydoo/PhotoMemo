import CoreGraphics
import Foundation
import ImageIO
import Testing
@testable import MemoMark

@Suite("GlassCard integration")
struct GlassCardIntegrationTests {
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
        #expect(artifact.layers.count == 1)
        #expect(artifact.layers[0].image.width == 1080)
        #expect(artifact.layers[0].image.height < 300)
        let panel = GlassCardLayoutSpecification.panelFrame(canvasSize: size)
        let artifactPanel = CGRect(x: panel.minX, y: size.height - panel.maxY, width: panel.width, height: panel.height)
        #expect(artifact.layers[0].frame.contains(artifactPanel))
        #expect(artifact.layers[0].frame.minY == 0)
        _ = try artifact.validatedForEncoder()
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
