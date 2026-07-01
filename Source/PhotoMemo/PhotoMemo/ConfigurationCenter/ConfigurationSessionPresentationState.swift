#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct ConfigurationSessionPresentationState:
    Hashable {

    var selectedOutputOption:
        ConfigurationOutputOption = .processedImage

    var selectedStorageOption:
        ConfigurationStorageOption = .appFolder

    var usesCustomMemoryWriteText = false

    var customMemoryWriteText = ""

    var latestModuleInsertion:
        MemoryModuleInsertion?

    var appliedMemoryPresetID:
        MemoryPreset.ID?
}
#endif
