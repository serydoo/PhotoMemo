#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct ConfigurationCenterRegionComposerSection:
    View {

    let region: CardRegion
    let configurationOptions: [IOSRegionConfigurationOption]
    @Binding var selectedConfigurationID: String
    @Binding var configurationName: String
    @Binding var isRenamingConfiguration: Bool
    let isSaved: Bool
    @Binding var text: String
    @Binding var continuationText: String
    @Binding var modules: [IOSInsertedModule]
    let showsMemorySystemModules: Bool
    let onSaveConfiguration: () -> Void
    let onDeleteModule: (IOSInsertedModule) -> Void

    var body: some View {
        IOSRegionComposer(
            region: region,
            configurationOptions:
                configurationOptions,
            selectedConfigurationID:
                $selectedConfigurationID,
            configurationName:
                $configurationName,
            isRenamingConfiguration:
                $isRenamingConfiguration,
            isSaved: isSaved,
            text: $text,
            continuationText:
                $continuationText,
            modules: $modules,
            showsMemorySystemModules:
                showsMemorySystemModules,
            onSaveConfiguration:
                onSaveConfiguration,
            onDeleteModule:
                onDeleteModule
        )
    }
}
#endif
