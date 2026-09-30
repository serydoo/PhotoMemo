#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

@main
struct MemoMarkiOSApp: App {

    @StateObject
    private var runtime =
        MemoMarkAppRuntime()

    @State
    private var showsConfigurationPreviewReview = false

    @State
    private var showsGlassCardPrototypeReview = false

    init() {
#if DEBUG
        _showsGlassCardPrototypeReview = State(
            initialValue: ProcessInfo.processInfo.arguments.contains("--glasscard-prototype-review")
        )
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
            if showsGlassCardPrototypeReview {
#if DEBUG
                GlassCardPrototypeReviewView {
                    showsGlassCardPrototypeReview = false
                }
#else
                MemoMarkiOSHomeView(runtime: runtime)
#endif
            } else if showsConfigurationPreviewReview {
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
