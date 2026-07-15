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

struct LogoAssetUpdate: Hashable {
    let isOptimizingLogo: Bool
    let customLogoBadge: Badge?
    let logoMode: V1LogoMode?
    let logoStatusMessage: String
    let activeConfigurationStatus: V1ConfigurationStatus?
}

@MainActor
struct LogoAssetCoordinator {

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
