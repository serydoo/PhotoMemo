#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

enum InspectorProvider:
    String,
    Identifiable,
    Hashable {

    case subject
    case expression
    case iconLibrary
    case badgeLibrary

    var id: String {
        rawValue
    }

    init(
        region: CardRegion
    ) {
        switch region {
        case .subject:
            self = .subject
        case .icon:
            self = .iconLibrary
        case .badge:
            self = .badgeLibrary
        case .slotA,
             .slotB,
             .slotC,
             .slotD:
            self = .expression
        }
    }

    @ViewBuilder
    func view(
        session: ConfigurationSession
    ) -> some View {
        switch self {
        case .subject:
            MemorySubjectEditorView(session: session)
        case .expression:
            ExpressionEditor(session: session)
        case .iconLibrary:
            IconLibraryView(session: session)
        case .badgeLibrary:
            BadgeLibraryView(session: session)
        }
    }
}
#endif
