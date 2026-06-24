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
            return "图标"
        case .badge:
            return "徽标"
        case .future:
            return "未来装饰"
        }
    }
}
#endif
