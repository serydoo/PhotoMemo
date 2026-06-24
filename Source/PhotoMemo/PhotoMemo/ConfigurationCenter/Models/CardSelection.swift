#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct CardSelection:
    Codable,
    Hashable {

    var selectedRegion: CardRegion
    var hoveredRegion: CardRegion?

    var region: CardRegion {
        selectedRegion
    }

    init(
        selectedRegion: CardRegion,
        hoveredRegion: CardRegion? = nil
    ) {
        self.selectedRegion = selectedRegion
        self.hoveredRegion = hoveredRegion
    }

    mutating func select(
        _ region: CardRegion
    ) {
        selectedRegion = region
    }

    mutating func hover(
        _ region: CardRegion?
    ) {
        hoveredRegion = region
    }

    static let defaultSelection =
        CardSelection(selectedRegion: .slotD)
}
#endif
