#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

@main
struct PhotoMemoiOSMVPApp: App {

    @StateObject
    private var runtime =
        PhotoMemoAppRuntime()

    var body: some Scene {
        WindowGroup {
            PhotoMemoiOSHomeView(
                runtime: runtime,
                temporaryEntryStorageKey:
                    "photomemo.ios.mvp.temporaryEntry",
                temporaryEntryDefault:
                    "mvpTest"
            )
        }
    }
}
#endif
