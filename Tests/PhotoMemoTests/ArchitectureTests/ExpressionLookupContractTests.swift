import Foundation
import Testing
@testable import PhotoMemo

@Suite("Expression Lookup Contract")
struct ExpressionLookupContractTests {

    @Test("Given expression context When used as lookup Then value is returned by token")
    func givenExpressionContextWhenUsedAsLookupThenValueIsReturnedByToken() throws {
        let lookup: any ExpressionLookup =
            try ExpressionContext(
                values: [
                    ExpressionValue(
                        token: "location",
                        resolvedText: "示例省 · 示例市"
                    )
                ]
            )

        #expect(
            lookup
                .value(
                    for: "location"
                )?
                .resolvedText
            == "示例省 · 示例市"
        )
    }

    @Test("Boundary Given expression lookup protocol When inspected Then it exposes only value lookup")
    func boundaryGivenExpressionLookupProtocolWhenInspectedThenItExposesOnlyValueLookup() throws {
        let source =
            try String(
                contentsOfFile: "/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Expression/ExpressionLookup.swift",
                encoding: .utf8
            )

        #expect(source.contains("func value("))
        #expect(!source.contains("allValues"))
        #expect(!source.contains("tokens"))
        #expect(!source.contains("valuesByToken"))
        #expect(!source.contains("mutating"))
        #expect(!source.contains("set("))
    }

    @Test("Boundary Given mock lookup When renderer stub renders Then output matches context backed lookup")
    func boundaryGivenMockLookupWhenRendererStubRendersThenOutputMatchesContextBackedLookup() throws {
        let token =
            ExpressionToken(
                rawValue: "location"
            )

        let contextLookup: any ExpressionLookup =
            try ExpressionContext(
                values: [
                    ExpressionValue(
                        token: token,
                        resolvedText: "示例省 · 示例市"
                    )
                ]
            )

        let mockLookup =
            MockExpressionLookup(
                valuesByToken: [
                    token: ExpressionValue(
                        token: token,
                        resolvedText: "示例省 · 示例市"
                    )
                ]
            )

        let renderer =
            LookupOnlyRendererStub(
                token: token
            )

        #expect(
            renderer.render(
                lookup: contextLookup
            )
            == renderer.render(
                lookup: mockLookup
            )
        )
    }
}

private struct MockExpressionLookup:
    ExpressionLookup {

    let valuesByToken: [ExpressionToken: ExpressionValue]

    func value(
        for token: ExpressionToken
    ) -> ExpressionValue? {
        valuesByToken[token]
    }
}

private struct LookupOnlyRendererStub {

    let token: ExpressionToken

    func render(
        lookup: any ExpressionLookup
    ) -> String {
        lookup
            .value(
                for: token
            )?
            .resolvedText
        ?? ""
    }
}
