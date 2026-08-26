#if os(iOS)
import WidgetKit
import SwiftUI

@main
struct MemoMarkWidgetExtensionBundle:
    WidgetBundle {

    var body: some Widget {
        MemoMarkLiveActivityWidgetDefinition()
    }
}
#endif
