import SwiftUI
#if os(macOS)
import AppKit
#endif

#if os(macOS)
@main
struct PhotoMemoApp: App {

    @StateObject
    private var runtime =
        PhotoMemoAppRuntime()

#if os(macOS)
    @NSApplicationDelegateAdaptor(
        PhotoMemoAppDelegate.self
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

            PhotoMemoRootSceneView(
                runtime: runtime
            )
        }
    }
}
#endif
