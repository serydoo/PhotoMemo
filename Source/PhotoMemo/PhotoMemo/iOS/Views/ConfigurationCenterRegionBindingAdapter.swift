#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct ConfigurationCenterRegionBindingMutation {

    let store: ConfigurationCenterRegionDraftStore

    let previewText: String?
}

struct ConfigurationCenterRegionBindingAdapter {

    let region: CardRegion

    let subject: MemorySubject?

    let store: ConfigurationCenterRegionDraftStore

    let coordinator: ConfigurationCenterRegionEditCoordinator

    func text() -> String {
        store.text(
            for: region,
            subject: subject
        )
    }

    func setText(
        _ text: String
    ) -> ConfigurationCenterRegionBindingMutation {
        previewMutation(
            coordinator.setText(
                text,
                for: region,
                store: store
            )
        )
    }

    func modules() -> [IOSInsertedModule] {
        store.modules(for: region)
    }

    func setModules(
        _ modules: [IOSInsertedModule]
    ) -> ConfigurationCenterRegionBindingMutation {
        previewMutation(
            coordinator.setModules(
                modules,
                for: region,
                store: store
            )
        )
    }

    func continuationText() -> String {
        store.continuationText(for: region)
    }

    func setContinuationText(
        _ text: String
    ) -> ConfigurationCenterRegionBindingMutation {
        previewMutation(
            coordinator.setContinuationText(
                text,
                for: region,
                store: store
            )
        )
    }

    func selectedConfigurationID() -> String {
        store.selectedConfigurationID(for: region)
    }

    func setSelectedConfigurationID(
        _ configurationID: String
    ) -> ConfigurationCenterRegionBindingMutation {
        previewMutation(
            coordinator.setSelectedConfigurationID(
                configurationID,
                for: region,
                store: store
            )
        )
    }

    func configurationName() -> String {
        store.configurationName(for: region)
    }

    func setConfigurationName(
        _ name: String
    ) -> ConfigurationCenterRegionBindingMutation {
        var updatedStore = store
        updatedStore.setConfigurationName(
            name,
            for: region
        )
        return .init(
            store: updatedStore,
            previewText: nil
        )
    }

    func isRenamingConfiguration() -> Bool {
        store.isRenamingConfiguration(for: region)
    }

    func setRenamingConfiguration(
        _ isRenaming: Bool
    ) -> ConfigurationCenterRegionBindingMutation {
        var updatedStore = store
        updatedStore.setRenamingConfiguration(
            isRenaming,
            for: region
        )
        return .init(
            store: updatedStore,
            previewText: nil
        )
    }

    func insertModule(
        _ module: IOSInsertableModule
    ) -> ConfigurationCenterRegionBindingMutation? {
        guard CardRegion.memoryCardRegions.contains(region) else {
            return nil
        }

        return previewMutation(
            coordinator.insertModule(
                module,
                into: region,
                store: store
            )
        )
    }

    func removeInsertedModule(
        _ module: IOSInsertedModule
    ) -> ConfigurationCenterRegionBindingMutation {
        previewMutation(
            coordinator.removeInsertedModule(
                module,
                from: region,
                store: store
            )
        )
    }

    func refreshPreview() -> ConfigurationCenterRegionBindingMutation {
        previewMutation(
            coordinator.refreshPreview(
                for: region,
                store: store
            )
        )
    }

    private func previewMutation(
        _ update: ConfigurationCenterPreviewCompositionUpdate
    ) -> ConfigurationCenterRegionBindingMutation {
        .init(
            store: update.store,
            previewText: update.previewText
        )
    }
}
#endif
