#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Presentation style persistence")
struct PresentationStylePersistenceTests {

    @Test("Minimal presentation style survives a persistence round trip")
    func minimalStyleRoundTrip() throws {
        let presentation = makePresentation(route: .minimal)

        let data = try JSONEncoder().encode(presentation)
        let decoded = try JSONDecoder().decode(
            MemoryConfigurationRecord.Presentation.self,
            from: data
        )

        #expect(decoded == presentation)
        #expect(decoded.route == .minimal)
    }

    @Test("A legacy presentation without a route defaults to classic white")
    func missingRouteDefaultsToClassicWhite() throws {
        let data = try encodedPresentationObject(route: .minimal) { object in
            object.removeValue(forKey: "route")
        }

        let decoded = try JSONDecoder().decode(
            MemoryConfigurationRecord.Presentation.self,
            from: data
        )

        #expect(decoded.route == .classicWhite)
        #expect(decoded.logo.mode == .appleMini)
    }

    @Test("An unknown presentation route safely defaults to classic white")
    func unknownRouteDefaultsToClassicWhite() throws {
        let data = try encodedPresentationObject(route: .minimal) { object in
            object["route"] = "futureStyle"
        }

        let decoded = try JSONDecoder().decode(
            MemoryConfigurationRecord.Presentation.self,
            from: data
        )

        #expect(decoded.route == .classicWhite)
        #expect(decoded.logo.mode == .appleMini)
    }

    private func makePresentation(
        route: RecordCardPresentationStyle
    ) -> MemoryConfigurationRecord.Presentation {
        MemoryConfigurationRecord.Presentation(
            route: route,
            locationConfiguration: nil,
            logo: .init(
                mode: .appleMini,
                badge: nil
            )
        )
    }

    private func encodedPresentationObject(
        route: RecordCardPresentationStyle,
        mutation: (inout [String: Any]) -> Void
    ) throws -> Data {
        let encoded = try JSONEncoder().encode(
            makePresentation(route: route)
        )
        var object = try #require(
            JSONSerialization.jsonObject(with: encoded)
                as? [String: Any]
        )
        mutation(&object)
        return try JSONSerialization.data(withJSONObject: object)
    }
}
#endif
