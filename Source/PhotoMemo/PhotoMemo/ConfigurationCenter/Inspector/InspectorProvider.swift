#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

enum InspectorProvider:
    Identifiable,
    Hashable {

    case subject
    case memoryBlock
    case iconLibrary
    case badgeLibrary

    var id: String {
        switch self {
        case .subject:
            return "subject"
        case .memoryBlock:
            return "memoryBlock"
        case .iconLibrary:
            return "iconLibrary"
        case .badgeLibrary:
            return "badgeLibrary"
        }
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
            self = .memoryBlock
        }
    }

    @ViewBuilder
    func view(
        session: ConfigurationSession
    ) -> some View {
        switch self {
        case .subject:
            MemorySubjectEditorView(session: session)
        case .memoryBlock:
            MemoryBlockInspectorView(session: session)
        case .iconLibrary:
            IconLibraryView(session: session)
        case .badgeLibrary:
            BadgeLibraryView(session: session)
        }
    }
}
#endif
