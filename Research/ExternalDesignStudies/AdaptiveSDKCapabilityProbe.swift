import SwiftUI

// Research-only compile probe; never add to an application target.
// Compile for the iOS 18 deployment baseline against the selected SDK.
@available(iOS 27.1, *)
struct AdaptiveSDKCapabilityProbe: View {
    var body: some View {
        ArrangementView {
            Text("Configuration")
        } secondary: {
            Text("Preview")
        }
    }
}

@available(iOS 27.1, *)
func probeReservedRegions(_ geometry: GeometryProxy, kind: ReservedRegion.Kind) -> [ReservedRegion] {
    geometry.reservedRegions(kind: kind)
}
