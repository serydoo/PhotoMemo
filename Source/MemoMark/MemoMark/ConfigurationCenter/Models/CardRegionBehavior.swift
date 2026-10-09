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

#if !MEMOMARK_SHARE_EXTENSION
    var inspectorProvider: InspectorProvider {
        InspectorProvider(region: region)
    }

#endif

    var accessibilityIdentifier: String {
        region.accessibilityIdentifier
    }

    var accessibilityLabel: String {
        region.accessibilityLabel
    }
}
