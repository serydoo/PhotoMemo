import Foundation
import AppKit
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("LogoAssetOptimizationService", .serialized)
struct LogoAssetOptimizationServiceTests {

    @Test("Only a generated direct Logo asset is eligible for stale-result cleanup")
    func onlyGeneratedDirectLogoAssetIsEligibleForStaleResultCleanup() {
        let logoFolderURL = URL(fileURLWithPath: "/tmp/LogoAssets")

        #expect(
            LogoAssetOptimizationService.isUncommittedAsset(
                logoFolderURL.appendingPathComponent(
                    "memomark-logo-123.png"
                ),
                in: logoFolderURL
            )
        )
        #expect(
            !LogoAssetOptimizationService.isUncommittedAsset(
                logoFolderURL.appendingPathComponent(
                    "saved-logo.png"
                ),
                in: logoFolderURL
            )
        )
        #expect(
            !LogoAssetOptimizationService.isUncommittedAsset(
                logoFolderURL.appendingPathComponent(
                    "nested/memomark-logo-123.png"
                ),
                in: logoFolderURL
            )
        )
        #expect(
            !LogoAssetOptimizationService.isUncommittedAsset(
                URL(fileURLWithPath: "/tmp/memomark-logo-123.png"),
                in: logoFolderURL
            )
        )
    }

    @Test("Defines a print-safe upload and optimization size")
    func definesPrintSafeUploadAndOptimizationSize() {

        #expect(
            LogoAssetOptimizationService
                .minimumUploadPixelSize == 1024
        )

        #expect(
            LogoAssetOptimizationService
                .recommendedUploadPixelSize == 2048
        )

        #expect(
            LogoAssetOptimizationService
                .optimizedPixelSize == 2048
        )
    }

    @Test("Estimates compact logo display size from renderer constants")
    func estimatesCompactLogoDisplaySizeFromRendererConstants() {

        let landscapeDisplayPixels =
            LogoAssetOptimizationService
            .estimatedDisplayedLogoPixels(
                outputWidth: 4032,
                orientation: .landscape
            )

        let wideFutureDisplayPixels =
            LogoAssetOptimizationService
            .estimatedDisplayedLogoPixels(
                outputWidth: 12_000,
                orientation: .portrait
            )

        #expect(
            abs(landscapeDisplayPixels - 209.2) < 0.5
        )

        #expect(
            abs(wideFutureDisplayPixels - 816.7) < 0.5
        )
    }

    @Test("Optimized custom logo has transparent circular corners")
    func optimizedCustomLogoHasTransparentCircularCorners() throws {
        let colorSpace = try #require(
            CGColorSpace(name: CGColorSpace.sRGB)
        )
        let sourceContext = try #require(
            CGContext(
                data: nil,
                width: 96,
                height: 48,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        let sourceColor = try #require(
            CGColor(
                colorSpace: colorSpace,
                components: [0, 0.48, 1, 1]
            )
        )
        sourceContext.setFillColor(sourceColor)
        sourceContext.fill(CGRect(x: 0, y: 0, width: 96, height: 48))
        let sourceCGImage = try #require(sourceContext.makeImage())
        let mutableSourceData = NSMutableData()
        let destination = try #require(
            CGImageDestinationCreateWithData(
                mutableSourceData,
                UTType.png.identifier as CFString,
                1,
                nil
            )
        )
        CGImageDestinationAddImage(destination, sourceCGImage, nil)
        #expect(CGImageDestinationFinalize(destination))
        let sourceData = mutableSourceData as Data

        let optimizedData = try LogoAssetOptimizationService
            .normalizedCircularPNGData(
                from: sourceData,
                canvasPixelSize: 128
            )
        let optimized = try #require(NSBitmapImageRep(data: optimizedData))

        #expect(optimized.pixelsWide == 128)
        #expect(optimized.pixelsHigh == 128)
        #expect((optimized.colorAt(x: 0, y: 0)?.alphaComponent ?? 1) == 0)
        #expect((optimized.colorAt(x: 64, y: 64)?.alphaComponent ?? 0) > 0.95)
    }
}
