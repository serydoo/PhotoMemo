#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

@main
struct MemoMarkiOSApp: App {

    @StateObject
    private var runtime =
        MemoMarkAppRuntime()

    var body: some Scene {

        WindowGroup {
            MemoMarkiOSHomeView(
                runtime: runtime
            )
        }
    }
}
#endif
