import Foundation
import Testing
@testable import PhotoMemo

@Suite("Location Expression Phase 0")
struct LocationExpressionPhase0Tests {

    @Test("skeleton exposes canonical provider tokens without resolving values")
    func skeletonExposesCanonicalProviderTokens() {
        let provider =
            LocationExpressionProvider()

        #expect(
            provider.canonicalTokens
                == [
                    ExpressionToken(rawValue: "location")
                ]
        )
    }

    @Test("context builder remains a non-production stub in Phase 0")
    func contextBuilderRemainsNonProductionStub() {
        let context =
            LocationContextBuilder()
            .build()

        #expect(context.hasGPS == false)
        #expect(context.hasAddress == false)
        #expect(context.hasPOI == false)
        #expect(context.coordinate == nil)
        #expect(context.address == nil)
        #expect(context.altitudeMeters == nil)
    }

    @Test("presentation resolver has no display behavior in Phase 0")
    func presentationResolverHasNoDisplayBehavior() {
        let resolved =
            LocationResolver()
            .resolve(
                context: LocationContext(),
                requestedPresentation: .provinceCity,
                configuration: LocationResolutionConfiguration(
                    allowsCoordinateFallback: true
                )
            )

        #expect(resolved.resolvedPresentation == nil)
        #expect(resolved.resolutionPolicy == .empty)
    }
}
