#if DEBUG && os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// Explicit Simulator QA launch only; no normal-launch writes or product state.
enum NativeRegionValidationProbe {
    static func snapshot(_ geometry: GeometryProxy, window: CGSize?, verticalToolbar: Bool) -> String {
        guard ProcessInfo.processInfo.arguments.contains("--memomark-native-region-probe") else { return "" }
        var value: [String: Any] = ["viewport": [geometry.size.width, geometry.size.height],
            "window": [window?.width ?? 0, window?.height ?? 0],
            "verticalToolbarCapability": verticalToolbar,
            "deviceModel": UIDevice.current.model]
        if #available(iOS 27.1, *) {
            value["divisions"] = ReservedPresentationRegionReader.divisions(in: geometry, includingInactive: true).map {
                ["frame": [$0.frame.minX, $0.frame.minY, $0.frame.width, $0.frame.height],
                 "active": $0.isActive, "margins": [$0.leadingMargin, $0.trailingMargin, $0.topMargin, $0.bottomMargin]] as [String: Any]
            }
        }
        value["compactRail"] = NativeCompactNavigationPolicy.usesFixedRail(
            hasVerticalToolbar: verticalToolbar, isPhone: UIDevice.current.userInterfaceIdiom == .phone,
            viewport: window ?? geometry.size,
            usesWidePresentation: SystemPresentationRegions.supportsNativeWidePresentation(in: geometry, windowViewport: window))
        value["wide"] = SystemPresentationRegions.supportsNativeWidePresentation(in: geometry, windowViewport: window)
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys, .prettyPrinted]) else { return "" }
        return String(decoding: data, as: UTF8.self)
    }
    static func record(_ value: String) {
        guard !value.isEmpty,
              let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        try? value.write(to: directory.appendingPathComponent("native-region-qa.json"), atomically: true, encoding: .utf8)
    }
}
#endif
