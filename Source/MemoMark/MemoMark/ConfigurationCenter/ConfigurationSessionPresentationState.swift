#if !MEMOMARK_SHARE_EXTENSION
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

    /// Monotonically increases for every user-authored configuration edit.
    /// It is process-local and never persisted; it only fences asynchronous
    /// save receipts from reapplying an older editor snapshot.
    var editorGeneration: UInt64 = 0

    /// Durable configuration consumed by the next Share request. This is
    /// intentionally independent from the legacy "applied" draft marker.
    var processingDefaultMemoryPresetID:
        MemoryPreset.ID?

    var draftMemoryConfiguration:
        MemoryConfigurationRecord?
}
#endif
