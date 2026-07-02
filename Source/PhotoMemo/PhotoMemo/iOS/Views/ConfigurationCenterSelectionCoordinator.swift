#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct ConfigurationCenterSelectionUpdate {

    var selectedPanel: IOSConfigurationPanel?
    var selectedRegion: CardRegion?
    var selectedSubject: MemorySubject?
}

struct ConfigurationCenterSelectionCoordinator {

    static func showCard(
        region: CardRegion
    ) -> ConfigurationCenterSelectionUpdate {
        ConfigurationCenterSelectionUpdate(
            selectedPanel: .card(region),
            selectedRegion: region,
            selectedSubject: nil
        )
    }

    static func showSubject(
        _ subject: MemorySubject
    ) -> ConfigurationCenterSelectionUpdate {
        ConfigurationCenterSelectionUpdate(
            selectedPanel: .subject,
            selectedRegion: nil,
            selectedSubject: subject
        )
    }

    static func showSubjectPanel()
        -> ConfigurationCenterSelectionUpdate {
        ConfigurationCenterSelectionUpdate(
            selectedPanel: .subject,
            selectedRegion: nil,
            selectedSubject: nil
        )
    }

    static func showPanel(
        _ panel: IOSConfigurationPanel
    ) -> ConfigurationCenterSelectionUpdate {
        ConfigurationCenterSelectionUpdate(
            selectedPanel: panel,
            selectedRegion: nil,
            selectedSubject: nil
        )
    }

    static func focusPreviewRegion(
        _ region: CardRegion
    ) -> ConfigurationCenterSelectionUpdate {
        ConfigurationCenterSelectionUpdate(
            selectedPanel: nil,
            selectedRegion: region,
            selectedSubject: nil
        )
    }

    static func isSelectedSubject(
        panel: IOSConfigurationPanel,
        selectedSubjectID: UUID?,
        candidateSubjectID: UUID
    ) -> Bool {
        panel == .subject
        && selectedSubjectID == candidateSubjectID
    }

    static func shouldDismissKeyboard(
        for update: ConfigurationCenterSelectionUpdate,
        currentPanel: IOSConfigurationPanel,
        currentRegion: CardRegion
    ) -> Bool {
        if let panel = update.selectedPanel,
           panel != currentPanel {
            return true
        }

        if let region = update.selectedRegion,
           region != currentRegion {
            return true
        }

        return false
    }
}
#endif
