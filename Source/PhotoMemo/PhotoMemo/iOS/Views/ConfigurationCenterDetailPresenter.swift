#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct ConfigurationCenterDetailPanelPresentation:
    Equatable {

    enum Content: Equatable {
        case subject
        case card
        case memoryModule
        case output
        case configurationGuide
    }

    let content: Content
    let title: String?
    let systemImage: String?
    let subtitle: String?
}

struct ConfigurationCenterRegionEditorPresentation:
    Equatable {

    enum Content: Equatable {
        case subject
        case iconLibrary
        case badgeLibrary
        case regionComposer
    }

    let content: Content
    let title: String
    let systemImage: String
}

struct ConfigurationCenterDetailPresenter {

    static func panelPresentation(
        for panel: IOSConfigurationPanel
    ) -> ConfigurationCenterDetailPanelPresentation {
        switch panel {
        case .subject:
            return ConfigurationCenterDetailPanelPresentation(
                content: .subject,
                title: "记忆对象",
                systemImage: "person.fill",
                subtitle: "对象资料与锚点维护"
            )

        case .card:
            return ConfigurationCenterDetailPanelPresentation(
                content: .card,
                title: nil,
                systemImage: nil,
                subtitle: nil
            )

        case .memoryModule:
            return ConfigurationCenterDetailPanelPresentation(
                content: .memoryModule,
                title: "智能模块",
                systemImage: "text.badge.checkmark",
                subtitle: "先生成 1 个智能结果，再决定承载与写入方式"
            )

        case .output:
            return ConfigurationCenterDetailPanelPresentation(
                content: .output,
                title: "输出",
                systemImage: "square.and.arrow.down",
                subtitle: "新图结果、元数据保留与相册说明写入"
            )

        case .configurationGuide:
            return ConfigurationCenterDetailPanelPresentation(
                content: .configurationGuide,
                title: "配置说明",
                systemImage: "questionmark.circle",
                subtitle: nil
            )
        }
    }

    static func regionEditorPresentation(
        for region: CardRegion
    ) -> ConfigurationCenterRegionEditorPresentation {
        switch region {
        case .subject:
            return ConfigurationCenterRegionEditorPresentation(
                content: .subject,
                title: "记忆对象资料",
                systemImage: "person.fill"
            )

        case .icon:
            return ConfigurationCenterRegionEditorPresentation(
                content: .iconLibrary,
                title: "图标配置",
                systemImage: "person.crop.circle"
            )

        case .badge:
            return ConfigurationCenterRegionEditorPresentation(
                content: .badgeLibrary,
                title: "徽标配置",
                systemImage: "camera.fill"
            )

        case .slotA:
            return ConfigurationCenterRegionEditorPresentation(
                content: .regionComposer,
                title: "区域 A 配置",
                systemImage: "camera.fill"
            )

        case .slotB:
            return ConfigurationCenterRegionEditorPresentation(
                content: .regionComposer,
                title: "区域 B 配置",
                systemImage: "calendar"
            )

        case .slotC:
            return ConfigurationCenterRegionEditorPresentation(
                content: .regionComposer,
                title: "区域 C 配置",
                systemImage: "scope"
            )

        case .slotD:
            return ConfigurationCenterRegionEditorPresentation(
                content: .regionComposer,
                title: "区域 D 配置",
                systemImage: "text.quote"
            )
        }
    }
}
#endif
