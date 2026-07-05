import Foundation

nonisolated struct ExpressionValue:
    Hashable,
    Codable {

    let token: ExpressionToken

    let resolvedText: String

    init(
        token: ExpressionToken,
        resolvedText: String
    ) {
        self.token =
            token
        self.resolvedText =
            resolvedText
    }
}
