#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum DecorationKind:
    String,
    Codable,
    CaseIterable,
    Hashable {

    case icon
    case badge
    case future
}

extension DecorationKind {

    var displayTitle: String {
        switch self {
        case .icon:
            return "Icon"
        case .badge:
            return "Badge"
        case .future:
            return "Future"
        }
    }
}
#endif
