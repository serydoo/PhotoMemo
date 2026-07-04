#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1SubjectLibraryRecord:
    Codable,
    Hashable {

    let subjects: [MemorySubject]
    let selectedSubjectID: MemorySubject.ID?

    init(
        subjects: [MemorySubject],
        selectedSubjectID: MemorySubject.ID?
    ) {
        self.subjects = subjects
        self.selectedSubjectID = selectedSubjectID
    }
}
#endif
