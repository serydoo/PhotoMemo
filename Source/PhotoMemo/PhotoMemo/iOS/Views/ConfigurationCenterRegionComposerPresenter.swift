#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct ConfigurationCenterRegionComposerProjection:
    Equatable {

    let selectedConfigurationTitle: String
    let statusSymbolName: String
    let statusTitle: String
    let usesSavedAccentStyle: Bool
    let textPlaceholder: String
    let continuationPlaceholder: String
}

struct ConfigurationCenterRegionComposerPresenter {

    static func projection(
        for region: CardRegion,
        selectedConfigurationID: String,
        configurationName: String,
        configurationOptions:
            [IOSRegionConfigurationOption],
        isSaved: Bool
    ) -> ConfigurationCenterRegionComposerProjection {
        ConfigurationCenterRegionComposerProjection(
            selectedConfigurationTitle:
                configurationOptions
                .first(where: {
                    $0.id == selectedConfigurationID
                })?
                .title
                ?? configurationName,
            statusSymbolName:
                isSaved
                ? "checkmark.circle.fill"
                : "circle",
            statusTitle:
                isSaved
                ? "已生效"
                : "未保存",
            usesSavedAccentStyle:
                isSaved,
            textPlaceholder:
                "输入或补充 \(region.semanticTitle)",
            continuationPlaceholder:
                "继续输入"
        )
    }
}
#endif
