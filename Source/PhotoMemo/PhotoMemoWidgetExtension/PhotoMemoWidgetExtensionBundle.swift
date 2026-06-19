#if os(iOS)
import WidgetKit
import SwiftUI

@main
struct PhotoMemoWidgetExtensionBundle:
    WidgetBundle {

    var body: some Widget {
        PhotoMemoLiveActivityWidgetDefinition()
    }
}
#endif
