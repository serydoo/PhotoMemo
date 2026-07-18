#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct TimeAnchorEditingTransaction: Equatable {

    let anchorID: UUID
    let originalAnchor: MemorySubject.TimeAnchor?
    let originalSelectedAnchorID: UUID?

    var isNewAnchor: Bool {
        originalAnchor == nil
    }

    func rollback(
        anchors: [MemorySubject.TimeAnchor],
        selectedAnchorID: UUID?
    ) -> TimeAnchorEditingRollback {
        var restoredAnchors = anchors

        if let originalAnchor,
           let index = restoredAnchors.firstIndex(where: {
               $0.id == anchorID
           }) {
            restoredAnchors[index] = originalAnchor
        } else if originalAnchor == nil {
            restoredAnchors.removeAll { $0.id == anchorID }
        }

        let restoredSelection: UUID?
        if let originalSelectedAnchorID,
           restoredAnchors.contains(where: {
               $0.id == originalSelectedAnchorID
           }) {
            restoredSelection = originalSelectedAnchorID
        } else if let selectedAnchorID,
                  restoredAnchors.contains(where: {
                      $0.id == selectedAnchorID
                  }) {
            restoredSelection = selectedAnchorID
        } else {
            restoredSelection = restoredAnchors.first?.id
        }

        return TimeAnchorEditingRollback(
            anchors: restoredAnchors,
            selectedAnchorID: restoredSelection
        )
    }
}

struct TimeAnchorEditingRollback: Equatable {

    let anchors: [MemorySubject.TimeAnchor]
    let selectedAnchorID: UUID?
}
#endif
