import Foundation
import Testing
@testable import PhotoMemo

@Suite("Expression System Smoke")
struct ExpressionSystemSmokeTests {

    @Test("Given fake providers When expression context is built Then mock renderer consumes only expression context")
    func givenFakeProvidersWhenExpressionContextIsBuiltThenMockRendererConsumesOnlyExpressionContext() throws {
        let locationProvider =
            FakeExpressionProvider(
                canonicalTokens: ["location"],
                values: [
                    ExpressionValue(
                        token: "location",
                        resolvedText: "Shanghai · Pudong"
                    )
                ]
            )

        let memoryProvider =
            FakeExpressionProvider(
                canonicalTokens: ["age"],
                values: [
                    ExpressionValue(
                        token: "age",
                        resolvedText: "2岁3个月"
                    )
                ]
            )

        let context =
            try makeExpressionContext(
                providers: [
                    locationProvider,
                    memoryProvider
                ]
            )

        let renderer =
            MockExpressionRenderer(
                tokens: [
                    "location",
                    "age"
                ]
            )

        #expect(
            renderer.render(
                context: context
            )
            == "Shanghai · Pudong | 2岁3个月"
        )
    }

    @Test("Given fake providers with duplicate token When expression context is built Then duplicate is rejected")
    func givenFakeProvidersWithDuplicateTokenWhenExpressionContextIsBuiltThenDuplicateIsRejected() {
        let first =
            FakeExpressionProvider(
                canonicalTokens: ["location"],
                values: [
                    ExpressionValue(
                        token: "location",
                        resolvedText: "Shanghai · Pudong"
                    )
                ]
            )

        let second =
            FakeExpressionProvider(
                canonicalTokens: ["location"],
                values: [
                    ExpressionValue(
                        token: "location",
                        resolvedText: "Tokyo · Shibuya"
                    )
                ]
            )

        #expect {
            try makeExpressionContext(
                providers: [
                    first,
                    second
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
                    "location"
                )
        }
    }

    @Test("Boundary Given mock renderer When inspected Then it stores only semantic tokens")
    func boundaryGivenMockRendererWhenInspectedThenItStoresOnlySemanticTokens() {
        let renderer =
            MockExpressionRenderer(
                tokens: [
                    "location",
                    "age"
                ]
            )

        let labels =
            Mirror(
                reflecting: renderer
            )
            .children
            .compactMap(\.label)

        #expect(labels == ["tokens"])
    }
}

private struct FakeExpressionProvider:
    ExpressionProvider {

    let canonicalTokens: Set<ExpressionToken>

    let values: [ExpressionValue]
}

private struct MockExpressionRenderer {

    let tokens: [ExpressionToken]

    func render(
        context: ExpressionContext
    ) -> String {
        tokens
            .compactMap { token in
                context
                    .value(
                        for: token
                    )?
                    .resolvedText
            }
            .joined(
                separator: " | "
            )
    }
}

private func makeExpressionContext(
    providers: [FakeExpressionProvider]
) throws -> ExpressionContext {
    try ExpressionContext(
        values: providers
            .flatMap(\.values)
    )
}
