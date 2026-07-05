import Foundation

nonisolated struct ExpressionContext:
    Hashable,
    Codable,
    ExpressionLookup {

    let valuesByToken: [ExpressionToken: ExpressionValue]

    init(
        values: [ExpressionValue] = []
    ) throws {
        var valuesByToken: [ExpressionToken: ExpressionValue] = [:]

        for value in values {
            guard valuesByToken[value.token] == nil else {
                throw ExpressionContextError
                    .duplicateToken(
                        value.token
                    )
            }

            valuesByToken[value.token] =
                value
        }

        self.valuesByToken =
            valuesByToken
    }

    func value(
        for token: ExpressionToken
    ) -> ExpressionValue? {
        valuesByToken[token]
    }
}

nonisolated enum ExpressionContextError:
    Error,
    Equatable {

    case duplicateToken(ExpressionToken)
}
