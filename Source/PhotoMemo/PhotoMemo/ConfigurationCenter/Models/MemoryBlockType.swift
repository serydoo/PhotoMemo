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
            return "Text"
        case .memory:
            return "Memory"
        case .photo:
            return "Photo"
        case .system:
            return "System"
        }
    }
}
#endif
