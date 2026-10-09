#if os(iOS) && DEBUG && MEMOMARK_HOST_HANDOFF_MINIMAL && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

@main
struct HostHandoffMinimalApp: App {
    init() {
        if #available(iOS 26.0, *) { HostHandoffMinimalProbe.prepareHost() }
    }
    var body: some Scene {
        WindowGroup {
            Text("MemoMark 接管探针")
                .accessibilityIdentifier("host-handoff-isolated-home")
        }
    }
}
#endif
