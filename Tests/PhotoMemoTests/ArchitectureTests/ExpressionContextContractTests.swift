import Foundation
import Testing
@testable import PhotoMemo

@Suite("Expression Context Contract")
struct ExpressionContextContractTests {

    @Test("Given expression values When context is created Then values are addressable by semantic token")
    func givenExpressionValuesWhenContextIsCreatedThenValuesAreAddressableBySemanticToken() throws {
        let context =
            try ExpressionContext(
                values: [
                    ExpressionValue(
                        token: "location",
                        resolvedText: "Shanghai · Pudong"
                    ),
                    ExpressionValue(
                        token: "age",
                        resolvedText: "2岁3个月"
                    )
                ]
            )

        #expect(
            context.value(
                for: "location"
            )
            == ExpressionValue(
                token: "location",
                resolvedText: "Shanghai · Pudong"
            )
        )

        #expect(
            context.value(
                for: "age"
            )?
            .resolvedText == "2岁3个月"
        )
    }

    @Test("Given duplicate semantic tokens When context is created Then duplicate token is rejected")
    func givenDuplicateSemanticTokensWhenContextIsCreatedThenDuplicateTokenIsRejected() {
        #expect {
            try ExpressionContext(
                values: [
                    ExpressionValue(
                        token: "location",
                        resolvedText: "Shanghai · Pudong"
                    ),
                    ExpressionValue(
                        token: "location",
                        resolvedText: "Tokyo · Shibuya"
                    )
                ]
            )
        } throws: { error in
            guard
                let expressionError =
                    error as? ExpressionContextError
            else {
                return false
            }

            return expressionError
                == .duplicateToken(
                    ExpressionToken(
                        rawValue: "location"
                    )
                )
        }
    }

    @Test("Given expression context When encoded and decoded Then token map is preserved")
    func givenExpressionContextWhenEncodedAndDecodedThenTokenMapIsPreserved() throws {
        let context =
            try ExpressionContext(
                values: [
                    ExpressionValue(
                        token: "camera_model",
                        resolvedText: "iPhone 17 Pro"
                    ),
                    ExpressionValue(
                        token: "location",
                        resolvedText: "Shanghai · Pudong"
                    )
                ]
            )

        let data =
            try JSONEncoder()
            .encode(
                context
            )

        let decoded =
            try JSONDecoder()
            .decode(
                ExpressionContext.self,
                from: data
            )

        #expect(decoded == context)
        #expect(
            decoded.value(
                for: "camera_model"
            )?
            .resolvedText == "iPhone 17 Pro"
        )
    }

    @Test("Boundary Given expression context When inspected Then it stores only expression values")
    func boundaryGivenExpressionContextWhenInspectedThenItStoresOnlyExpressionValues() throws {
        let context =
            try ExpressionContext(
                values: [
                    ExpressionValue(
                        token: "location",
                        resolvedText: "Shanghai · Pudong"
                    )
                ]
            )

        let labels =
            Mirror(
                reflecting: context
            )
            .children
            .compactMap(\.label)

        #expect(labels == ["valuesByToken"])
    }
}
