import Foundation
import Testing
@testable import PhotoMemo

@Suite("PI-5 Legacy Metadata Adapter")
struct ExpressionContextMetadataAdapterTests {

    @Test("Given location expression value When projected Then legacy location display is set")
    func givenLocationExpressionValueWhenProjectedThenLegacyLocationDisplayIsSet() throws {
        let expressionContext =
            try ExpressionContext(
                values: [
                    ExpressionValue(
                        token: ExpressionToken(rawValue: "location"),
                        resolvedText: "河南 · 商丘"
                    )
                ]
            )

        let metadataContext =
            ExpressionContextMetadataAdapter()
            .metadataContext(
                from: expressionContext
            )

        #expect(
            metadataContext[MetadataContext.Key.locationDisplay]
                == "河南 · 商丘"
        )
    }

    @Test("Given location expression value When rendered through legacy template Then output is unchanged")
    func givenLocationExpressionValueWhenRenderedThroughLegacyTemplateThenOutputIsUnchanged() throws {
        let expressionContext =
            try ExpressionContext(
                values: [
                    ExpressionValue(
                        token: ExpressionToken(rawValue: "location"),
                        resolvedText: "河南 · 商丘"
                    )
                ]
            )

        let metadataContext =
            ExpressionContextMetadataAdapter()
            .metadataContext(
                from: expressionContext
            )

        let rendered =
            TemplateVariableEngine()
            .render(
                "{{location_display}}",
                context: metadataContext
            )

        #expect(rendered == "河南 · 商丘")
    }

    @Test("PI-13D Given model expression value When projected Then legacy model is set")
    func pi13dGivenModelExpressionValueWhenProjectedThenLegacyModelIsSet() throws {
        let expressionContext =
            try ExpressionContext(
                values: [
                    ExpressionValue(
                        token: MetadataProvider.modelToken,
                        resolvedText: "iPhone 17 Pro"
                    )
                ]
            )

        let metadataContext =
            ExpressionContextMetadataAdapter()
            .metadataContext(
                from: expressionContext
            )

        #expect(
            metadataContext[MetadataContext.Key.model]
            == "iPhone 17 Pro"
        )
    }

    @Test("PI-17 Given memory expression value When projected Then legacy memory summary is set")
    func pi17GivenMemoryExpressionValueWhenProjectedThenLegacyMemorySummaryIsSet() throws {
        let expressionContext =
            try ExpressionContext(
                values: [
                    ExpressionValue(
                        token: MemoryProvider.memoryToken,
                        resolvedText: "今天途途18天"
                    )
                ]
            )

        let metadataContext =
            ExpressionContextMetadataAdapter()
            .metadataContext(
                from: expressionContext
            )

        #expect(
            metadataContext[MetadataContext.Key.memorySummary]
                == "今天途途18天"
        )
    }

    @Test("Given unsupported expression values When projected Then unsupported legacy keys stay empty")
    func givenUnsupportedExpressionValuesWhenProjectedThenUnsupportedLegacyKeysStayEmpty() throws {
        let expressionContext =
            try ExpressionContext(
                values: [
                    ExpressionValue(
                        token: ExpressionToken(rawValue: "people"),
                        resolvedText: "第31天"
                    ),
                    ExpressionValue(
                        token: ExpressionToken(rawValue: "model"),
                        resolvedText: "iPhone 17 Pro"
                    )
                ]
            )

        let metadataContext =
            ExpressionContextMetadataAdapter()
            .metadataContext(
                from: expressionContext
            )

        #expect(
            metadataContext[MetadataContext.Key.locationDisplay]
                .isEmpty
        )
        #expect(
            metadataContext[MetadataContext.Key.memorySummary]
                .isEmpty
        )
        #expect(
            metadataContext[MetadataContext.Key.model]
                == "iPhone 17 Pro"
        )
    }

    @Test("Given base metadata context When location projected Then unrelated legacy values are preserved")
    func givenBaseMetadataContextWhenLocationProjectedThenUnrelatedLegacyValuesArePreserved() throws {
        let expressionContext =
            try ExpressionContext(
                values: [
                    ExpressionValue(
                        token: ExpressionToken(rawValue: "location"),
                        resolvedText: "河南 · 商丘"
                    )
                ]
            )

        let baseContext =
            MetadataContext(
                values: [
                    MetadataContext.Key.model: "iPhone 17 Pro"
                ]
            )

        let metadataContext =
            ExpressionContextMetadataAdapter()
            .metadataContext(
                from: expressionContext,
                base: baseContext
            )

        #expect(
            metadataContext[MetadataContext.Key.locationDisplay]
                == "河南 · 商丘"
        )
        #expect(
            metadataContext[MetadataContext.Key.model]
                == "iPhone 17 Pro"
        )
    }

    @Test("Boundary Given adapter source When inspected Then it stays inside approved seam")
    func boundaryGivenAdapterSourceWhenInspectedThenItStaysInsideApprovedSeam() throws {
        let source =
            try String(
                contentsOfFile:
                    "/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Engines/ExpressionContextMetadataAdapter.swift",
                encoding: .utf8
            )

        #expect(source.contains("ExpressionContext"))
        #expect(source.contains("MetadataContext"))
        #expect(source.contains("MetadataContext.Key.locationDisplay"))
        #expect(source.contains("MetadataContext.Key.model"))
        #expect(source.contains("MetadataContext.Key.memorySummary"))
        #expect(!source.contains("PhotoMetadata"))
        #expect(!source.contains("PhotoMetadataReader"))
        #expect(!source.contains("LocationExpressionProvider"))
        #expect(!source.contains("CardVariableProvider"))
        #expect(!source.contains("TemplateVariableEngine"))
        #expect(!source.contains("RecordCard"))
        #expect(!source.contains("RecordCardBuildService"))
        #expect(!source.contains("RecordCardRenderer"))
    }
}
