#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct InteractiveMemoryCardSelection:
    Codable,
    Hashable {

    var cardSelection: CardSelection

    var region: CardRegion {
        cardSelection.region
    }

    init(
        region: CardRegion
    ) {
        self.cardSelection =
            CardSelection(selectedRegion: region)
    }
}
#endif
