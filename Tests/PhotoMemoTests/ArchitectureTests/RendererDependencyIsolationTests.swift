import Foundation
import Testing
@testable import PhotoMemo

@Suite("PI-2 Renderer Dependency Isolation")
struct RendererDependencyIsolationTests {

    @Test("Boundary CardTextBlockEngine depends on ExpressionLookup at approved seam")
    func boundaryCardTextBlockEngineDependsOnExpressionLookupAtApprovedSeam() throws {
        let source =
            try sourceFile(
                "Source/PhotoMemo/PhotoMemo/Engines/CardTextBlockEngine.swift"
            )

        #expect(source.contains("ExpressionLookup"))
        #expect(!source.contains("context: MetadataContext"))
        #expect(!source.contains("context = CardVariableProvider"))
        #expect(!source.contains("variableEngine.render(\n                        item.value,\n                        context:"))
    }

    @Test("Boundary concrete renderers do not learn expression storage")
    func boundaryConcreteRenderersDoNotLearnExpressionStorage() throws {
        let rendererFiles = [
            "Source/PhotoMemo/PhotoMemo/Renderers/RecordCardRenderer.swift",
            "Source/PhotoMemo/PhotoMemo/Renderers/ClassicWhiteCardRenderer.swift",
            "Source/PhotoMemo/PhotoMemo/Renderers/ImmersWhiteRenderer.swift"
        ]

        for file in rendererFiles {
            let source =
                try sourceFile(file)

            #expect(!source.contains("ExpressionContext"))
            #expect(!source.contains("valuesByToken"))
            #expect(!source.contains("[ExpressionToken"))
        }
    }

    @Test("Regression template rendering through lookup matches legacy metadata context rendering")
    func regressionTemplateRenderingThroughLookupMatchesLegacyMetadataContextRendering() {
        let engine =
            TemplateVariableEngine()
        let context =
            MetadataContext(
                values: [
                    "model": "iPhone 17 Pro",
                    "capture_date_short": "2026.06.20"
                ]
            )
        let lookup =
            MockExpressionLookup(
                valuesByToken: [
                    "model": ExpressionValue(
                        token: "model",
                        resolvedText: "iPhone 17 Pro"
                    ),
                    "capture_date_short": ExpressionValue(
                        token: "capture_date_short",
                        resolvedText: "2026.06.20"
                    )
                ]
            )
        let template =
            "{{model}} · {{capture_date_short}} · {{missing_token}}"

        #expect(
            engine.render(
                template,
                lookup: lookup
            )
            == engine.render(
                template,
                context: context
            )
        )
    }

    @Test("Regression CardTextBlockEngine output remains unchanged")
    func regressionCardTextBlockEngineOutputRemainsUnchanged() {
        let template =
            Template(
                preset: .template2,
                name: "PI-2 Regression",
                leftTopArea: TemplateArea(
                    name: "Left Top",
                    items: [
                        TemplateItem(
                            type: .variable,
                            name: "Camera",
                            value: "{{model}} · {{missing_token}}"
                        )
                    ]
                ),
                leftBottomArea: .empty,
                rightTopArea: .empty,
                rightBottomArea: .empty,
                badgeArea: .empty
            )
        let card =
            RecordCard(
                template: template,
                metadata: PhotoMetadata(),
                context: MetadataContext(
                    values: [
                        "model": "iPhone 17 Pro"
                    ]
                )
            )

        let blocks =
            CardTextBlockEngine()
            .build(
                from: card
            )

        #expect(blocks.count == 1)
        #expect(blocks.first?.area == .leftTop)
        #expect(blocks.first?.value == "iPhone 17 Pro ·")
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

private func sourceFile(
    _ relativePath: String
) throws -> String {

    try String(
        contentsOfFile:
            "/Users/rui/Desktop/PhotoMemo/\(relativePath)",
        encoding: .utf8
    )
}
