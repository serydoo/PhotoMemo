#if !MEMOMARK_SHARE_EXTENSION
import CoreGraphics

/// Transient system geometry. This is neither a device model nor output layout truth.
struct ReservedPresentationDivision: Equatable, Sendable {
    let frame: CGRect
    let leadingMargin: CGFloat
    let trailingMargin: CGFloat
    let topMargin: CGFloat
    let bottomMargin: CGFloat
    let isActive: Bool
}

struct ReservedPresentationRegionAllocation: Equatable, Sendable {
    let arrangement: ConfigurationContentArrangement
    let primary: CGRect
    let secondary: CGRect
}

enum ReservedPresentationRegionPolicy {
    static func supportsNativeWidePresentation(viewport: CGSize, divisions: [ReservedPresentationDivision]) -> Bool {
        // An inactive native division still proves inner-display capacity;
        // activation is projected only for admission, never for content placement.
        let capacityDivisions = divisions.map {
            ReservedPresentationDivision(frame: $0.frame, leadingMargin: $0.leadingMargin,
                trailingMargin: $0.trailingMargin, topMargin: $0.topMargin,
                bottomMargin: $0.bottomMargin, isActive: true)
        }
        return allocation(viewport: viewport, divisions: capacityDivisions) != nil
    }

    static func allocation(viewport: CGSize, divisions: [ReservedPresentationDivision],
        minimumRegionWidth: CGFloat = 350, minimumRegionHeight: CGFloat = 260) -> ReservedPresentationRegionAllocation? {
        guard viewport.width.isFinite, viewport.height.isFinite,
              viewport.width > 0, viewport.height > 0,
              minimumRegionWidth.isFinite, minimumRegionHeight.isFinite,
              minimumRegionWidth > 0, minimumRegionHeight > 0 else { return nil }
        let active = divisions.filter(\.isActive)
        guard active.count == 1, let division = active.first else { return nil }
        let frame = division.frame
        guard [frame.minX, frame.minY, frame.width, frame.height,
               division.leadingMargin, division.trailingMargin, division.topMargin, division.bottomMargin].allSatisfy(\.isFinite),
              frame.width >= 0, frame.height >= 0,
              division.leadingMargin >= 0, division.trailingMargin >= 0,
              division.topMargin >= 0, division.bottomMargin >= 0 else { return nil }
        let width = viewport.width, height = viewport.height
        let primary: CGRect, secondary: CGRect, arrangement: ConfigurationContentArrangement
        if frame.width < frame.height, frame.minY <= 0, frame.maxY >= height {
            let lower = max(0, frame.minX - division.leadingMargin)
            let upper = min(width, frame.maxX + division.trailingMargin)
            guard lower <= upper else { return nil }
            primary = CGRect(x: 0, y: 0, width: lower, height: height)
            secondary = CGRect(x: upper, y: 0, width: width - upper, height: height)
            arrangement = .sideBySide
        } else if frame.height <= frame.width, frame.minX <= 0, frame.maxX >= width {
            let lower = max(0, frame.minY - division.topMargin)
            let upper = min(height, frame.maxY + division.bottomMargin)
            guard lower <= upper else { return nil }
            primary = CGRect(x: 0, y: 0, width: width, height: lower)
            secondary = CGRect(x: 0, y: upper, width: width, height: height - upper)
            arrangement = .stacked
        } else { return nil }
        guard primary.width >= minimumRegionWidth, secondary.width >= minimumRegionWidth,
              primary.height >= minimumRegionHeight, secondary.height >= minimumRegionHeight else { return nil }
        return ReservedPresentationRegionAllocation(arrangement: arrangement, primary: primary, secondary: secondary)
    }
}

#if os(iOS)
import SwiftUI

enum SystemPresentationRegions {
    static func allocation(in geometry: GeometryProxy) -> ReservedPresentationRegionAllocation? {
        if #available(iOS 27.1, *) { return ReservedPresentationRegionReader.allocation(in: geometry) }
        return nil
    }
    static func supportsNativeWidePresentation(in geometry: GeometryProxy, windowViewport: CGSize?) -> Bool {
        if #available(iOS 27.1, *) { return ReservedPresentationRegionReader.supportsNativeWidePresentation(in: geometry, windowViewport: windowViewport) }
        return false
    }
}

/// Keeps the existing child identities; only system-supplied placement changes.
struct ReservedPresentationRegionLayout: Layout {
    let allocation: ReservedPresentationRegionAllocation
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        CGSize(width: proposal.width ?? max(allocation.primary.maxX, allocation.secondary.maxX),
               height: proposal.height ?? max(allocation.primary.maxY, allocation.secondary.maxY))
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (index, view) in subviews.enumerated() {
            let region: CGRect
            if index == 0 { region = allocation.primary }
            else if index == subviews.count - 1 { region = allocation.secondary }
            else { region = .zero } // Existing separator stays in the subtree but outside the fold.
            view.place(at: CGPoint(x: bounds.minX + region.minX, y: bounds.minY + region.minY),
                anchor: .topLeading, proposal: ProposedViewSize(width: region.width, height: region.height))
        }
    }
}

@available(iOS 27.1, *)
enum ReservedPresentationRegionReader {
    static func supportsNativeWidePresentation(in geometry: GeometryProxy, windowViewport: CGSize?) -> Bool {
        ReservedPresentationRegionPolicy.supportsNativeWidePresentation(viewport: windowViewport ?? geometry.size,
            divisions: divisions(in: geometry, includingInactive: true))
    }

    static func allocation(in geometry: GeometryProxy) -> ReservedPresentationRegionAllocation? {
        // Keyboard occlusion reduces live pane capacity but must not remove the fold gap.
        ReservedPresentationRegionPolicy.allocation(viewport: geometry.size,
            divisions: divisions(in: geometry), minimumRegionWidth: 1, minimumRegionHeight: 1)
    }

    static func divisions(in geometry: GeometryProxy, includingInactive: Bool = false) -> [ReservedPresentationDivision] {
        geometry.reservedRegions(kind: .division, options: includingInactive ? .includeInactive : []).map {
            ReservedPresentationDivision(frame: $0.frame, leadingMargin: $0.margins.leading,
                trailingMargin: $0.margins.trailing, topMargin: $0.margins.top,
                bottomMargin: $0.margins.bottom, isActive: $0.isActive)
        }
    }
}
#endif
#endif
