#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct BadgeLibraryView: View {

    @ObservedObject
    var session: ConfigurationSession

    var body: some View {
        DecorationLibraryGrid(
            title: "Badge Library",
            decorations:
                session.state.availableDecorations
                .filter { $0.kind == .badge },
            onSelect: {
                session.selectDecoration($0)
            }
        )
    }
}
#endif
