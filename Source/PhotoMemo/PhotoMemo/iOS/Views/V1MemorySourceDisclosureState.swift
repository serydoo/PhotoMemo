#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1MemorySourceDisclosureState: Hashable {

    private(set) var selectedSubjectID: UUID?
    private(set) var isExpanded: Bool

    init(
        selectedSubjectID: UUID? = nil,
        isExpanded: Bool = true
    ) {
        self.selectedSubjectID = selectedSubjectID
        self.isExpanded = isExpanded
    }

    mutating func setExpanded(_ isExpanded: Bool) {
        self.isExpanded = isExpanded
    }

    mutating func synchronize(
        selectedSubjectID: UUID?
    ) {
        guard self.selectedSubjectID != selectedSubjectID else {
            return
        }

        self.selectedSubjectID = selectedSubjectID
        isExpanded = true
    }
}
#endif
