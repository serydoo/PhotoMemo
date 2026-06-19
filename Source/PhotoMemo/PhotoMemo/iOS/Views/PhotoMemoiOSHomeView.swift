#if os(iOS)
import SwiftUI

struct PhotoMemoiOSHomeView: View {

    @ObservedObject
    var runtime: PhotoMemoAppRuntime

    var body: some View {

        PhotoMemoRootSceneView(
            runtime: runtime
        )
    }
}
#endif
