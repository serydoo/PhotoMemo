import Foundation

protocol ExpressionProvider {

    var canonicalTokens: Set<ExpressionToken> { get }
}
