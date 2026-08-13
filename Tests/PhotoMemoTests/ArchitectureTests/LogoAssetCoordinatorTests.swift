import Foundation
import Testing
@testable import PhotoMemo

@MainActor
@Suite("LogoAssetCoordinator")
struct LogoAssetCoordinatorTests {

    @Test("Fixed Logo modes request a fresh image before switching to custom")
    func fixedLogoModesRequestFreshImageBeforeSwitchingToCustom() {
        for currentMode in [V1LogoMode.appleMini, .subjectAvatar] {
            let decision = LogoAssetCoordinator().modeSelectionDecision(
                currentMode: currentMode,
                requestedMode: .customUpload
            )

            #expect(decision.nextLogoMode == nil)
            #expect(decision.shouldPresentPhotoPicker)
        }
    }

    @Test("An existing custom Logo remains unchanged until replacement succeeds")
    func existingCustomLogoRemainsUnchangedUntilReplacementSucceeds() {
        let decision = LogoAssetCoordinator().modeSelectionDecision(
            currentMode: .customUpload,
            requestedMode: .customUpload
        )

        #expect(decision.nextLogoMode == nil)
        #expect(!decision.shouldPresentPhotoPicker)
    }

    @Test("Custom Logo switches immediately to either fixed mode")
    func customLogoSwitchesImmediatelyToEitherFixedMode() {
        for requestedMode in [V1LogoMode.appleMini, .subjectAvatar] {
            let decision = LogoAssetCoordinator().modeSelectionDecision(
                currentMode: .customUpload,
                requestedMode: requestedMode
            )

            #expect(decision.nextLogoMode == requestedMode)
            #expect(!decision.shouldPresentPhotoPicker)
        }
    }

    @Test("Selecting a fixed Logo mode invalidates a pending custom optimization")
    func fixedLogoSelectionInvalidatesPendingCustomOptimization() {
        let coordinator = LogoAssetCoordinator()

        for requestedMode in [V1LogoMode.appleMini, .subjectAvatar] {
            let decision = coordinator.modeSelectionDecision(
                currentMode: .appleMini,
                requestedMode: requestedMode
            )

            #expect(decision.shouldCancelActiveOptimization)
        }
    }

    @Test("Optimization completion applies only to its original editing context")
    func optimizationCompletionAppliesOnlyToOriginalEditingContext() {
        let subjectID = UUID()
        let configurationID = UUID()
        let context = LogoAssetEditingContext(
            subjectID: subjectID,
            configurationID: configurationID
        )
        let request = LogoAssetOptimizationRequest(
            id: UUID(),
            editingContext: context
        )
        let coordinator = LogoAssetCoordinator()

        #expect(
            coordinator.shouldApplyCompletedOptimization(
                request,
                activeRequest: request,
                currentContext: context
            )
        )
        #expect(
            !coordinator.shouldApplyCompletedOptimization(
                request,
                activeRequest: request,
                currentContext: LogoAssetEditingContext(
                    subjectID: UUID(),
                    configurationID: configurationID
                )
            )
        )
        #expect(
            !coordinator.shouldApplyCompletedOptimization(
                request,
                activeRequest: request,
                currentContext: LogoAssetEditingContext(
                    subjectID: subjectID,
                    configurationID: UUID()
                )
            )
        )
        #expect(
            !coordinator.shouldApplyCompletedOptimization(
                request,
                activeRequest: LogoAssetOptimizationRequest(
                    id: UUID(),
                    editingContext: context
                ),
                currentContext: context
            )
        )
    }

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
