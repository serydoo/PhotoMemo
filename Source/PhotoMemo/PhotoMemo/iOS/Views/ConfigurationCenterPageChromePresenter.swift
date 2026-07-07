#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct ConfigurationCenterPageChromePresentation:
    Equatable {

    let sectionTitle: String
    let statusText: String
    let primaryActionTitle: String
    let primaryActionSystemImage: String
    let canApplyChanges: Bool
    let resetActionTitle: String
}

@MainActor
enum ConfigurationCenterPageChromePresenter {

    static func presentation(
        selectedPanel: IOSConfigurationPanel,
        session: ConfigurationSession
    ) -> ConfigurationCenterPageChromePresentation {
        let canApplyChanges =
            !session.selectedMemoryPresetIsApplied

        return ConfigurationCenterPageChromePresentation(
            sectionTitle:
                sectionTitle(for: selectedPanel),
            statusText:
                canApplyChanges
                ? "当前配置改动尚未生效"
                : "当前生效配置已同步",
            primaryActionTitle:
                canApplyChanges
                ? "保存并生效"
                : "已生效",
            primaryActionSystemImage:
                canApplyChanges
                ? "checkmark.circle"
                : "checkmark.circle.fill",
            canApplyChanges: canApplyChanges,
            resetActionTitle: "重置"
        )
    }

    private static func sectionTitle(
        for panel: IOSConfigurationPanel
    ) -> String {
        switch panel {
        case .card(let region):
            return ConfigurationCenterDetailPresenter
                .regionEditorPresentation(
                    for: region
                )
                .title

        case .subject,
             .memoryModule,
             .output,
             .configurationGuide:
            return ConfigurationCenterDetailPresenter
                .panelPresentation(for: panel)
                .title
            ?? "时光记配置中心"
        }
    }
}
#endif
