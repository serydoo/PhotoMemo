import CoreGraphics
import SwiftUI
import Testing
@testable import PhotoMemo

@Suite("Classic White bottom edge", .serialized)
struct ClassicWhiteBottomEdgeTests {

    struct RenderCase: CustomTestStringConvertible {
        let width: Int
        let height: Int

        var testDescription: String {
            "\(width)x\(height)"
        }
    }

    @MainActor
    @Test(
        "Real renderer ends with opaque information-bar color at integer size",
        arguments: [
            RenderCase(width: 4032, height: 2268),
            RenderCase(width: 2268, height: 4032),
            RenderCase(width: 4031, height: 2267),
            RenderCase(width: 2267, height: 4031)
        ]
    )
    func realRendererHasExpectedBottomEdge(
        renderCase: RenderCase
    ) throws {
        let metadata = PhotoMetadata(
            deviceBrand: "Apple",
            deviceModel: "iPhone",
            imageWidth: renderCase.width,
            imageHeight: renderCase.height
        )
        let card = RecordCard(
            metadata: metadata,
            context: MetadataContext(),
            badge: .appleClassic,
            title: "Bottom edge regression"
        )
        let outputSize = ClassicWhiteRenderer.outputPixelSize(
            for: metadata,
            fallbackSize: CGSize(
                width: renderCase.width,
                height: renderCase.height
            )
        )
        let content = RecordCardRenderer(
            image: Image(systemName: "photo.fill"),
            card: card
        )
        .frame(
            width: outputSize.width,
            height: outputSize.height
        )
        let renderer = ImageRenderer(content: content)
        renderer.scale = 1
        renderer.proposedSize = .init(outputSize)
        renderer.isOpaque = true

        let image = try #require(renderer.cgImage)
        let rows = try ImageEdgeAssertionSupport.bottomRows(
            in: image,
            count: 3
        )

        let hasExpectedBottomEdge =
            rows.allSatisfy { row in
                row.isApproximatelySolid(
                    red: 244,
                    green: 244,
                    blue: 242,
                    rgbTolerance: 1
                )
            }

        #expect(outputSize.width.rounded() == outputSize.width)
        #expect(outputSize.height.rounded() == outputSize.height)
        #expect(image.width == Int(outputSize.width))
        #expect(image.height == Int(outputSize.height))
        #expect(hasExpectedBottomEdge)
    }
}
