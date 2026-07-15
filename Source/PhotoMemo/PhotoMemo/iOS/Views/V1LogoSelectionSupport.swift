#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import PhotosUI
import SwiftUI

enum V1LogoSelectionCoordinator {

    static func optimize(
        _ item: PhotosPickerItem
    ) async -> LogoAssetSelectionResult {
        let optimizer =
            LogoAssetOptimizationService()

        do {
            guard
                let data =
                    try await item.loadTransferable(
                        type: Data.self
                    )
            else {
                throw LogoAssetOptimizationError.invalidImage
            }

            let optimizedAsset =
                try await optimizer.optimize(
                    data: data
                )

            return LogoAssetSelectionResult(
                customLogoBadge:
                    optimizedAsset.badge,
                logoMode: .customUpload,
                logoStatusMessage:
                    "\(optimizedAsset.pixelSize) × \(optimizedAsset.pixelSize) PNG 已优化",
                activeConfigurationStatus:
                    .dirty
            )
        } catch {
            return LogoAssetSelectionResult(
                customLogoBadge: nil,
                logoMode: nil,
                logoStatusMessage:
                    error.localizedDescription,
                activeConfigurationStatus: nil
            )
        }
    }
}
#endif
