#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Presentation style persistence")
struct PresentationStylePersistenceTests {

    @Test("Each presentation style declares its own content projection")
    func contentContractKeepsStyleContentIndependent() {
        let classic = RecordCardPresentationStyle
            .classicWhite
            .contentContract
        let minimal = RecordCardPresentationStyle
            .minimal
            .contentContract

        #expect(
            classic.editableTextAreas == [
                .leftTop,
                .leftBottom,
                .rightTop,
                .rightBottom
            ]
        )
        #expect(classic.renderedTextAreas.count == 4)
        #expect(classic.photoDescriptionTextAreas == [.rightBottom])

        #expect(minimal.editableTextAreas == [.leftTop])
        #expect(minimal.renderedTextAreas == [.leftTop])
        #expect(minimal.photoDescriptionTextAreas == [.leftTop])
    }

    @Test("Card regions are derived from the selected style contract")
    func cardRegionsFollowStyleContract() {
        #expect(
            CardRegion.editableRegions(for: .classicWhite)
                == CardRegion.memoryCardRegions
        )
        #expect(
            CardRegion.editableRegions(for: .minimal)
                == [.slotA]
        )
    }

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

    @Test("Editor persists independent templates for each presentation style")
    func editorPersistsIndependentTemplatesForEachPresentationStyle() throws {
        var classic = Template.classicWhite
        classic.leftTopArea.items = [.title]
        var minimal = Template.classicWhite
        minimal.leftTopArea.items = [.story]

        let editor = MemoryConfigurationRecord.Editor(
            template: classic,
            templatesByPresentationStyle: [
                .classicWhite: classic,
                .minimal: minimal
            ],
            regionTemplateIDs: [:],
            memoryCopy: .init(
                usesCustomText: false,
                customText: ""
            )
        )
        let decoded = try JSONDecoder().decode(
            MemoryConfigurationRecord.Editor.self,
            from: JSONEncoder().encode(editor)
        )

        #expect(
            decoded.template(for: .classicWhite)
                .leftTopArea.items == [.title]
        )
        #expect(
            decoded.template(for: .minimal)
                .leftTopArea.items == [.story]
        )
        #expect(
            decoded.template(for: .classicWhite)
                != decoded.template(for: .minimal)
        )
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
