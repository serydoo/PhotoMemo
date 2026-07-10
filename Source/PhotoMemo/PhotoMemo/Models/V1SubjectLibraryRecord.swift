#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1SubjectLibraryRecord:
    Codable,
    Hashable {

    let subjects: [MemorySubject]
    let selectedSubjectID: MemorySubject.ID?
    let memoryPresets: [MemoryPreset]
    let selectedMemoryPresetID: MemoryPreset.ID?

    init(
        subjects: [MemorySubject],
        selectedSubjectID: MemorySubject.ID?,
        memoryPresets: [MemoryPreset] = [],
        selectedMemoryPresetID: MemoryPreset.ID? = nil
    ) {
        self.subjects = subjects
        self.selectedSubjectID = selectedSubjectID
        self.memoryPresets = memoryPresets
        self.selectedMemoryPresetID =
            selectedMemoryPresetID
    }

    init(from decoder: Decoder) throws {
        let container =
            try decoder.container(
                keyedBy: CodingKeys.self
            )

        subjects =
            try container.decode(
                [MemorySubject].self,
                forKey: .subjects
            )
        selectedSubjectID =
            try container.decodeIfPresent(
                MemorySubject.ID.self,
                forKey: .selectedSubjectID
            )
        memoryPresets =
            try container.decodeIfPresent(
                [MemoryPreset].self,
                forKey: .memoryPresets
            ) ?? []
        selectedMemoryPresetID =
            try container.decodeIfPresent(
                MemoryPreset.ID.self,
                forKey: .selectedMemoryPresetID
            )
    }
}
#endif
