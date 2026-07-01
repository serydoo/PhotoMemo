#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct ConfigurationCenterDetailPanelSection: View {

    enum Content {
        case memoryModule(
            model: ConfigurationCenterMemoryWritePanelModel,
            usesCustomText: Binding<Bool>,
            customText: Binding<String>
        )
        case output(
            model: ConfigurationCenterOutputSelectionPanelModel,
            storageOption: Binding<ConfigurationStorageOption>
        )
        case configurationGuide(
            items: [ConfigurationCenterGuideCardModel]
        )
    }

    let title: String
    let systemImage: String
    let content: Content

    var body: some View {
        IOSDetailPanel(
            title: title,
            systemImage: systemImage
        ) {
            switch content {
            case let .memoryModule(
                model,
                usesCustomText,
                customText
            ):
                ConfigurationCenterMemoryWritePanel(
                    model: model,
                    usesCustomText: usesCustomText,
                    customText: customText
                )

            case let .output(
                model,
                storageOption
            ):
                ConfigurationCenterOutputSelectionPanel(
                    model: model,
                    storageOption: storageOption
                )

            case let .configurationGuide(items):
                ConfigurationCenterGuidePanel(
                    items: items
                )
            }
        }
    }
}
#endif
