#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

@main
struct MemoMarkiOSApp: App {

    @StateObject
    private var runtime =
        MemoMarkAppRuntime()

    @State
    private var showsConfigurationPreviewReview = false

    init() {
#if DEBUG
        _showsConfigurationPreviewReview = State(
            initialValue: ProcessInfo.processInfo.arguments.contains(
                "--configuration-preview-review"
            )
        )
#else
        _showsConfigurationPreviewReview = State(initialValue: false)
#endif
    }

    var body: some Scene {

        WindowGroup {
            if showsConfigurationPreviewReview {
#if DEBUG
                ConfigurationPreviewReviewView {
                    showsConfigurationPreviewReview = false
                }
#else
                MemoMarkiOSHomeView(runtime: runtime)
#endif
            } else {
                MemoMarkiOSHomeView(runtime: runtime)
            }
        }
    }
}
#endif
