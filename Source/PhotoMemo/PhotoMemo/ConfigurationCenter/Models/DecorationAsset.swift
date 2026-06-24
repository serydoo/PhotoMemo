#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum DecorationSource:
    String,
    Codable,
    CaseIterable,
    Hashable {

    case systemLibrary
    case userLibrary
    case uploadPNG
}

enum DecorationStrategy:
    String,
    Codable,
    CaseIterable,
    Hashable {

    case autoMatch
    case fixed
    case none
    case overrideCurrentExport
}

struct DecorationAsset:
    Identifiable,
    Codable,
    Hashable {

    let id: UUID
    var kind: DecorationKind
    var source: DecorationSource
    var strategy: DecorationStrategy
    var title: String
    var systemSymbolName: String

    init(
        id: UUID = UUID(),
        kind: DecorationKind,
        source: DecorationSource = .systemLibrary,
        strategy: DecorationStrategy = .autoMatch,
        title: String,
        systemSymbolName: String
    ) {
        self.id = id
        self.kind = kind
        self.source = source
        self.strategy = strategy
        self.title = title
        self.systemSymbolName = systemSymbolName
    }
}
#endif
