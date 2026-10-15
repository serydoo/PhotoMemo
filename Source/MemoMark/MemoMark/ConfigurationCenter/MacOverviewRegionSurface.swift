#if os(macOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// Reuses summary and progress projections without a parallel domain model.
struct MacOverviewRegionSurface<Summary: View, Progress: View>: View {
    @ScaledMetric(relativeTo: .body)
    private var minimumRegionWidth = WideOverviewLayoutPolicy.minimumRegionWidth
    @ViewBuilder var summary: Summary
    @ViewBuilder var progress: Progress

    var body: some View {
        GeometryReader { viewport in
            let horizontal = WideOverviewLayoutPolicy.arrangement(
                viewport: viewport.size, hasRegularHorizontalSizeClass: true,
                hasRegularVerticalSizeClass: true, usesAccessibilityText: false,
                minimumRegionWidth: minimumRegionWidth) == .horizontal
            let layout = horizontal
                ? AnyLayout(HStackLayout(alignment: .top, spacing: 16))
                : AnyLayout(VStackLayout(spacing: 16))
            layout {
                ScrollView { summary }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                ScrollView { progress }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: viewport.size.width, height: viewport.size.height)
        }
    }
}
#endif
