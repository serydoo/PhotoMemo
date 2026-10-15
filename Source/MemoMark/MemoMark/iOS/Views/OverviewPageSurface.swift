#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// The primary host keeps its TabView/editor identity while only the peer
/// arrangement changes. No business state or task execution lives here.
struct OverviewPageSurface<PrimaryContent: View, ProgressContent: View>: View {
    let arrangement: OverviewContentArrangement?
    let retainsProgress: Bool
    @ViewBuilder var primaryContent: PrimaryContent
    @ViewBuilder var progressContent: ProgressContent

    var body: some View {
        GeometryReader { geometry in
        let nativeAllocation = arrangement != nil && retainsProgress
            ? SystemPresentationRegions.allocation(in: geometry) : nil
        let showsProgress = arrangement != nil
        let layout = nativeAllocation.map { AnyLayout(ReservedPresentationRegionLayout(allocation: $0)) }
            ?? (arrangement == .horizontal
            ? AnyLayout(HStackLayout(alignment: .top, spacing: WideOverviewLayoutPolicy.regionSpacing))
            : AnyLayout(VStackLayout(spacing: showsProgress ? WideOverviewLayoutPolicy.regionSpacing : 0)))
        layout {
            primaryContent
                .frame(width: nativeAllocation?.primary.width, height: nativeAllocation?.primary.height)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if retainsProgress {
                progressContent
                    .frame(width: nativeAllocation?.secondary.width, height: nativeAllocation?.secondary.height)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(width: showsProgress ? nil : 0, height: showsProgress ? nil : 0)
                    .clipped()
                    .opacity(showsProgress ? 1 : 0)
                    .allowsHitTesting(showsProgress)
                    .accessibilityHidden(!showsProgress)
            }
        }
        .overlay {
            if showsProgress && nativeAllocation == nil {
                Rectangle()
                    .fill(ConfigurationUI.faintHairline)
                    .frame(width: arrangement == .horizontal ? 0.5 : nil,
                           height: arrangement == .vertical ? 0.5 : nil)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        }
    }
}
#endif
