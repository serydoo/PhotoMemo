import Foundation

nonisolated struct ExpressionToken:
    Hashable,
    Codable,
    ExpressibleByStringLiteral {

    let rawValue: String

    init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }

    init(
        stringLiteral value: String
    ) {
        self.init(
            rawValue: value
        )
    }
}
