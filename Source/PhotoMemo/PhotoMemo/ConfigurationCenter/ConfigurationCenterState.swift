#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct ConfigurationCenterState:
    Hashable {

    var subjects: [MemorySubject]
    var selectedSubjectID: MemorySubject.ID?
    var cardSelection: CardSelection
    var selectedBlockID: MemoryBlock.ID?
    var tokenLibrary: TokenLibrary
    var availableDecorations: [DecorationAsset]

    var selectedSubject: MemorySubject? {
        guard let selectedSubjectID else {
            return subjects.first
        }

        return subjects.first {
            $0.id == selectedSubjectID
        } ?? subjects.first
    }

    var selectedRegion: CardRegion {
        get {
            cardSelection.selectedRegion
        }
        set {
            cardSelection.selectedRegion = newValue
        }
    }

    var hoveredRegion: CardRegion? {
        get {
            cardSelection.hoveredRegion
        }
        set {
            cardSelection.hoveredRegion = newValue
        }
    }
}
#endif
