import Foundation
import Testing
@testable import PhotoMemo

@Suite("Expression Value Contract")
struct ExpressionValueContractTests {

    @Test("Given semantic token and resolved text When expression value is created Then it is not a bare string")
    func givenSemanticTokenAndResolvedTextWhenExpressionValueIsCreatedThenItIsNotBareString() {
        let value =
            ExpressionValue(
                token: ExpressionToken(
                    rawValue: "location"
                ),
                resolvedText: "Shanghai · Pudong"
            )

        #expect(value.token == ExpressionToken(rawValue: "location"))
        #expect(value.resolvedText == "Shanghai · Pudong")
    }

    @Test("Given matching token and text When compared Then expression values are value equal")
    func givenMatchingTokenAndTextWhenComparedThenExpressionValuesAreValueEqual() {
        let first =
            ExpressionValue(
                token: "age",
                resolvedText: "2岁3个月"
            )

        let second =
            ExpressionValue(
                token: ExpressionToken(
                    rawValue: "age"
                ),
                resolvedText: "2岁3个月"
            )

        #expect(first == second)
    }

    @Test("Given expression value When encoded and decoded Then semantic token is preserved")
    func givenExpressionValueWhenEncodedAndDecodedThenSemanticTokenIsPreserved() throws {
        let value =
            ExpressionValue(
                token: "camera_model",
                resolvedText: "iPhone 17 Pro"
            )

        let data =
            try JSONEncoder()
            .encode(
                value
            )

        let decoded =
            try JSONDecoder()
            .decode(
                ExpressionValue.self,
                from: data
            )

        #expect(decoded == value)
        #expect(decoded.token == "camera_model")
        #expect(decoded.resolvedText == "iPhone 17 Pro")
    }

    @Test("Boundary Given expression value When inspected Then it is provider neutral")
    func boundaryGivenExpressionValueWhenInspectedThenItIsProviderNeutral() {
        let value =
            ExpressionValue(
                token: "location",
                resolvedText: "Shanghai · Pudong"
            )

        let labels =
            Mirror(
                reflecting: value
            )
            .children
            .compactMap(\.label)

        #expect(labels == ["token", "resolvedText"])
    }
}
