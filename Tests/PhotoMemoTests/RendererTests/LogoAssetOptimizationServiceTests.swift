import Foundation
import Testing
@testable import PhotoMemo

@Suite("LogoAssetOptimizationService")
struct LogoAssetOptimizationServiceTests {

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
}
