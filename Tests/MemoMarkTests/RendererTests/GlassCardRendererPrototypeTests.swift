import CoreGraphics
import Foundation
import Testing
@testable import MemoMark

@Suite("Glass Card renderer prototype")
struct GlassCardRendererPrototypeTests {

    @Test("Calibration assets provide output pixel geometry in both orientations")
    func calibrationPixelGeometry() throws {
        for orientation in ConfigurationPreviewBackground.Orientation.allCases {
            let size = try #require(ConfigurationPreviewBackground.glassCardPixelSize(for: orientation))
            #expect(size.width > 360)
            #expect(size.height > 360)
            #expect(abs(size.width / size.height - ConfigurationPreviewBackground.aspectRatio(for: orientation)) < 0.01)
        }
    }

    @Test("Whitespace is empty without rewriting authored content")
    func whitespaceContent() {
        let content = GlassCardContentProjection(leftTop: " \n", leftBottom: "\t", rightTop: "", rightBottom: "　")
        #expect(content.isEmpty)
        #expect(content.leftTop == " \n")
    }

    @Test("Artifact eligibility reports overflowing positional text")
    func overflowingArtifactContent() {
        let content = GlassCardContentProjection(
            leftTop: String(repeating: "较长的自定义回忆内容", count: 100),
            leftBottom: "", rightTop: "", rightBottom: ""
        )
        #expect(GlassCardPrototypeAppearance.current.overflowingPositions(
            content: content, canvasSize: CGSize(width: 1080, height: 1440)
        ) == ["左上"])
    }

    @Test("Glass Card keeps one near-full-width bottom panel")
    func bottomPanelGeometry() {
        let canvas = CGSize(width: 1_920, height: 1_080)
        let frame = GlassCardLayoutSpecification.panelFrame(canvasSize: canvas)
        let layout = GlassCardLayoutSpecification.layout
        let shortEdge = min(canvas.width, canvas.height)

        #expect(
            abs(
                frame.height
                    - shortEdge * layout.panelHeightToShortEdge
            ) < 0.001
        )
        #expect(
            abs(
                frame.minX
                    - shortEdge * layout.horizontalInsetToShortEdge
            ) < 0.001
        )
        #expect(
            abs(
                canvas.height
                    - frame.maxY
                    - shortEdge * layout.bottomInsetToShortEdge
            ) < 0.001
        )
        #expect(frame.width > canvas.width * 0.95)
    }

    @Test("Glass Card internal anchors are stable across portrait and landscape canvases")
    func internalAnchorGeometry() {
        let canvases = [
            CGSize(width: 1_308, height: 1_744),
            CGSize(width: 1_744, height: 1_308)
        ]
        let layout = GlassCardLayoutSpecification.layout

        for canvas in canvases {
            let geometry = GlassCardLayoutSpecification.resolvedGeometry(
                canvasSize: canvas
            )
            let panel = geometry.panelFrame

            #expect(geometry.leftTopFrame.minX == geometry.leftBottomFrame.minX)
            #expect(geometry.leftTopFrame.width == geometry.leftBottomFrame.width)
            #expect(geometry.rightTopFrame.minX == geometry.rightBottomFrame.minX)
            #expect(geometry.rightTopFrame.width == geometry.rightBottomFrame.width)
            #expect(abs(geometry.badgeFrame.midX - panel.width * layout.badgeCenterXToPanelWidth) < 0.001)
            #expect(geometry.leftTopFrame.maxX < geometry.badgeFrame.minX)
            #expect(geometry.badgeFrame.maxX < geometry.dividerFrame.minX)
            #expect(geometry.dividerFrame.maxX < geometry.rightTopFrame.minX)
            #expect(geometry.leftTopFrame.minY < geometry.leftBottomFrame.minY)
            #expect(geometry.rightTopFrame.minY < geometry.rightBottomFrame.minY)
        }
    }

    @Test("Badge, divider and right text retain local spacing across photo aspect ratios")
    func localGroupSpacing() {
        for aspect in [9.0 / 16, 3.0 / 4, 1, 4.0 / 3, 16.0 / 9, 3] {
            let canvas = CGSize(width: 1080 * aspect, height: 1080)
            let geometry = GlassCardLayoutSpecification.resolvedGeometry(canvasSize: canvas)
            let height = geometry.panelFrame.height
            #expect(abs((geometry.dividerFrame.minX - geometry.badgeFrame.maxX) / height - 0.12) < 0.001)
            #expect(abs((geometry.rightTopFrame.minX - geometry.dividerFrame.maxX) / height - 0.12) < 0.001)
            #expect(geometry.rightTopFrame.width >= geometry.panelFrame.width * 0.39 - height * 0.46)
        }
    }

    @Test("GlassCard mark matches the measured visible reference proportion")
    func measuredMarkSize() {
        for canvas in [CGSize(width: 1080, height: 1440), CGSize(width: 1920, height: 1080)] {
            let geometry = GlassCardLayoutSpecification.resolvedGeometry(canvasSize: canvas)
            #expect(abs(geometry.badgeFrame.height / geometry.panelFrame.height - 0.40) < 0.001)
            #expect(geometry.badgeFrame.midY == geometry.panelFrame.height / 2)
        }
    }

    @Test("Glass Card divider and badge scale with the output canvas")
    func scalesInternalGeometry() {
        let preview = GlassCardLayoutSpecification.resolvedGeometry(canvasSize: CGSize(width: 360, height: 480))
        let output = GlassCardLayoutSpecification.resolvedGeometry(canvasSize: CGSize(width: 1080, height: 1440))
        #expect(abs(output.dividerFrame.width - preview.dividerFrame.width * 3) < 0.001)
        #expect(abs(output.badgeFrame.midX - preview.badgeFrame.midX * 3) < 0.001)
        #expect(abs(output.leftTopFrame.width - preview.leftTopFrame.width * 3) < 0.001)
    }

    @Test("Glass Card reports complete text fit, Unicode overflow and explicit line breaks")
    func textFitOutcomes() {
        func resolve(_ text: String, lines: Int = 1) -> GlassCardTextFitSpecification.Result {
            GlassCardTextFitSpecification.resolve(
                text: text, frame: CGSize(width: 120, height: 30),
                pointSize: 18, isPrimary: true, lineLimit: lines, minimumScale: 0.72
            )
        }
        #expect(resolve("Rui").outcome == .fits)
        #expect(resolve("  ").outcome == .empty)
        #expect(resolve(String(repeating: "回忆🌅", count: 40)).outcome == .overflow)
        #expect(resolve("第一行\n第二行").outcome == .overflow)
        #expect(resolve("Rui").pointSize == 18)
        #expect(resolve(String(repeating: "回忆🌅", count: 40)).pointSize >= 18 * 0.72)
    }

    @Test("Four-language slots preserve copy and report long content in both orientations")
    func multilingualSlotMatrix() {
        for canvas in [CGSize(width: 1080, height: 1920), CGSize(width: 1920, height: 1080)] {
            for text in ["相伴365天", "Our first walk", "大切な思い出", "함께한 추억"] {
                let short = GlassCardResolvedPresentation.resolve(
                    content: .init(leftTop: text, leftBottom: text, rightTop: text, rightBottom: text),
                    canvasSize: canvas)
                #expect(!short.isContentOverflowing)
                #expect(short.slots.allSatisfy { $0.text == text })
                let longText = String(repeating: text, count: 100)
                let long = GlassCardResolvedPresentation.resolve(
                    content: .init(leftTop: longText, leftBottom: longText, rightTop: longText, rightBottom: longText),
                    canvasSize: canvas)
                #expect(long.slots.allSatisfy { $0.text == longText && $0.fit.outcome == .overflow })
                let emptyRight = GlassCardResolvedPresentation.resolve(
                    content: .init(leftTop: text, leftBottom: "", rightTop: "", rightBottom: ""), canvasSize: canvas)
                #expect(!emptyRight.isEmpty)
                #expect(!emptyRight.isContentOverflowing)
                #expect(emptyRight.geometry == short.geometry)
            }
        }
    }

    @Test("Glass Card projects four template positions without semantic aliases")
    func projectsTemplatePositions() {
        var template = Template.classicWhite
        template.leftTopArea.items = [.story]
        template.leftBottomArea.items = [.title]
        template.rightTopArea.items = [.story]
        template.rightBottomArea.items = [.title]

        let card = RecordCard(
            template: template,
            presentationStyle: .classicWhite,
            metadata: PhotoMetadata(
                imageWidth: 4_032,
                imageHeight: 3_024
            ),
            context: MetadataContext(),
            title: "第一次自己走过这条路",
            story: "锦奕"
        )
        let content = GlassCardContentResolver.resolve(from: card)

        #expect(content.leftTop == "锦奕")
        #expect(content.leftBottom == "第一次自己走过这条路")
        #expect(content.rightTop == "锦奕")
        #expect(content.rightBottom == "第一次自己走过这条路")
    }
}
