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

    @State private var showsNativeMaterialStudy = false

    init() {
#if DEBUG
        _showsNativeMaterialStudy = State(initialValue:ProcessInfo.processInfo.arguments.contains("--glasscard-native-material-study"))
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
            if showsNativeMaterialStudy {
#if DEBUG
                GlassCardNativeMaterialStudyView { showsNativeMaterialStudy = false }
#else
                MemoMarkiOSHomeView(runtime:runtime)
#endif
            } else if showsGlassCardPrototypeReview {
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
