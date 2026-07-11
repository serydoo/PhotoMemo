import Foundation
import Testing
@testable import PhotoMemo

@Suite("TemplatePreset Codable migration")
struct TemplatePresetCodableMigrationTests {

    @Test(
        "Legacy and canonical raw values decode to Classic White",
        arguments: [
            "classicWhite",
            "template1",
            "template2",
            "template3",
            "immersWhite"
        ]
    )
    func supportedRawValuesDecodeToClassicWhite(
        rawValue: String
    ) throws {
        let data = try JSONEncoder().encode(rawValue)

        let preset = try JSONDecoder().decode(
            TemplatePreset.self,
            from: data
        )

        #expect(preset == .classicWhite)
    }

    @Test("Classic White encodes with only the canonical raw value")
    func classicWhiteEncodesCanonically() throws {
        let data = try JSONEncoder().encode(
            TemplatePreset.classicWhite
        )

        #expect(
            String(decoding: data, as: UTF8.self)
            == "\"classicWhite\""
        )
    }

    @Test("Unknown preset raw values are rejected")
    func unknownRawValueIsRejected() throws {
        let data = try JSONEncoder().encode(
            "unknownPreset"
        )

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(
                TemplatePreset.self,
                from: data
            )
        }
    }

    @Test("Classic White is the only active preset")
    func classicWhiteIsTheOnlyActivePreset() {
        #expect(
            TemplatePreset.allCases
            == [.classicWhite]
        )
    }

    @Test(
        "Legacy preset migration preserves template payloads",
        arguments: [
            "template1",
            "template2",
            "template3",
            "immersWhite"
        ]
    )
    func legacyPresetMigrationPreservesTemplatePayload(
        rawValue: String
    ) throws {
        let expected = Template(
            id: UUID(
                uuidString:
                    "B2E3997B-20B0-496B-A714-A4A1EF025694"
            )!,
            preset: .classicWhite,
            name: "Preserved Name",
            leftTopArea: TemplateArea(
                name: "Preserved Left Top",
                items: [.relationshipDeviceLine]
            ),
            leftBottomArea: TemplateArea(
                name: "Preserved Left Bottom",
                items: [.captureDateLine]
            ),
            rightTopArea: TemplateArea(
                name: "Preserved Right Top",
                items: [.cameraSummary]
            ),
            rightBottomArea: TemplateArea(
                name: "Preserved Right Bottom",
                items: [.memorySummary]
            ),
            badgeArea: TemplateArea(
                name: "Preserved Badge",
                items: []
            )
        )
        let encoded = try JSONEncoder().encode(expected)
        var object = try #require(
            JSONSerialization.jsonObject(
                with: encoded
            ) as? [String: Any]
        )
        object["preset"] = rawValue
        let legacyData = try JSONSerialization.data(
            withJSONObject: object
        )

        let decoded = try JSONDecoder().decode(
            Template.self,
            from: legacyData
        )

        #expect(decoded == expected)
    }
}
