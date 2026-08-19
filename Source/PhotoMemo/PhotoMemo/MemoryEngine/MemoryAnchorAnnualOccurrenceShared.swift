import Foundation

#if PHOTOMEMO_SHARE_EXTENSION
struct MemoryAnchorAnnualOccurrence: Hashable {

    let date: Date
    let yearsAtOccurrence: Int
    let daysUntilOccurrence: Int
}
#endif
