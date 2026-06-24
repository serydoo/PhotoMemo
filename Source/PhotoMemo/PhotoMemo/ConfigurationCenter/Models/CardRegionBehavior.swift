#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct CardRegionBehavior:
    Identifiable,
    Hashable {

    let region: CardRegion

    var id: CardRegion {
        region
    }

    var selection: CardSelection {
        CardSelection(selectedRegion: region)
    }

    var inspectorProvider: InspectorProvider {
        InspectorProvider(region: region)
    }

    var accessibilityIdentifier: String {
        region.accessibilityIdentifier
    }

    var accessibilityLabel: String {
        region.accessibilityLabel
    }
}
#endif
