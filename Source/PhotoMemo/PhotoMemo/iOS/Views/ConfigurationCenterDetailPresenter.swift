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
                systemImage: MemoMarkSymbol.memorySubject.name,
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
                systemImage: MemoMarkSymbol.module.name,
                subtitle: "先生成 1 个智能结果，再决定承载与写入方式"
            )

        case .output:
            return ConfigurationCenterDetailPanelPresentation(
                content: .output,
                title: "输出",
                systemImage: MemoMarkSymbol.output.name,
                subtitle: "新图结果、元数据保留与相册说明写入"
            )

        case .configurationGuide:
            return ConfigurationCenterDetailPanelPresentation(
                content: .configurationGuide,
                title: "配置说明",
                systemImage: MemoMarkSymbol.help.name,
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
                systemImage: MemoMarkSymbol.memorySubject.name
            )

        case .icon:
            return ConfigurationCenterRegionEditorPresentation(
                content: .iconLibrary,
                title: "图标配置",
                systemImage: MemoMarkSymbol.memorySubject.name
            )

        case .badge:
            return ConfigurationCenterRegionEditorPresentation(
                content: .badgeLibrary,
                title: "徽标配置",
                systemImage: MemoMarkSymbol.configuration.name
            )

        case .slotA:
            return ConfigurationCenterRegionEditorPresentation(
                content: .regionComposer,
                title: "区域 A 配置",
                systemImage: MemoMarkSymbol.configuration.name
            )

        case .slotB:
            return ConfigurationCenterRegionEditorPresentation(
                content: .regionComposer,
                title: "区域 B 配置",
                systemImage: MemoMarkSymbol.timeAnchor.name
            )

        case .slotC:
            return ConfigurationCenterRegionEditorPresentation(
                content: .regionComposer,
                title: "区域 C 配置",
                systemImage: MemoMarkSymbol.photoMetadata.name
            )

        case .slotD:
            return ConfigurationCenterRegionEditorPresentation(
                content: .regionComposer,
                title: "区域 D 配置",
                systemImage: MemoMarkSymbol.memoryContent.name
            )
        }
    }
}
#endif
