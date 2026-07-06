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
        #expect(source.contains("MetadataProvider"))
        #expect(source.contains("ExpressionContextMetadataAdapter"))
        #expect(!source.contains("context: MetadataContext"))
        #expect(!source.contains("context = CardVariableProvider"))
        #expect(!source.contains("variableEngine.render(\n                        item.value,\n                        context:"))
    }

    @Test("PI-13D Boundary model provider adoption stays inside approved text seam")
    func pi13dBoundaryModelProviderAdoptionStaysInsideApprovedTextSeam() throws {
        let cardTextBlockEngineSource =
            try sourceFile(
                "Source/PhotoMemo/PhotoMemo/Engines/CardTextBlockEngine.swift"
            )
        let cardVariableProviderSource =
            try sourceFile(
                "Source/PhotoMemo/PhotoMemo/Models/CardVariableProvider.swift"
            )
        let recordCardBuildServiceSource =
            try sourceFile(
                "Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift"
            )

        #expect(cardTextBlockEngineSource.contains("MetadataProvider"))
        #expect(cardTextBlockEngineSource.contains("ExpressionContextMetadataAdapter"))
        #expect(!cardVariableProviderSource.contains("MetadataProvider"))
        #expect(!recordCardBuildServiceSource.contains("MetadataProvider"))
    }

    @Test("PI-17 Boundary memory provider adoption consumes carried values without provider policy")
    func pi17BoundaryMemoryProviderAdoptionConsumesCarriedValuesWithoutProviderPolicy() throws {
        let cardTextBlockEngineSource =
            try sourceFile(
                "Source/PhotoMemo/PhotoMemo/Engines/CardTextBlockEngine.swift"
            )
        let cardVariableProviderSource =
            try sourceFile(
                "Source/PhotoMemo/PhotoMemo/Models/CardVariableProvider.swift"
            )
        let rendererSource =
            try sourceFile(
                "Source/PhotoMemo/PhotoMemo/Renderers/RecordCardRenderer.swift"
            )

        #expect(!cardTextBlockEngineSource.contains("MemoryProvider"))
        #expect(cardTextBlockEngineSource.contains("productionExpressionContext"))
        #expect(!cardVariableProviderSource.contains("productionExpressionContext"))
        #expect(!rendererSource.contains("productionExpressionContext"))
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

    @Test("PI-13D Regression CardTextBlockEngine model output matches parity-proven provider value")
    func pi13dRegressionCardTextBlockEngineModelOutputMatchesParityProvenProviderValue() throws {
        let template =
            Template(
                preset: .template2,
                name: "PI-13D Regression",
                leftTopArea: TemplateArea(
                    name: "Left Top",
                    items: [
                        TemplateItem(
                            type: .variable,
                            name: "Camera",
                            value: "{{model}}"
                        )
                    ]
                ),
                leftBottomArea: .empty,
                rightTopArea: .empty,
                rightBottomArea: .empty,
                badgeArea: .empty
            )
        let metadata =
            PhotoMetadata(
                deviceBrand: " Apple ",
                deviceModel: " iPhone 17 Pro "
            )
        let card =
            RecordCard(
                template: template,
                metadata: metadata,
                context:
                    MetadataContext
                    .build(
                        from: metadata
                    )
            )
        let providerValue =
            try #require(
                MetadataProvider()
                    .expressionValue(
                        for: MetadataProvider.modelToken,
                        metadata: metadata
                    )
            )

        let blocks =
            CardTextBlockEngine()
            .build(
                from: card
            )

        #expect(blocks.count == 1)
        #expect(blocks.first?.area == .leftTop)
        #expect(blocks.first?.value == providerValue.resolvedText)
    }

    @Test("PI-17 Regression CardTextBlockEngine memory output comes from carried provider value")
    func pi17RegressionCardTextBlockEngineMemoryOutputComesFromCarriedProviderValue() throws {
        let template =
            Template(
                preset: .template2,
                name: "PI-17 Regression",
                leftTopArea: TemplateArea(
                    name: "Left Top",
                    items: [
                        TemplateItem(
                            type: .variable,
                            name: "Memory",
                            value: "{{memory_summary}}"
                        )
                    ]
                ),
                leftBottomArea: .empty,
                rightTopArea: .empty,
                rightBottomArea: .empty,
                badgeArea: .empty
            )
        let memoryValue =
            ExpressionValue(
                token: MemoryProvider.memoryToken,
                resolvedText: "这一天，途途18天"
            )
        var card =
            RecordCard(
                template: template,
                metadata: PhotoMetadata(),
                context: MetadataContext(
                    values: [
                        MetadataContext.Key.memorySummary:
                            "legacy memory text"
                    ]
                )
            )
        card.productionExpressionContext =
            try ExpressionContext(
                values: [
                    memoryValue
                ]
            )

        let blocks =
            CardTextBlockEngine()
            .build(
                from: card
            )

        #expect(blocks.count == 1)
        #expect(blocks.first?.area == .leftTop)
        #expect(blocks.first?.value == memoryValue.resolvedText)
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
