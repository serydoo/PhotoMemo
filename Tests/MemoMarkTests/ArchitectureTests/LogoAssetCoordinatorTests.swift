import Foundation
import Testing
@testable import MemoMark

@MainActor
@Suite("LogoAssetCoordinator")
struct LogoAssetCoordinatorTests {

    @Test("Fixed Logo modes request a fresh image before switching to custom")
    func fixedLogoModesRequestFreshImageBeforeSwitchingToCustom() {
        for currentMode in [ConfigurationLogoMode.appleMini, .subjectAvatar] {
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
        for requestedMode in [ConfigurationLogoMode.appleMini, .subjectAvatar] {
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

        for requestedMode in [ConfigurationLogoMode.appleMini, .subjectAvatar] {
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

    @Test("runtime publishes begin and completion for the active editing context")
    func runtimePublishesBeginAndCompletion() async {
        let context = LogoAssetEditingContext(
            subjectID: UUID(),
            configurationID: UUID()
        )
        let completed = Self.completedUpdate(named: "active")
        let runtime = LogoAssetRuntimeCoordinator()
        var updates: [LogoAssetUpdate] = []

        await runtime.optimize(
            editingContext: context,
            performOptimization: { completed },
            currentContext: { context },
            discardUnappliedAsset: { _ in
                Issue.record("The active result must not be discarded.")
            },
            apply: { updates.append($0) }
        )

        #expect(updates.map(\.isOptimizingLogo) == [true, false])
        #expect(updates.last?.customLogoBadge == completed.customLogoBadge)
    }

    @Test("runtime cancellation discards a delayed optimization result")
    func runtimeCancellationDiscardsDelayedResult() async {
        let context = LogoAssetEditingContext(
            subjectID: UUID(),
            configurationID: UUID()
        )
        let completed = Self.completedUpdate(named: "cancelled")
        let gate = LogoOptimizationGate()
        let runtime = LogoAssetRuntimeCoordinator()
        var updates: [LogoAssetUpdate] = []
        var discardedBadge: Badge?

        let task = Task { @MainActor in
            await runtime.optimize(
                editingContext: context,
                performOptimization: { await gate.wait() },
                currentContext: { context },
                discardUnappliedAsset: { discardedBadge = $0 },
                apply: { updates.append($0) }
            )
        }

        await gate.waitUntilSuspended()
        runtime.cancelActiveOptimization {
            updates.append($0)
        }
        gate.resume(completed)
        await task.value

        #expect(updates.map(\.isOptimizingLogo) == [true, false])
        #expect(discardedBadge == completed.customLogoBadge)
        #expect(updates.last?.customLogoBadge == nil)
    }

    @Test("newer Logo optimization rejects the older delayed result")
    func newerOptimizationRejectsOlderDelayedResult() async {
        let context = LogoAssetEditingContext(
            subjectID: UUID(),
            configurationID: UUID()
        )
        let first = Self.completedUpdate(named: "first")
        let second = Self.completedUpdate(named: "second")
        let firstGate = LogoOptimizationGate()
        let runtime = LogoAssetRuntimeCoordinator()
        var updates: [LogoAssetUpdate] = []
        var discardedBadges: [Badge] = []

        let firstTask = Task { @MainActor in
            await runtime.optimize(
                editingContext: context,
                performOptimization: { await firstGate.wait() },
                currentContext: { context },
                discardUnappliedAsset: {
                    if let badge = $0 { discardedBadges.append(badge) }
                },
                apply: { updates.append($0) }
            )
        }

        await firstGate.waitUntilSuspended()
        await runtime.optimize(
            editingContext: context,
            performOptimization: { second },
            currentContext: { context },
            discardUnappliedAsset: {
                if let badge = $0 { discardedBadges.append(badge) }
            },
            apply: { updates.append($0) }
        )
        firstGate.resume(first)
        await firstTask.value

        #expect(updates.map(\.isOptimizingLogo) == [true, true, false])
        #expect(updates.last?.customLogoBadge == second.customLogoBadge)
        #expect(discardedBadges == [first.customLogoBadge].compactMap { $0 })
    }

    private static func completedUpdate(
        named name: String
    ) -> LogoAssetUpdate {
        LogoAssetUpdate(
            isOptimizingLogo: false,
            customLogoBadge: Badge(
                name: name,
                type: .customUpload,
                imagePath: "/tmp/LogoAssets/\(name).png"
            ),
            logoMode: .customUpload,
            logoStatusMessage: "optimized",
            activeConfigurationStatus: .dirty
        )
    }
}

@MainActor
private final class LogoOptimizationGate {

    private var continuation:
        CheckedContinuation<LogoAssetUpdate, Never>?

    func wait() async -> LogoAssetUpdate {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func waitUntilSuspended() async {
        while continuation == nil {
            await Task.yield()
        }
    }

    func resume(_ update: LogoAssetUpdate) {
        continuation?.resume(returning: update)
        continuation = nil
    }
}
