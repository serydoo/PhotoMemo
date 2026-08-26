import Foundation

protocol ExpressionLookup {

    func value(
        for token: ExpressionToken
    ) -> ExpressionValue?
}
