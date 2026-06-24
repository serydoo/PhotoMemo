#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct IconLibraryView: View {

    @ObservedObject
    var session: ConfigurationSession

    var body: some View {
        DecorationLibraryGrid(
            title: "Icon Library",
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
