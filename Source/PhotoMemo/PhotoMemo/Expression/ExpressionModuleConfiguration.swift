import Foundation

nonisolated struct ExpressionModuleConfiguration:
    Codable,
    Hashable {

    var token: ExpressionToken
    var options: [String: String]

    init(
        token: ExpressionToken,
        options: [String: String] = [:]
    ) {
        self.token = token
        self.options = options
    }
}
