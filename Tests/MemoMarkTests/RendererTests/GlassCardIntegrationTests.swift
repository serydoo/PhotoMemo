import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers
import Testing
@testable import MemoMark

@Suite("GlassCard integration")
struct GlassCardIntegrationTests {
    @Test("GlassCard preserves a short memory supplement with its explicit line break")
    @MainActor
    func memorySupplementFits() {
        let text = MemoryWriteTextComposer.compose(smartText: "今天是第 100 天", usesCustomText: true, customText: "此刻")!
        var input = card(text: text)
        input.template.leftTopArea.items = []
        input.template.rightBottomArea.items = [.story]
        let plan = GlassCardProductionRenderer.resolve(card: input, canvasSize: CGSize(width: 1080, height: 1440))
        #expect(plan.slots[3].text == text)
        #expect(plan.slots[3].fit.outcome == .fits)
        #expect(!plan.isContentOverflowing)
    }

    @Test("GlassCard retains overflow protection for more than two authored lines")
    @MainActor
    func memorySupplementTooManyLines() {
        var input = card(text: "第一行\n第二行\n第三行")
        input.template.leftTopArea.items = []
        input.template.rightBottomArea.items = [.story]
        let plan = GlassCardProductionRenderer.resolve(card: input, canvasSize: CGSize(width: 1080, height: 1440))
        #expect(plan.isContentOverflowing)
    }

    @Test("Motion color fallback retains layout and readable foreground without native backdrop")
    @MainActor
    func motionColorFallbackArtifact() throws {
        let input = card(text: "A memory")
        let size = CGSize(width: 1080, height: 1440)
        let planner = RecordCardPresentationPlanner()
        let native = try planner.artifact(for: input, canvasSize: size)
        let fallback = try planner.artifact(for: input, canvasSize: size, allowsNativeBackdrop: false)
        #expect(fallback.backdropMaterial == nil)
        #expect(fallback.canvasSize == native.canvasSize)
        #expect(fallback.photoFrame == native.photoFrame)
        #expect(fallback.layers[0].frame == native.layers[0].frame)
        #expect(fallback.layers[0].image.width == native.layers[0].image.width)
        _ = try fallback.validatedForEncoder()
    }

    @Test("Content-based right rail exports visible text without changing the photo canvas")
    @MainActor
    func trailingRailVisualEvidence() throws {
        for size in [CGSize(width: 1080, height: 1920), CGSize(width: 1920, height: 1080)] {
            let content = GlassCardContentProjection(leftTop: "MemoMark", leftBottom: "2026.10.06 08:30",
                rightTop: "24mm f/1.78 1/5814s ISO80", rightBottom: "A day to remember")
            let plan = GlassCardResolvedPresentation.resolve(content: content, canvasSize: size)
            #expect(!plan.isContentOverflowing)
            #expect(plan.geometry.leftTopFrame.maxX < plan.geometry.badgeFrame.minX)
            #expect(plan.geometry.rightTopFrame.minX == plan.geometry.rightBottomFrame.minX)
            let sourceRenderer = ImageRenderer(content: LinearGradient(colors: [.blue, .green, .orange],
                startPoint: .topLeading, endPoint: .bottomTrailing).frame(width: size.width, height: size.height))
            sourceRenderer.scale = 1
            let source = try #require(sourceRenderer.cgImage)
            let renderer = ImageRenderer(content: GlassCardResolvedCanvas(
                image: Image(decorative: source, scale: 1), presentation: plan, badge: .appleClassic))
            renderer.scale = 1
            let result = try #require(renderer.cgImage)
            #expect(result.width == Int(size.width) && result.height == Int(size.height))
            let data = NSMutableData()
            let destination = try #require(CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil))
            CGImageDestinationAddImage(destination, result, nil)
            #expect(CGImageDestinationFinalize(destination))
            Attachment.record(data as Data, named: "trailing-rail-\(Int(size.width)).png")
        }
    }

    @Test("GlassCard remains selectable and processable in Release and Debug")
    func releaseAvailability() throws {
        let style = try JSONDecoder().decode(RecordCardPresentationStyle.self, from: Data("\"glassCard\"".utf8))
        #expect(style.availability(isDebugBuild: false).isAuthorable)
        #expect(style.availability(isDebugBuild: false).isProcessable)
        #expect(style.availability(isDebugBuild: true).isAuthorable)
        #expect(RecordCardPresentationStyle.authorableStyles(isDebugBuild: false) == RecordCardPresentationStyle.allCases)
        #expect(RecordCardPresentationStyle.authorableStyles(isDebugBuild: true) == RecordCardPresentationStyle.allCases)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RecordCardPresentationStyle.self, from: Data("\"unknownStyle\"".utf8))
        }
    }

    @Test("Existing styles remain authorable and processable in every build", arguments: [
        RecordCardPresentationStyle.classicWhite, .minimal, .filmMark, .glassCard
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
        #expect(outputPlan.slots[0].fit.pointSize > viewportPlan.slots[0].fit.pointSize)
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
        let crop = CGRect(x: (panel.minX + panel.width * 0.5) * scale,
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

    @Test("Bounded preview preserves original GlassCard export geometry and source bytes")
    @MainActor
    func boundedPreviewPreservesOriginalExport() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("BoundedGlassExport-\(UUID())")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let sourceURL = folder.appendingPathComponent("source.jpg")
        let source = try ImageEdgeAssertionSupport.solidImage(width: 1080, height: 1440, red: 200, green: 200, blue: 200)
        try ImageEdgeAssertionSupport.writeJPEG(source, to: sourceURL)
        let originalBytes = try Data(contentsOf: sourceURL)
        let asset = MediaAsset(fileURL: sourceURL,
            sourceInfo: PhotoSourceInfo(originalFileName: "source.jpg"),
            sourceProperties: [:], contentType: .jpeg)
        let preview = try MediaDecodeService().previewImage(for: asset, maxPixelDimension: 128)
        #expect(preview.photoMemoSize.width <= 128)
        #expect(preview.photoMemoSize.height <= 128)
        let metadata = PhotoMetadata(imageWidth: 1080, imageHeight: 1440)
        let photo = SelectedPhoto(sourceURL: sourceURL, image: preview, metadata: metadata)
        var card = card(text: "此刻")
        card.metadata = metadata
        let outputURL = try RecordCardExportPipeline(namingResolver: OutputFileNamingResolver())
            .export(photo: photo, card: card, to: folder.appendingPathComponent("output.jpg"))
        let output = try ImageEdgeAssertionSupport.image(at: outputURL)
        #expect(output.width == 1080)
        #expect(output.height == 1440)
        #expect(try Data(contentsOf: sourceURL) == originalBytes)
    }

    @Test("CPU file export retains dimensions, EXIF and Unicode description")
    @MainActor
    func cpuJPEGMetadataReadback() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("CPUJPEG-\(UUID())")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let sourceURL = folder.appendingPathComponent("source.jpg")
        let source = try ImageEdgeAssertionSupport.solidImage(width: 1080, height: 1440, red: 160, green: 170, blue: 180)
        try ImageEdgeAssertionSupport.writeJPEG(source, to: sourceURL)
        let originalBytes = try Data(contentsOf: sourceURL)
        let image = try #require(CIImage(contentsOf: sourceURL, options: [.cacheImmediately: false]))
        let properties: [CFString: Any] = [
            kCGImagePropertyExifDictionary: [kCGImagePropertyExifDateTimeOriginal: "2020:01:02 03:04:05", kCGImagePropertyExifISOSpeedRatings: [100]],
            kCGImagePropertyTIFFDictionary: [kCGImagePropertyTIFFMake: "Apple"]
        ]
        let description = "成长的一天 🌱"
        let outputURL = try MetadataPreservingImageWriter().writeCPUJPEG(image: image,
            to: folder.appendingPathComponent("output.jpg"), sourceProperties: properties,
            exportDescription: description, captureDate: nil)
        let outputSource = try #require(CGImageSourceCreateWithURL(outputURL as CFURL, nil))
        let output = try #require(CGImageSourceCopyPropertiesAtIndex(outputSource, 0, nil) as? [CFString: Any])
        #expect(output[kCGImagePropertyPixelWidth] as? Int == 1080)
        #expect(output[kCGImagePropertyPixelHeight] as? Int == 1440)
        let exif = try #require(output[kCGImagePropertyExifDictionary] as? [CFString: Any])
        #expect(exif[kCGImagePropertyExifDateTimeOriginal] as? String == "2020:01:02 03:04:05")
        #expect(exif[kCGImagePropertyExifISOSpeedRatings] as? [Int] == [100])
        #expect(exif[kCGImagePropertyExifUserComment] as? String == description)
        let tiff = try #require(output[kCGImagePropertyTIFFDictionary] as? [CFString: Any])
        #expect(tiff[kCGImagePropertyTIFFMake] as? String == "Apple")
        #expect(tiff[kCGImagePropertyTIFFImageDescription] as? String == description)
        #expect(try Data(contentsOf: sourceURL) == originalBytes)
        let originalPixel = try ImageEdgeAssertionSupport.bottomRows(in: ImageEdgeAssertionSupport.image(at: sourceURL), count: 1)[0]
        let outputPixel = try ImageEdgeAssertionSupport.bottomRows(in: ImageEdgeAssertionSupport.image(at: outputURL), count: 1)[0]
        #expect(abs(Int(originalPixel.minimumRed) - Int(outputPixel.minimumRed)) <= 3)
        #expect(abs(Int(originalPixel.minimumGreen) - Int(outputPixel.minimumGreen)) <= 3)
        #expect(abs(Int(originalPixel.minimumBlue) - Int(outputPixel.minimumBlue)) <= 3)
        let scratch = folder.appendingPathComponent(".cpu-raster-work")
        #expect(try FileManager.default.contentsOfDirectory(atPath: scratch.path).isEmpty)
    }

    @Test("CPU lazy GlassCard export preserves native rail and full canvas")
    @MainActor
    func cpuNativeGlassExportReadback() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("CPUGlass-\(UUID())")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let sourceURL = folder.appendingPathComponent("source.jpg")
        let source = try ImageEdgeAssertionSupport.solidImage(width: 1080, height: 1440, red: 200, green: 200, blue: 200)
        try ImageEdgeAssertionSupport.writeJPEG(source, to: sourceURL)
        let metadata = PhotoMetadata(imageWidth: 1080, imageHeight: 1440)
        let preview = try #require(MediaDecodeService().thumbnailImage(from: sourceURL, maxPixelDimension: 128))
        let photo = SelectedPhoto(sourceURL: sourceURL, image: preview, metadata: metadata)
        var card = card(text: "成长的一天")
        card.metadata = metadata
        let artifact = try RecordCardPresentationPlanner().artifact(for: card, canvasSize: CGSize(width: 1080, height: 1440))
        let outputURL = try CPUStillImageExportExperiment.export(photo: photo, artifact: artifact,
            to: folder.appendingPathComponent("cpu.jpg"), writer: MetadataPreservingImageWriter(),
            exportDescription: "成长的一天")
        let output = try ImageEdgeAssertionSupport.image(at: outputURL)
        #expect(output.width == 1080)
        #expect(output.height == 1440)
        let bottom = try #require(output.cropping(to: CGRect(x: 216, y: 1365, width: 1, height: 1)))
        let top = try #require(output.cropping(to: CGRect(x: 216, y: 75, width: 1, height: 1)))
        #expect(try ImageEdgeAssertionSupport.bottomRows(in: bottom, count: 1)[0].maximumRGB < 170)
        #expect(try ImageEdgeAssertionSupport.bottomRows(in: top, count: 1)[0].minimumRGB > 190)
    }

    @Test("mapped JPEG strips retain asymmetric pixels and upright EXIF orientation", arguments: [1, 6, 8])
    @MainActor
    func cpuAsymmetricOrientationReadback(orientation: Int) throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("CPUOrientation-\(UUID())")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let context = try #require(CGContext(data: nil, width: 96, height: 64, bitsPerComponent: 8,
            bytesPerRow: 96 * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 96, height: 32))
        context.setFillColor(CGColor(red: 0.1, green: 0.1, blue: 0.8, alpha: 1))
        context.fill(CGRect(x: 0, y: 32, width: 96, height: 32))
        let original = try #require(context.makeImage())
        let sourceURL = folder.appendingPathComponent("source.jpg")
        let destination = try #require(CGImageDestinationCreateWithURL(sourceURL as CFURL, UTType.jpeg.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, original, [kCGImagePropertyOrientation: orientation,
            kCGImageDestinationLossyCompressionQuality: 1] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        let sourceBytes = try Data(contentsOf: sourceURL)
        let upright = try #require(CIImage(contentsOf: sourceURL, options: [.applyOrientationProperty: true]))
        let reference = try #require(CIContext(options: [.useSoftwareRenderer: true]).createCGImage(upright, from: upright.extent))
        let outputURL = try MetadataPreservingImageWriter().writeCPUJPEG(image: upright,
            to: folder.appendingPathComponent("output.jpg"), sourceProperties: [kCGImagePropertyOrientation: orientation],
            exportDescription: "", captureDate: nil)
        let output = try ImageEdgeAssertionSupport.image(at: outputURL)
        #expect(output.width == reference.width && output.height == reference.height)
        for x in [16, output.width - 17] {
            for y in [16, output.height - 17] {
                let rectangle = CGRect(x: x, y: y, width: 1, height: 1)
                let actualCrop = try #require(output.cropping(to: rectangle))
                let expectedCrop = try #require(reference.cropping(to: rectangle))
                let actual = try ImageEdgeAssertionSupport.bottomRows(in: actualCrop, count: 1)[0]
                let expected = try ImageEdgeAssertionSupport.bottomRows(in: expectedCrop, count: 1)[0]
                #expect(abs(Int(actual.minimumRed) - Int(expected.minimumRed)) <= 3)
                #expect(abs(Int(actual.minimumBlue) - Int(expected.minimumBlue)) <= 3)
            }
        }
        let outputSource = try #require(CGImageSourceCreateWithURL(outputURL as CFURL, nil))
        let properties = try #require(CGImageSourceCopyPropertiesAtIndex(outputSource, 0, nil) as? [CFString: Any])
        #expect((properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue == 1)
        #expect(try Data(contentsOf: sourceURL) == sourceBytes)
    }

    @Test("mapped Live Photo still keeps pairing metadata and full dimensions", arguments: ["jpg", "heic"])
    func cpuLivePhotoStillPairing(extensionName: String) throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("CPULiveStill-\(UUID())")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let sourceURL = folder.appendingPathComponent("source.jpg")
        let source = try ImageEdgeAssertionSupport.solidImage(width: 1080, height: 1440, red: 200, green: 200, blue: 200)
        try ImageEdgeAssertionSupport.writeJPEG(source, to: sourceURL)
        let original = try Data(contentsOf: sourceURL)
        let artifact = try RecordCardPresentationPlanner().artifact(for: card(text: "成长的一天"), canvasSize: CGSize(width: 1080, height: 1440))
        let pairing = UUID().uuidString
        let output = try LivePhotoStillImageCompositionService().composeCPUStillImage(
            sourceStillURL: sourceURL, overlay: artifact,
            outputURL: folder.appendingPathComponent("paired").appendingPathExtension(extensionName),
            outputType: extensionName == "jpg" ? .jpeg : .heic,
            pairingIdentifier: pairing, outputDescription: "成长的一天")
        let image = try ImageEdgeAssertionSupport.image(at: output)
        #expect(image.width == 1080 && image.height == 1440)
        let imageSource = try #require(CGImageSourceCreateWithURL(output as CFURL, nil))
        let properties = try #require(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any])
        let apple = try #require(properties[kCGImagePropertyMakerAppleDictionary] as? [String: Any])
        #expect(apple["17"] as? String == pairing)
        #expect(try Data(contentsOf: sourceURL) == original)
        let scratch = folder.appendingPathComponent(".cpu-raster-work")
        #expect(try FileManager.default.contentsOfDirectory(atPath: scratch.path).isEmpty)
    }

    @Test("mapped encoder failure removes only its scratch raster")
    func cpuRasterFailureCleanup() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("RasterFailure-\(UUID())")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let image = CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 16, height: 16))
        let context = CIContext(options: [.useSoftwareRenderer: true, .cacheIntermediates: false])
        #expect(throws: CocoaError.self) {
            try CPUFileRasterExport.withMappedRaster(image: image, context: context,
                to: folder.appendingPathComponent("failed.jpg")) { _ in throw CocoaError(.fileWriteUnknown) }
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.appendingPathComponent(".cpu-raster-work").path).isEmpty)
    }

    @Test("CPU raster strips reduce render calls while retaining a two MiB buffer limit", arguments: [4032, 8064, 16384])
    func cpuRasterStripBudget(width: Int) {
        let rows = CPUFileRasterExport.stripRows(forWidth: width)
        #expect(rows > 8 && rows <= 64)
        #expect(width * 4 * rows <= 2 * 1024 * 1024)
    }

    @Test("Mapped bitmap retains individual row order and the partial final strip")
    func cpuRasterIndividualRows() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("RasterRows-\(UUID())")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let context = try #require(CGContext(data: nil, width: 96, height: 70, bitsPerComponent: 8,
            bytesPerRow: 96 * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        for row in 0..<70 {
            let value = CGFloat(25 + row * 3) / 255
            context.setFillColor(CGColor(gray: value, alpha: 1))
            context.fill(CGRect(x: 0, y: row, width: 96, height: 1))
        }
        let image = CIImage(cgImage: try #require(context.makeImage()))
        let reference = try #require(CIContext(options: [.useSoftwareRenderer: true]).createCGImage(image, from: image.extent))
        let outputURL = try MetadataPreservingImageWriter().writeCPUJPEG(image: image,
            to: folder.appendingPathComponent("rows.jpg"), sourceProperties: [:], exportDescription: "", captureDate: nil)
        let output = try ImageEdgeAssertionSupport.image(at: outputURL)
        #expect(output.width == 96 && output.height == 70)
        for row in 0..<70 {
            let rectangle = CGRect(x: 32, y: row, width: 1, height: 1)
            let actual = try ImageEdgeAssertionSupport.bottomRows(in: #require(output.cropping(to: rectangle)), count: 1)[0]
            let expected = try ImageEdgeAssertionSupport.bottomRows(in: #require(reference.cropping(to: rectangle)), count: 1)[0]
            #expect(abs(Int(actual.minimumRed) - Int(expected.minimumRed)) <= 3)
        }
    }

    @Test("interrupted Live Photo rasters clean only owned regular files")
    func cpuOrphanCleanupScope() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("RasterOrphans-\(UUID())")
        let processing = root.appendingPathComponent("processing")
        let job = processing.appendingPathComponent(UUID().uuidString)
        let scratch = job.appendingPathComponent(".cpu-raster-work")
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let outside = root.appendingPathComponent("source.rgba")
        try Data("original".utf8).write(to: outside)
        let owned = scratch.appendingPathComponent(UUID().uuidString).appendingPathExtension("rgba")
        try Data("interrupted".utf8).write(to: owned)
        let unrelated = scratch.appendingPathComponent("notes.txt")
        try Data("keep".utf8).write(to: unrelated)
        let link = scratch.appendingPathComponent(UUID().uuidString).appendingPathExtension("rgba")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: outside)
        try CPUFileRasterExport.cleanupInterruptedRasters(inProcessingRoot: processing)
        #expect(!FileManager.default.fileExists(atPath: owned.path))
        #expect(FileManager.default.fileExists(atPath: unrelated.path))
        #expect(FileManager.default.fileExists(atPath: link.path))
        #expect(try Data(contentsOf: outside) == Data("original".utf8))
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
