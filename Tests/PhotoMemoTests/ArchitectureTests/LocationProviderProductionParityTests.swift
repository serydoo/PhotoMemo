import Foundation
import Testing
@testable import PhotoMemo

@Suite("PI-18 Location Provider Production Parity")
struct LocationProviderProductionParityTests {

    @Test("PI-18 full hierarchy legacy location display is not provider parity")
    func pi18FullHierarchyLegacyLocationDisplayIsNotProviderParity() throws {
        let metadata =
            PhotoMetadata(
                city: "Shenzhen",
                district: "Nanshan",
                province: "Guangdong",
                country: "China"
            )
        let legacyText =
            MetadataContext
            .build(
                from: metadata
            )[MetadataContext.Key.locationDisplay]
        let providerText =
            try providerText(
                from: metadata,
                requestedPresentation: .provinceCityDistrict
            )

        #expect(legacyText == "China · Guangdong · Shenzhen · Nanshan")
        #expect(providerText == "Guangdong · Shenzhen · Nanshan")
        #expect(providerText != legacyText)
    }

    @Test("PI-18 location name legacy display is not provider parity")
    func pi18LocationNameLegacyDisplayIsNotProviderParity() throws {
        let metadata =
            PhotoMetadata(
                city: "Shenzhen",
                district: "Nanshan",
                province: "Guangdong",
                country: "China",
                locationName: "Lujiazui"
            )
        let legacyText =
            MetadataContext
            .build(
                from: metadata
            )[MetadataContext.Key.locationDisplay]
        let providerText =
            try providerText(
                from: metadata,
                requestedPresentation: .provinceCityDistrict
            )

        #expect(legacyText == "Lujiazui")
        #expect(providerText == "Guangdong · Shenzhen · Nanshan")
        #expect(providerText != legacyText)
    }

    @Test("PI-18 coordinate fallback legacy display is not default provider parity")
    func pi18CoordinateFallbackLegacyDisplayIsNotDefaultProviderParity() throws {
        let metadata =
            PhotoMetadata(
                latitude: 22.5430964,
                longitude: 114.0578652
            )
        let legacyText =
            MetadataContext
            .build(
                from: metadata
            )[MetadataContext.Key.locationDisplay]
        let providerText =
            try providerText(
                from: metadata,
                requestedPresentation: .provinceCity
            )

        #expect(legacyText == "22.543096, 114.057865")
        #expect(providerText.isEmpty)
        #expect(providerText != legacyText)
    }
}

private func providerText(
    from metadata: PhotoMetadata,
    requestedPresentation: LocationPresentationMode
) throws -> String {
    let context =
        LocationContextBuilder()
        .build(
            from: metadata
        )
    let value =
        try #require(
            LocationExpressionProvider()
                .expressionValue(
                    for: LocationExpressionProvider.locationToken,
                    context: context,
                    requestedPresentation: requestedPresentation
                )
        )

    return value.resolvedText
}
