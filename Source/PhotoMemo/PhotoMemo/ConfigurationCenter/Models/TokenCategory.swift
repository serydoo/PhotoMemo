#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum TokenCategory:
    String,
    Codable,
    CaseIterable,
    Identifiable,
    Hashable {

    case memory
    case photo
    case system

    var id: String {
        rawValue
    }

    var displayTitle: String {
        switch self {
        case .memory:
            return "记忆"
        case .photo:
            return "照片信息"
        case .system:
            return "系统"
        }
    }

    var blockType: MemoryBlockType {
        switch self {
        case .memory:
            return .memory
        case .photo:
            return .photo
        case .system:
            return .system
        }
    }

    init?(
        blockType: MemoryBlockType
    ) {
        switch blockType {
        case .text:
            return nil
        case .memory:
            self = .memory
        case .photo:
            self = .photo
        case .system:
            self = .system
        }
    }
}
#endif
