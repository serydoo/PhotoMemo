import Foundation
import Testing
@testable import PhotoMemo

@MainActor
@Suite("LogoAssetCoordinator")
struct LogoAssetCoordinatorTests {

    @Test("Beginning optimization exposes only transient busy state")
    func beginningOptimizationExposesTransientBusyState() {
        let update = LogoAssetCoordinator().beginOptimization()

        #expect(update.isOptimizingLogo)
        #expect(update.logoStatusMessage == "正在优化 Logo")
        #expect(update.customLogoBadge == nil)
        #expect(update.logoMode == nil)
        #expect(update.activeConfigurationStatus == nil)
    }

    @Test("Successful selection maps asset and dirty configuration state")
    func successfulSelectionMapsAssetAndDirtyState() {
        let badge = Badge(
            name: "自选标识",
            type: .customUpload,
            imagePath: "/tmp/LogoAssets/logo.png"
        )
        let selection = LogoAssetSelectionResult(
            customLogoBadge: badge,
            logoMode: .customUpload,
            logoStatusMessage: "2048 × 2048 PNG 已优化",
            activeConfigurationStatus: .dirty
        )

        let update =
            LogoAssetCoordinator()
            .completeOptimization(selection)

        #expect(!update.isOptimizingLogo)
        #expect(update.customLogoBadge == badge)
        #expect(update.logoMode == .customUpload)
        #expect(update.logoStatusMessage == "2048 × 2048 PNG 已优化")
        #expect(update.activeConfigurationStatus == .dirty)
    }

    @Test("Failed selection preserves current Logo values")
    func failedSelectionPreservesCurrentLogoValues() {
        let selection = LogoAssetSelectionResult(
            customLogoBadge: nil,
            logoMode: nil,
            logoStatusMessage: "图片无效",
            activeConfigurationStatus: nil
        )

        let update =
            LogoAssetCoordinator()
            .completeOptimization(selection)

        #expect(!update.isOptimizingLogo)
        #expect(update.customLogoBadge == nil)
        #expect(update.logoMode == nil)
        #expect(update.logoStatusMessage == "图片无效")
        #expect(update.activeConfigurationStatus == nil)
    }
}
