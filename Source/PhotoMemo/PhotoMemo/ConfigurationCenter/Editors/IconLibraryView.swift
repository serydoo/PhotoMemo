#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct IconLibraryView: View {

    @ObservedObject
    var session: ConfigurationSession

    var body: some View {
        DecorationLibraryGrid(
            title: "图标库",
            decorations:
                session.state.availableDecorations
                .filter { $0.kind == .icon },
            onSelect: {
                session.selectDecoration($0)
            }
        )
    }
}
#endif
