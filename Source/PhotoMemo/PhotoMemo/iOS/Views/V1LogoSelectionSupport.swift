#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import PhotosUI
import SwiftUI

struct V1LogoSelectionUpdate {

    let customLogoBadge: Badge?

    let logoMode: V1LogoMode?

    let logoStatusMessage: String

    let activeConfigurationStatus:
        V1ConfigurationStatus?
}

enum V1LogoSelectionCoordinator {

    static func optimize(
        _ item: PhotosPickerItem
    ) async -> V1LogoSelectionUpdate {
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

            return V1LogoSelectionUpdate(
                customLogoBadge:
                    optimizedAsset.badge,
                logoMode: .customUpload,
                logoStatusMessage:
                    "\(optimizedAsset.pixelSize) × \(optimizedAsset.pixelSize) PNG 已优化",
                activeConfigurationStatus:
                    .dirty
            )
        } catch {
            return V1LogoSelectionUpdate(
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
