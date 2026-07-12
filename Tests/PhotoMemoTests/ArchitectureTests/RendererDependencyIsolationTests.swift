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

    @Test("PI-20 Boundary location provider adoption stays inside approved text seam")
    func pi20BoundaryLocationProviderAdoptionStaysInsideApprovedTextSeam() throws {
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
        let rendererSource =
            try sourceFile(
                "Source/PhotoMemo/PhotoMemo/Renderers/RecordCardRenderer.swift"
            )

        #expect(cardTextBlockEngineSource.contains("LocationContextBuilder"))
        #expect(cardTextBlockEngineSource.contains("LocationExpressionProvider"))
        #expect(cardTextBlockEngineSource.contains(".legacyDisplay"))
        #expect(!cardVariableProviderSource.contains("LocationExpressionProvider"))
        #expect(recordCardBuildServiceSource.contains("LocationExpressionProvider"))
        #expect(!rendererSource.contains("LocationExpressionProvider"))
    }

    @Test("Boundary concrete renderers do not learn expression storage")
    func boundaryConcreteRenderersDoNotLearnExpressionStorage() throws {
        let rendererFiles = [
            "Source/PhotoMemo/PhotoMemo/Renderers/RecordCardRenderer.swift",
            "Source/PhotoMemo/PhotoMemo/Renderers/ClassicWhiteRenderer.swift"
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
                preset: .classicWhite,
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

    @Test("CardTextBlockEngine composes every custom field and module in each region")
    func cardTextBlockEngineComposesEveryItemInEachRegion() throws {
        func area(
            _ name: String,
            prefix: String,
            token: String,
            suffix: String
        ) -> TemplateArea {
            TemplateArea(
                name: name,
                items: [
                    TemplateItem(type: .text, name: "前缀", value: prefix),
                    TemplateItem(type: .variable, name: "模块", value: token),
                    TemplateItem(type: .text, name: "后缀", value: suffix)
                ]
            )
        }
        let template = Template(
            preset: .classicWhite,
            name: "完整区域组合",
            leftTopArea: area(
                "Recorder",
                prefix: "他爹手持",
                token: "{{model}}",
                suffix: "记录"
            ),
            leftBottomArea: area(
                "Timeline",
                prefix: "记录于",
                token: "{{year}}",
                suffix: "年"
            ),
            rightTopArea: area(
                "Location",
                prefix: "位于",
                token: "{{location}}",
                suffix: "拍摄"
            ),
            rightBottomArea: area(
                "Memory",
                prefix: "今天",
                token: "{{story}}",
                suffix: "啦！"
            ),
            badgeArea: .empty
        )
        let card = RecordCard(
            template: template,
            metadata: PhotoMetadata(),
            context: MetadataContext(values: [
                "model": "iPhone 17 Pro Max",
                "year": "2026",
                "location": "商丘 · 永城",
                "story": "途途1岁1个月15天"
            ])
        )

        let values = Dictionary(
            uniqueKeysWithValues:
                CardTextBlockEngine()
                .build(from: card)
                .map { ($0.area, $0.value) }
        )

        #expect(values[.leftTop] == "他爹手持iPhone 17 Pro Max记录")
        #expect(values[.leftBottom] == "记录于2026年")
        #expect(values[.rightTop] == "位于商丘 · 永城拍摄")
        #expect(values[.rightBottom] == "今天途途1岁1个月15天啦！")
    }

    @Test("PI-13D Regression CardTextBlockEngine model output matches parity-proven provider value")
    func pi13dRegressionCardTextBlockEngineModelOutputMatchesParityProvenProviderValue() throws {
        let template =
            Template(
                preset: .classicWhite,
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
                preset: .classicWhite,
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
                resolvedText: "今天途途18天"
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

    @Test("PI-20 Regression CardTextBlockEngine location output comes from legacy-compatible provider value")
    func pi20RegressionCardTextBlockEngineLocationOutputComesFromLegacyCompatibleProviderValue() throws {
        try expectCardTextLocationDisplayResolvesThroughProvider(
            metadata: PhotoMetadata(
                city: "Shenzhen",
                district: "Nanshan",
                province: "Guangdong",
                country: "China"
            )
        )

        try expectCardTextLocationDisplayResolvesThroughProvider(
            metadata: PhotoMetadata(
                city: "Shenzhen",
                district: "Nanshan",
                province: "Guangdong",
                country: "China",
                locationName: "Lujiazui"
            )
        )

        try expectCardTextLocationDisplayResolvesThroughProvider(
            metadata: PhotoMetadata(
                latitude: 22.5430964,
                longitude: 114.0578652
            )
        )
    }

    @Test("Location feature production expression context overrides legacy location display")
    func locationFeatureProductionExpressionContextOverridesLegacyLocationDisplay() throws {
        let template =
            Template(
                preset: .classicWhite,
                name: "Location Feature",
                leftTopArea: TemplateArea(
                    name: "Left Top",
                    items: [
                        TemplateItem(
                            type: .variable,
                            name: "Location",
                            value: "{{location_display}}"
                        )
                    ]
                ),
                leftBottomArea: .empty,
                rightTopArea: .empty,
                rightBottomArea: .empty,
                badgeArea: .empty
            )
        var card =
            RecordCard(
                template: template,
                metadata:
                    PhotoMetadata(
                        city: "Shenzhen",
                        district: "Nanshan",
                        province: "Guangdong",
                        country: "China"
                    ),
                context:
                    MetadataContext.build(
                        from:
                            PhotoMetadata(
                                city: "Shenzhen",
                                district: "Nanshan",
                                province: "Guangdong",
                                country: "China"
                            )
                    )
            )
        card.productionExpressionContext =
            try ExpressionContext(
                values: [
                    ExpressionValue(
                        token:
                            LocationExpressionProvider
                            .locationToken,
                        resolvedText:
                            "Shenzhen · Nanshan"
                    )
                ]
            )

        let block =
            try #require(
                CardTextBlockEngine()
                    .build(
                        from: card
                    )
                    .first
            )

        #expect(block.value == "Shenzhen · Nanshan")
    }
}

private func expectCardTextLocationDisplayResolvesThroughProvider(
    metadata: PhotoMetadata
) throws {
    let template =
        Template(
            preset: .classicWhite,
            name: "PI-20 Regression",
            leftTopArea: TemplateArea(
                name: "Left Top",
                items: [
                    TemplateItem(
                        type: .variable,
                        name: "Location",
                        value: "{{location_display}}"
                    )
                ]
            ),
            leftBottomArea: .empty,
            rightTopArea: .empty,
            rightBottomArea: .empty,
            badgeArea: .empty
        )
    let legacyText =
        MetadataContext
        .build(
            from: metadata
        )[MetadataContext.Key.locationDisplay]
    let card =
        RecordCard(
            template: template,
            metadata: metadata,
            context: MetadataContext(
                values: [
                    MetadataContext.Key.locationDisplay:
                        "stale legacy location"
                ]
            )
        )

    let block =
        try #require(
            CardTextBlockEngine()
                .build(
                    from: card
                )
                .first
        )

    #expect(block.area == .leftTop)
    #expect(block.value == legacyText)
    #expect(block.value != "stale legacy location")
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
