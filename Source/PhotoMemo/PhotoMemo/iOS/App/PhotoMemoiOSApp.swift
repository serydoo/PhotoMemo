#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

@main
struct PhotoMemoiOSApp: App {

    @StateObject
    private var runtime =
        PhotoMemoAppRuntime()

    var body: some Scene {

        WindowGroup {
            PhotoMemoiOSHomeView(
                runtime: runtime
            )
        }
    }
}
#endif
