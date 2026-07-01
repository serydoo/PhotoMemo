#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

@MainActor
enum ConfigurationCenterSelectionApplier {

    static func apply(
        _ update: ConfigurationCenterSelectionUpdate,
        session: ConfigurationSession,
        selectedPanel: inout IOSConfigurationPanel
    ) {
        if let subject = update.selectedSubject {
            session.selectSubject(subject)
        }

        if let region = update.selectedRegion {
            session.selectRegion(region)
        }

        if let panel = update.selectedPanel {
            selectedPanel = panel
        }
    }

    static func applyPreviewFocus(
        _ update: ConfigurationCenterSelectionUpdate,
        session: ConfigurationSession
    ) {
        if let region = update.selectedRegion {
            session.selectRegion(region)
        }
    }
}
#endif
