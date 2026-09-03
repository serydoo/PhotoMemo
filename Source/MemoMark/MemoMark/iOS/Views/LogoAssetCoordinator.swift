#if !MEMOMARK_SHARE_EXTENSION
import Foundation

#if os(iOS)
import PhotosUI
import SwiftUI
#endif

struct LogoAssetSelectionResult: Hashable {
    let customLogoBadge: Badge?
    let logoMode: ConfigurationLogoMode?
    let logoStatusMessage: String
    let activeConfigurationStatus: ConfigurationPersistenceStatus?
}

struct LogoModeSelectionDecision: Hashable {
    let nextLogoMode: ConfigurationLogoMode?
    let shouldPresentPhotoPicker: Bool
    let shouldCancelActiveOptimization: Bool
}

struct LogoAssetEditingContext: Hashable {
    let subjectID: UUID?
    let configurationID: UUID?
}

struct LogoAssetOptimizationRequest: Hashable, Identifiable {
    let id: UUID
    let editingContext: LogoAssetEditingContext

    init(
        id: UUID = UUID(),
        editingContext: LogoAssetEditingContext
    ) {
        self.id = id
        self.editingContext = editingContext
    }
}

struct LogoAssetUpdate: Hashable {
    let isOptimizingLogo: Bool
    let customLogoBadge: Badge?
    let logoMode: ConfigurationLogoMode?
    let logoStatusMessage: String
    let activeConfigurationStatus: ConfigurationPersistenceStatus?
}

@MainActor
struct LogoAssetCoordinator {

    func modeSelectionDecision(
        currentMode: ConfigurationLogoMode,
        requestedMode: ConfigurationLogoMode
    ) -> LogoModeSelectionDecision {
        guard requestedMode != currentMode else {
            return LogoModeSelectionDecision(
                nextLogoMode: nil,
                shouldPresentPhotoPicker: false,
                shouldCancelActiveOptimization: true
            )
        }

        if requestedMode == .customUpload {
            return LogoModeSelectionDecision(
                nextLogoMode: nil,
                shouldPresentPhotoPicker: true,
                shouldCancelActiveOptimization: true
            )
        }

        return LogoModeSelectionDecision(
            nextLogoMode: requestedMode,
            shouldPresentPhotoPicker: false,
            shouldCancelActiveOptimization: true
        )
    }

    func shouldApplyCompletedOptimization(
        _ request: LogoAssetOptimizationRequest,
        activeRequest: LogoAssetOptimizationRequest?,
        currentContext: LogoAssetEditingContext
    ) -> Bool {
        request == activeRequest
        && request.editingContext == currentContext
    }

    func beginOptimization() -> LogoAssetUpdate {
        LogoAssetUpdate(
            isOptimizingLogo: true,
            customLogoBadge: nil,
            logoMode: nil,
            logoStatusMessage: "正在优化 Logo",
            activeConfigurationStatus: nil
        )
    }

    func cancelOptimization() -> LogoAssetUpdate {
        LogoAssetUpdate(
            isOptimizingLogo: false,
            customLogoBadge: nil,
            logoMode: nil,
            logoStatusMessage: "",
            activeConfigurationStatus: nil
        )
    }

    func completeOptimization(
        _ selection: LogoAssetSelectionResult
    ) -> LogoAssetUpdate {
        LogoAssetUpdate(
            isOptimizingLogo: false,
            customLogoBadge: selection.customLogoBadge,
            logoMode: selection.logoMode,
            logoStatusMessage: selection.logoStatusMessage,
            activeConfigurationStatus:
                selection.activeConfigurationStatus
        )
    }

    #if os(iOS)
    func optimize(
        _ item: PhotosPickerItem
    ) async -> LogoAssetUpdate {
        let selection =
            await LogoAssetSelectionCoordinator
            .optimize(item)
        return completeOptimization(selection)
    }
    #endif
}

/// Owns Logo optimization request identity and stale-result cleanup without
/// owning the selected Logo, configuration, or picker presentation state.
@MainActor
final class LogoAssetRuntimeCoordinator {

    private let policy = LogoAssetCoordinator()
    private var activeRequest:
        LogoAssetOptimizationRequest?

    func optimize(
        editingContext: LogoAssetEditingContext,
        performOptimization: () async -> LogoAssetUpdate,
        currentContext: () -> LogoAssetEditingContext,
        discardUnappliedAsset: (Badge?) -> Void,
        apply: (LogoAssetUpdate) -> Void
    ) async {
        let request = LogoAssetOptimizationRequest(
            editingContext: editingContext
        )
        activeRequest = request
        apply(policy.beginOptimization())

        let completedUpdate = await performOptimization()
        let shouldApply =
            !Task.isCancelled
            && policy.shouldApplyCompletedOptimization(
                request,
                activeRequest: activeRequest,
                currentContext: currentContext()
            )

        guard shouldApply else {
            discardUnappliedAsset(
                completedUpdate.customLogoBadge
            )
            if activeRequest == request {
                activeRequest = nil
                apply(policy.cancelOptimization())
            }
            return
        }

        activeRequest = nil
        apply(completedUpdate)
    }

    func cancelActiveOptimization(
        apply: (LogoAssetUpdate) -> Void
    ) {
        guard activeRequest != nil else {
            return
        }
        activeRequest = nil
        apply(policy.cancelOptimization())
    }
}
#endif
