import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
enum MemorySemanticKind:
    String,
    Codable,
    Hashable {

    case birthdayAge
}

struct MemorySemanticResult:
    Codable,
    Hashable {

    let kind: MemorySemanticKind
    let displayText: String
}
#endif
