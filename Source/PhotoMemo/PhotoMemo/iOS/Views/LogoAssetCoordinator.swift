#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

#if os(iOS)
import PhotosUI
import SwiftUI
#endif

struct LogoAssetSelectionResult: Hashable {
    let customLogoBadge: Badge?
    let logoMode: V1LogoMode?
    let logoStatusMessage: String
    let activeConfigurationStatus: V1ConfigurationStatus?
}

struct LogoModeSelectionDecision: Hashable {
    let nextLogoMode: V1LogoMode?
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
    let logoMode: V1LogoMode?
    let logoStatusMessage: String
    let activeConfigurationStatus: V1ConfigurationStatus?
}

@MainActor
struct LogoAssetCoordinator {

    func modeSelectionDecision(
        currentMode: V1LogoMode,
        requestedMode: V1LogoMode
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
            await V1LogoSelectionCoordinator
            .optimize(item)
        return completeOptimization(selection)
    }
    #endif
}
#endif
