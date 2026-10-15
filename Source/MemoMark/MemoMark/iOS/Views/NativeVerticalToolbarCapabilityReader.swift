#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

enum NativeCompactRailValidation {
    static var isEnabled: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--validate-native-compact-rail")
        #else
        false
        #endif
    }
}

/// Native toolbar capability, independent of model names or saved configuration.
@available(iOS 27.1, *)
struct NativeVerticalToolbarCapabilityReader: View {
    @Environment(\.toolbarVerticalEdge) private var edge
    let onChange: (Bool) -> Void
    var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .onAppear { onChange(edge != nil) }
            .onChange(of: edge) { _, value in onChange(value != nil) }
    }
}
#endif
