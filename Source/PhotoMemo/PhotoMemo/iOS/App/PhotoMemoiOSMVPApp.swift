#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

@main
struct PhotoMemoiOSMVPApp: App {

    var body: some Scene {
        WindowGroup {
            PhotoMemoiOSTemporaryEntryView(
                storageKey: "photomemo.ios.mvp.temporaryEntry",
                defaultEntry: "mvpTest"
            )
        }
    }
}
#endif
