import CoreGraphics
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Classic White export bottom edge", .serialized)
struct ClassicWhiteExportBottomEdgeTests {

    struct ExportCase: CustomTestStringConvertible {
        let width: Int
        let height: Int

        var testDescription: String {
            "\(width)x\(height)"
        }
    }

    @MainActor
    @Test(
        "JPEG export ends near the opaque information-bar color",
        arguments: [
            ExportCase(width: 4032, height: 2268),
            ExportCase(width: 2268, height: 4032),
            ExportCase(width: 4031, height: 2267),
            ExportCase(width: 2267, height: 4031)
        ]
    )
    func jpegExportReadbackHasExpectedBottomEdge(
        exportCase: ExportCase
    ) throws {
        let folderURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "ClassicWhiteExportBottomEdgeTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: folderURL,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: folderURL)
        }

        let sourceURL = folderURL.appendingPathComponent("source.jpg")
        let sourceImage = try ImageEdgeAssertionSupport.solidImage(
            width: exportCase.width,
            height: exportCase.height,
            red: 176,
            green: 196,
            blue: 214
        )
        try ImageEdgeAssertionSupport.writeJPEG(
            sourceImage,
            to: sourceURL
        )

        let metadata = PhotoMetadata(
            deviceBrand: "Apple",
            deviceModel: "iPhone",
            imageWidth: exportCase.width,
            imageHeight: exportCase.height
        )
        let photo = SelectedPhoto(
            sourceURL: sourceURL,
            image: PlatformImage.photoMemoImage(
                cgImage: sourceImage
            ),
            metadata: metadata
        )
        let card = RecordCard(
            metadata: metadata,
            context: MetadataContext(),
            badge: .appleClassic,
            title: "JPEG edge readback"
        )
        let exportURL = try RecordCardExportService()
            .exportToTemporaryFile(
                photo: photo,
                card: card
            )
        defer {
            try? FileManager.default.removeItem(at: exportURL)
        }

        let image = try ImageEdgeAssertionSupport.image(
            at: exportURL
        )
        let outputSize = ClassicWhiteRenderer.outputPixelSize(
            for: metadata,
            fallbackSize: CGSize(
                width: exportCase.width,
                height: exportCase.height
            )
        )
        let rows = try ImageEdgeAssertionSupport.bottomRows(
            in: image,
            count: 1
        )
        let hasExpectedBottomEdge = rows.allSatisfy { row in
            row.isApproximatelySolid(
                red: 244,
                green: 244,
                blue: 242,
                rgbTolerance: 4
            )
        }

        #expect(outputSize.width.rounded() == outputSize.width)
        #expect(outputSize.height.rounded() == outputSize.height)
        #expect(image.width == Int(outputSize.width))
        #expect(image.height == Int(outputSize.height))
        #expect(hasExpectedBottomEdge)
    }
}
