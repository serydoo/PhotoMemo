#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum MemoryBlockType:
    String,
    Codable,
    CaseIterable,
    Hashable {

    case text
    case memory
    case photo
    case system
}

extension MemoryBlockType {

    var displayTitle: String {
        switch self {
        case .text:
            return "文本"
        case .memory:
            return "记忆"
        case .photo:
            return "照片信息"
        case .system:
            return "系统"
        }
    }
}
#endif
