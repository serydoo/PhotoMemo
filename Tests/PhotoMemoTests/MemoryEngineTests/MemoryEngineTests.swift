import Foundation
import Testing
@testable import PhotoMemo

@Suite("MemoryEngineTests")
struct MemoryEngineTests {

    @Test("Formats baby age without zero-year wording and exposes numeric since values")
    func formatsBabyAgeAndSinceValues() throws {

        let anchor = Anchor(
            type: .birthday,
            title: "宝宝",
            date: try date(
                year: 2026,
                month: 1,
                day: 1,
                hour: 9,
                minute: 0,
                timeZoneOffsetSeconds: 8 * 3600
            )
        )

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 9,
                day: 1,
                hour: 9,
                minute: 0,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )

        let result = MemoryVariableProvider().build(
            from: MemoryContext(
                metadata: metadata,
                anchor: anchor
            )
        )

        #expect(result.daysSince == "243")
        #expect(result.yearsSince == "0")
        #expect(result.monthsSince == "8")
        #expect(result.weeksSince == "34")
        #expect(result.babyAge == "8个月")
        #expect(result.memorySummary == "宝宝今天8个月啦！")
    }

    @Test("Handles leap-year birthdays deterministically")
    func handlesLeapYearBirthdays() throws {

        let anchor = Anchor(
            type: .birthday,
            title: "Leap Baby",
            date: try date(
                year: 2024,
                month: 2,
                day: 29,
                hour: 8,
                minute: 0,
                timeZoneOffsetSeconds: 0
            )
        )

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2025,
                month: 3,
                day: 1,
                hour: 8,
                minute: 0,
                timeZoneOffsetSeconds: 0
            ),
            captureTimezoneOffsetSeconds: 0
        )

        let result = MemoryVariableProvider().build(
            from: MemoryContext(
                metadata: metadata,
                anchor: anchor
            )
        )

        #expect(result.daysSince == "366")
        #expect(result.yearsSince == "1")
        #expect(result.monthsSince == "12")
        #expect(result.weeksSince == "52")
        #expect(result.babyAge == "1岁1天")
    }

    @Test("Clamps future anchors and preserves explicit story text")
    func clampsFutureAnchorsAndPreservesStory() throws {

        let anchor = Anchor(
            type: .birthday,
            title: "宝宝",
            date: try date(
                year: 2026,
                month: 7,
                day: 1,
                hour: 12,
                minute: 0,
                timeZoneOffsetSeconds: 8 * 3600
            )
        )

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 6,
                day: 20,
                hour: 12,
                minute: 0,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )

        let result = MemoryVariableProvider().build(
            from: MemoryContext(
                metadata: metadata,
                anchor: anchor,
                story: "夏天之前"
            )
        )

        #expect(result.daysSince == "0")
        #expect(result.yearsSince == "0")
        #expect(result.monthsSince == "0")
        #expect(result.weeksSince == "0")
        #expect(result.babyAge.isEmpty)
        #expect(result.memorySummary == "夏天之前")
    }

    @Test("Publishes memory values into card context and keeps existing anchor summary behavior")
    func publishesMemoryValuesIntoCardContext() throws {

        let anchor = Anchor(
            type: .birthday,
            title: "宝宝",
            date: try date(
                year: 2026,
                month: 6,
                day: 1,
                hour: 23,
                minute: 30,
                timeZoneOffsetSeconds: 8 * 3600
            )
        )

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 6,
                day: 2,
                hour: 0,
                minute: 15,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )

        let anchorResult = AnchorEngine().build(
            from: anchor,
            photoDate: try #require(metadata.captureDate)
        )

        let card = RecordCard(
            metadata: metadata,
            context: MetadataContext.build(from: metadata),
            anchor: anchor,
            anchorResult: anchorResult
        )

        let context = CardVariableProvider.build(
            from: card
        )

        #expect(context[MetadataContext.Key.daysSince] == "0")
        #expect(context[MetadataContext.Key.weeksSince] == "0")
        #expect(context[MetadataContext.Key.babyAge] == "0天")
        #expect(context[MetadataContext.Key.memorySummary] == anchorResult.summaryText)
    }

    @Test("Projects explicit memory module into variable and template flow when legacy memory inputs are absent")
    func projectsExplicitMemoryModuleIntoVariableAndTemplateFlow() throws {

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 7,
                day: 2,
                hour: 8,
                minute: 30,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )
        var card = RecordCard(
            template: memorySummaryTemplate(),
            metadata: metadata,
            context: MetadataContext.build(from: metadata)
        )
        card.memoryModule =
            MemoryModule(
                title: "Memory",
                blocks: [
                    .text("乐乐")
                ],
                renderedText: "乐乐",
                sourceAnchor: nil,
                preferredRegion: .slotD
            )

        let context = CardVariableProvider.build(
            from: card
        )
        let blocks =
            CardTextBlockEngine()
            .build(from: card)

        #expect(context[MetadataContext.Key.memorySummary] == "乐乐")
        #expect(
            blocks.first(where: { $0.area == .rightBottom })?.value
            == "乐乐"
        )
    }

    @Test("Exposes new memory variables through the public catalog")
    func exposesNewMemoryVariablesThroughPublicCatalog() {

        let tokens = Set(
            TemplateVariableLibrary.intelligent.map(\.token)
        )

        #expect(tokens.contains("{{days_since}}"))
        #expect(tokens.contains("{{years_since}}"))
        #expect(tokens.contains("{{months_since}}"))
        #expect(tokens.contains("{{weeks_since}}"))
        #expect(tokens.contains("{{baby_age}}"))
        #expect(tokens.contains("{{memory_summary}}"))
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        timeZoneOffsetSeconds: Int
    ) throws -> Date {

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(
            secondsFromGMT: timeZoneOffsetSeconds
        ) ?? .gmt

        let components = DateComponents(
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )

        return try #require(
            calendar.date(from: components)
        )
    }

    private func memorySummaryTemplate() -> Template {

        Template(
            preset: .template1,
            name: "Memory Summary",
            leftTopArea: .leftTop,
            leftBottomArea: .leftBottom,
            rightTopArea: TemplateArea(
                name: "Right Top",
                items: [.cameraSummary]
            ),
            rightBottomArea: TemplateArea(
                name: "Right Bottom",
                items: [
                    TemplateItem(
                        type: .text,
                        name: "Memory Summary",
                        value: "{{memory_summary}}"
                    )
                ]
            ),
            badgeArea: .badge
        ).normalizedForEditing
    }
}
