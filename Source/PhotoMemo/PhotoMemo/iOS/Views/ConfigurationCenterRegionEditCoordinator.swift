#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct ConfigurationCenterRegionEditCoordinator {

    let previewHelper:
        ConfigurationCenterPreviewCompositionHelper

    func setText(
        _ text: String,
        for region: CardRegion,
        store: ConfigurationCenterRegionDraftStore
    ) -> ConfigurationCenterPreviewCompositionUpdate {
        var updatedStore = store
        updatedStore.setText(
            text,
            for: region
        )
        return makeUpdate(
            for: region,
            store: updatedStore
        )
    }

    func setModules(
        _ modules: [IOSInsertedModule],
        for region: CardRegion,
        store: ConfigurationCenterRegionDraftStore
    ) -> ConfigurationCenterPreviewCompositionUpdate {
        var updatedStore = store
        updatedStore.setModules(
            modules,
            for: region
        )
        return makeUpdate(
            for: region,
            store: updatedStore
        )
    }

    func setContinuationText(
        _ text: String,
        for region: CardRegion,
        store: ConfigurationCenterRegionDraftStore
    ) -> ConfigurationCenterPreviewCompositionUpdate {
        var updatedStore = store
        updatedStore.setContinuationText(
            text,
            for: region
        )
        return makeUpdate(
            for: region,
            store: updatedStore
        )
    }

    func setSelectedConfigurationID(
        _ configurationID: String,
        for region: CardRegion,
        store: ConfigurationCenterRegionDraftStore
    ) -> ConfigurationCenterPreviewCompositionUpdate {
        var updatedStore = store
        updatedStore.setSelectedConfigurationID(
            configurationID,
            for: region
        )
        return makeUpdate(
            for: region,
            store: updatedStore
        )
    }

    func insertModule(
        _ module: IOSInsertableModule,
        into region: CardRegion,
        store: ConfigurationCenterRegionDraftStore,
        expressionConfiguration:
            ExpressionModuleConfiguration? = nil
    ) -> ConfigurationCenterPreviewCompositionUpdate {
        previewHelper.insertModule(
            module,
            into: region,
            store: store,
            expressionConfiguration:
                expressionConfiguration
        )
    }

    func removeInsertedModule(
        _ module: IOSInsertedModule,
        from region: CardRegion,
        store: ConfigurationCenterRegionDraftStore
    ) -> ConfigurationCenterPreviewCompositionUpdate {
        previewHelper.removeInsertedModule(
            module,
            from: region,
            store: store
        )
    }

    func refreshPreview(
        for region: CardRegion,
        store: ConfigurationCenterRegionDraftStore
    ) -> ConfigurationCenterPreviewCompositionUpdate {
        makeUpdate(
            for: region,
            store: store
        )
    }

    private func makeUpdate(
        for region: CardRegion,
        store: ConfigurationCenterRegionDraftStore
    ) -> ConfigurationCenterPreviewCompositionUpdate {
        ConfigurationCenterPreviewCompositionUpdate(
            store: store,
            previewText:
                previewHelper
                .composedPreviewText(
                    for: region,
                    store: store
                )
        )
    }
}
#endif
