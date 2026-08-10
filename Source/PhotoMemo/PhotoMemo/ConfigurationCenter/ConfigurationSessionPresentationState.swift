#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum ActiveConfigurationState: Equatable {
    case saved(
        subjectID: MemorySubject.ID,
        configurationID: MemoryConfigurationRecord.ID
    )
    case newDraft(
        subjectID: MemorySubject.ID,
        draftID: MemoryPreset.ID
    )
    case unavailable
}

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

    var draftMemoryConfiguration:
        MemoryConfigurationRecord?
}
#endif
