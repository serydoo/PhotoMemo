import Foundation
import Testing
@testable import PhotoMemo

@Suite("Location Expression Phase 4-D")
struct LocationExpressionPhase4DTests {

    @Test("Given photo metadata When location provider compiles location Then expression context stores location value")
    func givenPhotoMetadataWhenLocationProviderCompilesLocationThenExpressionContextStoresLocationValue() throws {
        let metadata =
            PhotoMetadata(
                city: " 商丘 ",
                district: " 永城 ",
                province: " 河南 "
            )

        let context =
            LocationContextBuilder()
            .build(
                from: metadata
            )

        let expressionValue =
            try #require(
                LocationExpressionProvider()
                    .expressionValue(
                        for: LocationExpressionProvider.locationToken,
                        context: context,
                        requestedPresentation: .provinceCity
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
                    for: LocationExpressionProvider.locationToken
                )?
                .resolvedText
            == "河南 · 商丘"
        )
    }

    @Test("Given location provider When canonical tokens inspected Then only location is supported in phase four d")
    func givenLocationProviderWhenCanonicalTokensInspectedThenOnlyLocationIsSupportedInPhaseFourD() {
        let provider =
            LocationExpressionProvider()

        #expect(
            provider.canonicalTokens
                == [
                    LocationExpressionProvider.locationToken
                ]
        )
    }

    @Test("Given raw coordinate token When location provider asked for value Then phase four d returns nil")
    func givenRawCoordinateTokenWhenLocationProviderAskedForValueThenPhaseFourDReturnsNil() {
        let context =
            LocationContext(
                coordinate: LocationCoordinate(
                    latitude: 31.230416,
                    longitude: 121.473701
                )
            )

        let value =
            LocationExpressionProvider()
            .expressionValue(
                for: ExpressionToken(
                    rawValue: "latitude"
                ),
                context: context,
                requestedPresentation: .coordinate,
                configuration: LocationResolutionConfiguration(
                    allowsCoordinateFallback: true
                )
            )

        #expect(value == nil)
    }

    @Test("Boundary Given location provider When inspected Then it stores only resolver and formatter")
    func boundaryGivenLocationProviderWhenInspectedThenItStoresOnlyResolverAndFormatter() {
        let provider =
            LocationExpressionProvider()

        let labels =
            Mirror(
                reflecting: provider
            )
            .children
            .compactMap(\.label)

        #expect(
            labels
                == [
                    "resolver",
                    "formatter"
                ]
        )
    }
}
