import CoreGraphics
import Foundation
import Testing
import AppKit
import SwiftUI
@testable import MemoMark

@Suite("FilmMark presentation specification")
struct FilmMarkPresentationSpecificationTests {

    @Test("keeps content meaning in the primary output carrier")
    func keepsContentMeaningInPrimaryOutputCarrier() {
        let content = FilmMarkContentProjection(
            primaryOutput: "2026/08/16 21:29 · 1岁2个月18天"
        )

        #expect(content.primaryOutput.contains("2026/08/16"))
        #expect(content.primaryOutput.contains("1岁2个月18天"))
    }

    @Test("migrates V1 TemplateArea storage into the layout-independent V2 carrier")
    func migratesV1TemplateAreaStorageIntoV2Carrier() throws {
        let legacy = LegacyFilmMarkContentPayload(
            schemaVersion: 1,
            primaryOutput: TemplateArea(
                name: "FilmMark",
                items: [.captureDateLine]
            )
        )
        let decoded = try JSONDecoder().decode(
            FilmMarkContentSchemaV2.self,
            from: JSONEncoder().encode(legacy)
        )

        #expect(decoded.schemaVersion == 2)
        #expect(decoded.primaryOutputItems == [.captureDateLine])

        let encoded = try JSONEncoder().encode(decoded)
        let object = try #require(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        #expect(object["schemaVersion"] as? Int == 2)
        #expect(object["primaryOutputItems"] != nil)
        #expect(object["primaryOutput"] == nil)
    }

    @Test("offers bounded free-font candidate identifiers without bundling claims")
    func offersBoundedFreeFontCandidateIdentifiers() {
        #expect(FilmMarkFontID.allCases.contains(.ibmPlexMono))
        #expect(FilmMarkFontID.allCases.contains(.spaceMono))
        #expect(FilmMarkFontID.allCases.contains(.jetBrainsMono))
        #expect(FilmMarkFontID.allCases.count == 4)
    }

    @Test("quantizes and bounds font size ratios")
    func quantizesAndBoundsFontSizeRatios() {
        let tiny = FilmMarkFontSize(relativeToCanvasWidth: -1)
        let large = FilmMarkFontSize(relativeToCanvasWidth: 1)
        let precise = FilmMarkFontSize(relativeToCanvasWidth: 0.01804)

        #expect(tiny.canvasWidthRatioUnits == 80)
        #expect(large.canvasWidthRatioUnits == 600)
        #expect(precise.canvasWidthRatioUnits == 180)
        #expect(precise.relativeToCanvasWidth == 0.018)
    }

    @Test("font size slider centres the established prominent size and round trips values")
    func fontSizeSliderCentresTheEstablishedProminentSizeAndRoundTripsValues() {
        #expect(
            abs(FilmMarkFontSize.sliderPosition(for: .prominent) - 0.5)
                < 0.0001
        )
        #expect(
            FilmMarkFontSize.fontSize(
                forSliderPosition: 0.5
            ) == .prominent
        )

        let userSelected = FilmMarkFontSize.fontSize(forSliderPosition: 0.73)
        #expect(
            abs(
                FilmMarkFontSize.sliderPosition(for: userSelected) - 0.73
            ) < 0.003
        )
    }

    @Test("all production styles select the same orientation-matched photographs")
    func allProductionStylesSelectSharedOrientationMatchedPhotographs() {
        let styles: [ConfigurationPreviewBackground] = [
            .classicWhite,
            .minimal,
            .filmMark
        ]

        for style in styles {
            #expect(
                style.assetName(forOrientation: .landscape)
                    == "MidAutumnPreviewBackgroundLandscape"
            )
            #expect(
                style.assetName(forOrientation: .portrait)
                    == "MidAutumnPreviewBackgroundPortrait"
            )
        }
    }

    @Test("production previews select shared assets and matching canvas ratios")
    func productionPreviewsSelectSharedAssetsAndCanvasRatios() {
        #expect(
            ConfigurationPreviewBackground.minimal.assetName(
                forOrientation: .landscape
            ) == "MidAutumnPreviewBackgroundLandscape"
        )
        #expect(
            ConfigurationPreviewBackground.minimal.assetName(
                forOrientation: .portrait
            ) == "MidAutumnPreviewBackgroundPortrait"
        )
        #expect(
            ConfigurationPreviewBackground.filmMark.assetName(
                forOrientation: .portrait
            ) == "MidAutumnPreviewBackgroundPortrait"
        )
        #expect(
            abs(ConfigurationPreviewBackground.landscapeAspectRatio - 16.0 / 9.0)
                < 0.0001
        )
        #expect(
            abs(ConfigurationPreviewBackground.portraitAspectRatio - 9.0 / 16.0)
                < 0.0001
        )
        #expect(
            abs(
                ConfigurationPreviewViewportSpec.viewportAspectRatio(
                    for: .landscape,
                    isExpanded: false
                ) - (16.0 / 9.0 / ConfigurationPreviewViewportSpec.landscapeFitScale)
            ) < 0.0001
        )
        #expect(
            abs(
                ConfigurationPreviewViewportSpec.viewportAspectRatio(
                    for: .portrait,
                    isExpanded: false
                ) - (
                    1.125
                        / (
                            ConfigurationPreviewViewportSpec.portraitFitScale
                                * ConfigurationPreviewViewportSpec
                                    .portraitFitVisibleFraction
                        )
                )
            ) < 0.0001
        )
        #expect(
            FilmMarkPreviewGeometrySpec.canvasSize(for: .landscape)
                == CGSize(width: 1_200, height: 675)
        )
        #expect(
            FilmMarkPreviewGeometrySpec.canvasSize(for: .portrait)
                == CGSize(width: 675, height: 1_200)
        )
    }

    @Test("preview preferences remain app-local UI state")
    func previewPreferencesRemainAppLocalUIState() {
        #expect(
            ConfigurationPreviewPreferenceKey.orientation
                == "memomark.configuration.preview.orientation"
        )
        #expect(
            ConfigurationPreviewViewportSpec.canvasWidth(
                availableWidth: 400,
                for: .landscape,
                isExpanded: false
            ) == 400 * ConfigurationPreviewViewportSpec.landscapeFitScale
        )
        #expect(
            ConfigurationPreviewViewportSpec.canvasWidth(
                availableWidth: 400,
                for: .portrait,
                isExpanded: false
            ) == 400 * ConfigurationPreviewViewportSpec.portraitFitScale
        )
        let availableWidth: CGFloat = 400
        let canvasAspectRatio = ConfigurationPreviewBackground.portraitAspectRatio
        let canvasWidth = availableWidth
            * ConfigurationPreviewViewportSpec.portraitFitScale
        let canvasHeight = canvasWidth / canvasAspectRatio
        let viewportHeight = availableWidth
            / ConfigurationPreviewViewportSpec.viewportAspectRatio(
                canvasAspectRatio: canvasAspectRatio,
                for: .portrait,
                isExpanded: false
            )
        #expect(
            abs(
                viewportHeight / canvasHeight
                    - ConfigurationPreviewViewportSpec.portraitFitVisibleFraction
            ) < 0.0001
        )
        #expect(ConfigurationPreviewViewportSpec.alternateCardPeekScale > 0.90)
        #expect(ConfigurationPreviewViewportSpec.alternateCardPeekScale < 1)
        #expect(ConfigurationPreviewViewportSpec.alternateCardPeekOpacity > 0.65)
        #expect(ConfigurationPreviewViewportSpec.alternateCardPeekOffset > 0)
    }

    @Test("Classic White preview includes its complete information bar in the canvas ratio")
    func classicWhitePreviewIncludesCompleteInformationBarInCanvasRatio() {
        for orientation in ConfigurationPreviewBackground.Orientation.allCases {
            let imageAspectRatio = ConfigurationPreviewBackground.aspectRatio(
                for: orientation
            )
            let barOrientation: CompactInformationBarOrientation =
                orientation == .landscape ? .landscape : .portrait
            let informationBarHeightToWidth =
                RendererConstants.CompactInformationBar.spec(for: barOrientation)
                    .barHeightToWidth
            let expectedCanvasAspectRatio = 1 / (
                1 / imageAspectRatio + informationBarHeightToWidth
            )

            #expect(
                abs(
                    ConfigurationPreviewViewportSpec.canvasAspectRatio(
                        for: .classicWhite,
                        orientation: orientation
                    ) - expectedCanvasAspectRatio
                ) < 0.0001
            )
        }
    }

    @MainActor
    @Test("full-canvas FilmMark surface renders both orientations")
    func reviewFullCanvasFilmMarkSurfaceRendersBothOrientations() throws {
        for orientation in ConfigurationPreviewBackground.Orientation.allCases {
            let canvasSize = FilmMarkPreviewGeometrySpec.canvasSize(
                for: orientation
            )
            let displayWidth: CGFloat = 360
            let displayHeight = displayWidth
                / ConfigurationPreviewBackground.aspectRatio(for: orientation)
            let renderer = ImageRenderer(
                content: FilmMarkPreviewSurface(
                    content: .init(
                        primaryOutput: "2026.06.18 · 出生第 428 天"
                    ),
                    configuration: .default,
                    mode: .fullPhotoCanvas(
                        orientation: orientation,
                        showsGuides: true
                    )
                )
                .frame(width: displayWidth, height: displayHeight)
            )
            renderer.scale = 1

            let image = try #require(renderer.cgImage)
            #expect(image.width == Int(displayWidth))
            #expect(abs(image.height - Int(displayHeight.rounded())) <= 1)
            #expect(canvasSize.width > 0 && canvasSize.height > 0)
        }
    }

    @MainActor
    @Test("Classic White review preserves each photo above its complete information bar")
    func classicWhiteReviewPreservesPhotoAndInformationBarDimensions() throws {
        for orientation in ConfigurationPreviewBackground.Orientation.allCases {
            let aspectRatio = ConfigurationPreviewViewportSpec.canvasAspectRatio(
                for: .classicWhite,
                orientation: orientation
            )
            let width: CGFloat = 360
            let height = width / aspectRatio
            let renderer = ImageRenderer(
                content: MemoryCardPreviewSurface(
                    presentationStyle: .classicWhite,
                    logoMode: .appleMini,
                    customLogoImagePath: nil,
                    subjectAvatarLogoImagePath: nil,
                    regionText: "时光记",
                    timeText: "出生第 428 天",
                    contextText: "2026年6月18日 · 横滨",
                    memoryText: "你第一次追着风跑",
                    filmMarkPreviewMode: .contentStrip,
                    previewOrientation: orientation
                )
                .frame(width: width, height: height)
            )
            renderer.scale = 1

            let image = try #require(renderer.cgImage)
            #expect(image.width == Int(width))
            #expect(abs(image.height - Int(height.rounded())) <= 1)
        }
    }

    @Test("FM geometry preview never reveals more than the lower photo half")
    func fmGeometryPreviewNeverRevealsMoreThanTheLowerPhotoHalf() {
        #expect(
            FilmMarkPreviewGeometrySpec.maximumVisibleImageHeightFraction == 0.50
        )
        #expect(
            FilmMarkPreviewGeometrySpec.cropHeight(
                canvasHeight: 675,
                availableHeight: 400
            ) == 337.5
        )
        #expect(
            FilmMarkPreviewGeometrySpec.cropHeight(
                canvasHeight: 675,
                availableHeight: 150
            ) == 150
        )
        #expect(
            FilmMarkPreviewGeometrySpec.cropHeight(
                canvasHeight: 200,
                availableHeight: 150
            ) == 100
        )
    }

    @Test("starts a new FilmMark card with capture date and smart result")
    func startsNewFilmMarkCardWithCaptureDateAndSmartResult() {
        #expect(
            FilmMarkContentSchemaV2.defaultPrimaryOutputModules
                == [.captureDate, .smartTime]
        )
    }

    @Test("maps the compact FilmMark preview continuously around its default size")
    func mapsCompactFilmMarkPreviewContinuouslyAroundDefaultSize() {
        let height: CGFloat = 40
        let defaultSize = FilmMarkPreviewTypography.compactContentFontSize(
            for: .prominent,
            height: height
        )
        let userSelected = FilmMarkFontSize.fontSize(forSliderPosition: 0.73)
        let userSelectedSize = FilmMarkPreviewTypography.compactContentFontSize(
            for: userSelected,
            height: height
        )
        let largestSize = FilmMarkPreviewTypography.compactContentFontSize(
            for: FilmMarkFontSize.fontSize(forSliderPosition: 1),
            height: height
        )

        #expect(abs(defaultSize - 16.4) < 0.001)
        #expect(userSelectedSize > defaultSize)
        #expect(userSelectedSize < largestSize)
    }

    @Test("uses the short edge for stable typography across orientations")
    func usesShortEdgeForTypographyAcrossOrientations() {
        let appearance = FilmMarkAppearanceDraft(
            fontSize: .standard
        )
        let landscape = FilmMarkResolvedPresentation(
            canvasSize: CGSize(width: 4_000, height: 3_000),
            content: .init(primaryOutput: "time"),
            appearance: appearance,
            measuredContentSize: CGSize(width: 100, height: 50),
            placement: .init(anchor: .bottomRight)
        )
        let portrait = FilmMarkResolvedPresentation(
            canvasSize: CGSize(width: 3_000, height: 4_000),
            content: .init(primaryOutput: "time"),
            appearance: appearance,
            measuredContentSize: CGSize(width: 100, height: 50),
            placement: .init(anchor: .bottomRight)
        )

        #expect(
            abs(
                landscape.typography.pointSize
                    - portrait.typography.pointSize
            ) < 0.0001
        )
        #expect(abs(landscape.typography.pointSize - 54) < 0.0001)
    }

    @Test("marks measurement as constrained when CoreText cannot fit all content")
    func usesConstraintForUnfittedContent() {
        let appearance = FilmMarkAppearanceDraft(
            fontSize: .prominent
        )

        let measured = FilmMarkLayoutSpecification.measure(
            text: String(repeating: "2026/08/16 21:29 · 途途1岁6天 ", count: 500),
            canvasSize: CGSize(width: 1_200, height: 450),
            appearance: appearance
        )

        #expect(measured.size.width >= 1_104)
        #expect(measured.size.height >= 180)
        #expect(!measured.didFitEntireString)
        let resolved = FilmMarkResolvedPresentation(
            canvasSize: CGSize(width: 1_200, height: 450),
            content: .init(primaryOutput: String(repeating: "FM ", count: 500)),
            appearance: appearance, measuredContentSize: measured.size,
            placement: .init(anchor: .bottomRight),
            didFitEntireString: measured.didFitEntireString
        )
        #expect(resolved.layout.isContentOverflowingSafeArea)
    }

    @Test("clamps malformed persisted FM primitives through their invariants")
    func clampsMalformedPersistedPrimitives() throws {
        let color = try JSONDecoder().decode(
            FilmMarkRGBAColor.self,
            from: Data(#"{"red":2,"green":-1,"blue":0.4,"alpha":3}"#.utf8)
        )
        #expect(color == FilmMarkRGBAColor(red: 1, green: 0, blue: 0.4, alpha: 1))

        let offset = try JSONDecoder().decode(
            FilmMarkNormalizedOffset.self,
            from: Data(#"{"xUnits":999999,"yUnits":-999999}"#.utf8)
        )
        #expect(offset.x == 1)
        #expect(offset.y == -1)

        let insets = try JSONDecoder().decode(
            FilmMarkNormalizedInsets.self,
            from: Data(#"{"top":2,"left":-1,"bottom":0.25,"right":0.5}"#.utf8)
        )
        #expect(insets.top == 1)
        #expect(insets.left == 0)
        #expect(insets.bottom == 0.25)
        #expect(insets.right == 0.5)

        let fontSize = try JSONDecoder().decode(
            FilmMarkFontSize.self,
            from: Data(#"{"canvasWidthRatioUnits":999999}"#.utf8)
        )
        #expect(fontSize.canvasWidthRatioUnits == 600)
    }

    @Test("keeps color alpha as the single transparency source")
    func keepsColorAlphaAsSingleTransparencySource() {
        let appearance = FilmMarkAppearanceDraft(
            color: FilmMarkRGBAColor(
                red: 0.2,
                green: 0.4,
                blue: 0.8,
                alpha: 0.72
            )
        )

        #expect(appearance.color.alpha == 0.72)
        #expect(appearance.substrate == .none)
    }

    @Test("round trips persisted FM drafts without SwiftUI color values")
    func roundTripsPersistedDrafts() throws {
        let appearance = FilmMarkAppearanceDraft(
            fontID: .spaceMono,
            fontSize: .large,
            color: FilmMarkRGBAColor(
                red: 0.92,
                green: 0.36,
                blue: 0.12,
                alpha: 0.9
            ),
            substrate: .softShadow
        )
        let placement = FilmMarkPlacementDraft(
            anchor: .bottomLeft,
            normalizedOffset: .init(x: -0.015, y: 0.01)
        )
        let payload: [String: AnyCodableTestValue] = [
            "appearance": .appearance(appearance),
            "placement": .placement(placement)
        ]

        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(
            [String: AnyCodableTestValue].self,
            from: data
        )

        #expect(decoded["appearance"] == .appearance(appearance))
        #expect(decoded["placement"] == .placement(placement))
    }

    @Test("keeps new substrate choices Codable and preserves deterministic export identity")
    func keepsSubstrateChoicesCodable() throws {
        let paperWhite = try JSONDecoder().decode(
            FilmMarkSubstrate.self,
            from: Data(#""paperWhite""#.utf8)
        )
        let systemGlass = try JSONDecoder().decode(
            FilmMarkSubstrate.self,
            from: Data(#""systemGlass""#.utf8)
        )

        #expect(paperWhite == .paperWhite)
        #expect(systemGlass == .systemGlass)
        #expect(systemGlass.deterministicExportKind == .systemGlass)
        #expect(FilmMarkSubstrate.none.deterministicExportKind == .none)
        #expect(FilmMarkSubstrate.userSelectableCases.count == 3)
        #expect(!FilmMarkSubstrate.userSelectableCases.contains(.systemGlass))
        #expect(!FilmMarkSubstrate.userSelectableCases.contains(.translucentLabel))
    }

    @Test("resolves substrate geometry outside the content frame")
    func resolvesSubstrateGeometryOutsideContentFrame() {
        let paperWhite = FilmMarkResolvedPresentation(
            canvasSize: CGSize(width: 1_200, height: 450),
            content: .init(primaryOutput: "2026/09/16 21:29"),
            appearance: .init(
                fontSize: .standard,
                substrate: .paperWhite
            ),
            measuredContentSize: CGSize(width: 360, height: 54),
            placement: .init(anchor: .bottomRight)
        )
        let transparent = FilmMarkResolvedPresentation(
            canvasSize: CGSize(width: 1_200, height: 450),
            content: .init(primaryOutput: "2026/09/16 21:29"),
            appearance: .init(
                fontSize: .standard,
                substrate: .none
            ),
            measuredContentSize: CGSize(width: 360, height: 54),
            placement: .init(anchor: .bottomRight)
        )

        #expect(paperWhite.layout.substrateFrame.contains(paperWhite.layout.frame))
        #expect(paperWhite.layout.substrateFrame.width > paperWhite.layout.frame.width)
        #expect(paperWhite.layout.substrateFrame.height > paperWhite.layout.frame.height)
        #expect(transparent.layout.substrateFrame == transparent.layout.frame)
    }

    @Test("resolves one immutable presentation for preview and export")
    func resolvesOneImmutablePresentationForPreviewAndExport() {
        let presentation = FilmMarkResolvedPresentation(
            canvasSize: CGSize(width: 4_000, height: 3_000),
            content: .init(primaryOutput: "2026/08/16 21:29"),
            appearance: .init(
                fontID: .ibmPlexMono,
                fontSize: .standard,
                color: .white
            ),
            measuredContentSize: CGSize(width: 720, height: 96),
            placement: .init(anchor: .bottomRight)
        )

        #expect(presentation.canvasSize == CGSize(width: 4_000, height: 3_000))
        #expect(presentation.typography.fontID == .systemMonospaced)
        #expect(abs(presentation.typography.pointSize - 54) < 0.0001)
        #expect(presentation.layout.anchor == .bottomRight)
        #expect(presentation.content.primaryOutput == "2026/08/16 21:29")
    }

    @Test("production FilmMark rasterization fails closed when its context is unavailable")
    func productionFilmMarkRasterizationFailsClosedWhenContextIsUnavailable() {
        let presentation = FilmMarkResolvedPresentation(
            canvasSize: CGSize(width: 1_200, height: 450),
            content: .init(primaryOutput: "2026/08/16 21:29"),
            appearance: .init(fontSize: .standard),
            measuredContentSize: CGSize(width: 360, height: 54),
            placement: .init(anchor: .bottomRight)
        )

        #expect(throws: FilmMarkRasterizationError.contextUnavailable) {
            try FilmMarkRasterRenderer.render(
                presentation: presentation,
                contextFactory: { _, _, _ in nil }
            )
        }
    }

    @Test("FM export overlay keeps the same top-leading origin as preview")
    func exportOverlayKeepsTopLeadingOrigin() throws {
        let source = try Self.source(
            at: "Source/MemoMark/MemoMark/Renderers/FilmMarkRenderer.swift"
        )
        let overlaySource = try #require(
            source.components(separatedBy: "struct FilmMarkCardOverlayLayerRenderer")
                .dropFirst()
                .first
        )
        let overlayImplementation = try #require(
            overlaySource.components(separatedBy: "private struct FilmMarkTextLayer")
                .first
        )

        #expect(
            overlayImplementation.contains("alignment: .topLeading")
        )
    }

    @MainActor
    @Test("content-strip preview visibly draws authored output inside its compact bounds")
    func contentStripPreviewDrawsTextInsideCompactBounds() throws {
        func bitmap(_ text: String) throws -> NSBitmapImageRep {
            let renderer = ImageRenderer(content: FilmMarkPreviewSurface(
                content: .init(primaryOutput: text),
                configuration: .init(appearance: .init(fontSize: .prominent))
            ).frame(width: 400, height: 51))
            renderer.scale = 1
            return NSBitmapImageRep(cgImage: try #require(renderer.cgImage))
        }
        let first = try bitmap("2026/09/16 21:29 · 途途1岁6天")
        let second = try bitmap("2026/09/17 21:29 · 途途1岁6天")
        var changedPixels: [(Int, Int)] = []
        for y in 0..<second.pixelsHigh {
            for x in 0..<second.pixelsWide {
                let before = try #require(first.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB))
                let after = try #require(second.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB))
                if abs(before.redComponent - after.redComponent)
                    + abs(before.greenComponent - after.greenComponent)
                    + abs(before.blueComponent - after.blueComponent) > 0.08 {
                    changedPixels.append((x, y))
                }
            }
        }
        // The compact mode is a readable content strip rather than a 1:1
        // layout calibration; authored changes must still be visible inside
        // its shared Classic White preview height.
        #expect(changedPixels.count > 5)
        #expect(changedPixels.allSatisfy { $0.0 >= 0 && $0.0 < 400 && $0.1 >= 0 && $0.1 < 51 })
    }

    private static func source(at relativePath: String) throws -> String {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}

private struct LegacyFilmMarkContentPayload: Codable {
    let schemaVersion: Int
    let primaryOutput: TemplateArea
}

private enum AnyCodableTestValue: Codable, Equatable {
    case appearance(FilmMarkAppearanceDraft)
    case placement(FilmMarkPlacementDraft)

    private enum CodingKeys: String, CodingKey {
        case kind
        case value
    }

    private enum Kind: String, Codable {
        case appearance
        case placement
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .appearance(let value):
            try container.encode(Kind.appearance, forKey: .kind)
            try container.encode(value, forKey: .value)
        case .placement(let value):
            try container.encode(Kind.placement, forKey: .kind)
            try container.encode(value, forKey: .value)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .appearance:
            self = .appearance(
                try container.decode(
                    FilmMarkAppearanceDraft.self,
                    forKey: .value
                )
            )
        case .placement:
            self = .placement(
                try container.decode(
                    FilmMarkPlacementDraft.self,
                    forKey: .value
                )
            )
        }
    }
}
