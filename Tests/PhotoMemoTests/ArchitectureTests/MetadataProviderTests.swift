import Foundation
import Testing
@testable import PhotoMemo

@Suite("PI-4 Metadata Provider")
struct MetadataProviderTests {

    @Test("Given photo metadata When provider compiles model Then expression context stores model value")
    func givenPhotoMetadataWhenProviderCompilesModelThenExpressionContextStoresModelValue() throws {
        let metadata =
            PhotoMetadata(
                deviceBrand: " Apple ",
                deviceModel: " iPhone 17 Pro "
            )

        let expressionValue =
            try #require(
                MetadataProvider()
                    .expressionValue(
                        for: MetadataProvider.modelToken,
                        metadata: metadata
                    )
            )

        let expressionContext =
            try ExpressionContext(
                values: [
                    expressionValue
                ]
            )

        #expect(
            expressionContext
                .value(
                    for: MetadataProvider.modelToken
                )?
                .resolvedText
            == "iPhone 17 Pro"
        )
    }

    @Test("Given metadata provider When canonical tokens inspected Then only model is supported in PI four")
    func givenMetadataProviderWhenCanonicalTokensInspectedThenOnlyModelIsSupportedInPIFour() {
        let provider =
            MetadataProvider()

        #expect(
            provider.canonicalTokens
                == [
                    MetadataProvider.modelToken
                ]
        )
    }

    @Test("Given metadata subtoken When provider asked for value Then PI four returns nil")
    func givenMetadataSubtokenWhenProviderAskedForValueThenPIFourReturnsNil() {
        let value =
            MetadataProvider()
            .expressionValue(
                for: ExpressionToken(
                    rawValue: "camera_summary"
                ),
                metadata: PhotoMetadata(
                    deviceModel: "iPhone 17 Pro"
                )
            )

        #expect(value == nil)
    }

    @Test("Given missing model When provider asked for model Then nil is returned")
    func givenMissingModelWhenProviderAskedForModelThenNilIsReturned() {
        let value =
            MetadataProvider()
            .expressionValue(
                for: MetadataProvider.modelToken,
                metadata: PhotoMetadata()
            )

        #expect(value == nil)
    }

    @Test("PI-13C Given same production input When model resolves through legacy lookup and provider Then text is identical")
    func pi13cGivenSameProductionInputWhenModelResolvesThroughLegacyLookupAndProviderThenTextIsIdentical() throws {
        let metadata =
            PhotoMetadata(
                deviceBrand: " Apple ",
                deviceModel: " iPhone 17 Pro "
            )
        let card =
            RecordCard(
                metadata: metadata,
                context:
                    MetadataContext
                    .build(
                        from: metadata
                    )
            )
        let legacyLookup =
            MetadataContextExpressionLookup(
                metadataContext:
                    CardVariableProvider
                    .build(
                        from: card
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

        #expect(
            legacyLookup
                .value(
                    for: MetadataProvider.modelToken
                )?
                .resolvedText
            == providerValue.resolvedText
        )
    }

    @Test("Boundary Given metadata provider When inspected Then it stores no dependencies")
    func boundaryGivenMetadataProviderWhenInspectedThenItStoresNoDependencies() {
        let provider =
            MetadataProvider()

        let labels =
            Mirror(
                reflecting: provider
            )
            .children
            .compactMap(\.label)

        #expect(labels.isEmpty)
    }

    @Test("Boundary Given metadata provider source When inspected Then it does not cross acquisition production or renderer seams")
    func boundaryGivenMetadataProviderSourceWhenInspectedThenItDoesNotCrossAcquisitionProductionOrRendererSeams() throws {
        let source =
            try String(
                contentsOfFile:
                    "/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MetadataExpression/MetadataProvider.swift",
                encoding: .utf8
            )

        #expect(source.contains("MetadataContext.build"))
        #expect(source.contains("ExpressionValue"))
        #expect(!source.contains("PhotoMetadataReader"))
        #expect(!source.contains("CardVariableProvider"))
        #expect(!source.contains("TemplateVariableLibrary"))
        #expect(!source.contains("RecordCardBuildService"))
        #expect(!source.contains("RecordCardRenderer"))
        #expect(
            source.range(
                of: "\\bExpressionContext\\b",
                options: .regularExpression
            ) == nil
        )
    }
}
