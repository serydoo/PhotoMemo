#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct TimeAnchorEditingTransaction: Equatable {

    let anchorID: UUID
    let originalAnchor: MemorySubject.TimeAnchor?
    let originalSelectedAnchorID: UUID?

    var isNewAnchor: Bool {
        originalAnchor == nil
    }
}
#endif
