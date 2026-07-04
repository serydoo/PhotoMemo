import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
enum MemorySemanticKind:
    String,
    Codable,
    Hashable {

    case birthdayAge
    case relationshipDuration
    case marriageDuration
    case examDuration
    case customDuration
    case countdown
}

struct MemorySemanticResult:
    Codable,
    Hashable {

    let kind: MemorySemanticKind
    let displayText: String
    let relativeSnapshot:
        MemoryAnchorRelativeSnapshot
}
#endif
