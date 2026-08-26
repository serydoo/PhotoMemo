import Foundation

#if !MEMOMARK_SHARE_EXTENSION
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
    /// Compatibility-only presentation text derived from the explicit output
    /// language at calculation time. New output paths must use the semantic
    /// fields and project through the Formatter/Narrative layers instead.
    let displayText: String
    let relativeSnapshot:
        MemoryAnchorRelativeSnapshot

    var narrativeOccurrence:
        MemoryNarrativeOccurrence {
        switch kind {
        case .countdown:
            return .countdown
        case .birthdayAge:
            return relativeSnapshot.isOnAnchorDay
                ? .birthDay
                : .elapsed
        case .relationshipDuration,
             .marriageDuration,
             .examDuration,
             .customDuration:
            return relativeSnapshot.isOnAnchorDay
                ? .anchorDay
                : .elapsed
        }
    }
}
#endif
