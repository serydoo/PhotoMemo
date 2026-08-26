import SwiftUI
#if os(macOS)
import AppKit
#endif

#if os(macOS)
@main
struct MemoMarkApp: App {

    @StateObject
    private var runtime =
        MemoMarkAppRuntime()

#if os(macOS)
    @NSApplicationDelegateAdaptor(
        MemoMarkAppDelegate.self
    )
    private var appDelegate
#endif

    init() {

#if os(macOS)
        NSApplication.shared.appearance =
        NSAppearance(
                named: .aqua
            )
#endif
    }

    var body: some Scene {

        WindowGroup {

            MemoMarkRootSceneView(
                runtime: runtime
            )
        }
    }
}
#endif
