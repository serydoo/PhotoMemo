import Foundation
import Testing
@testable import PhotoMemo

@Suite("Template editing migration")
struct TemplateEditingMigrationTests {

    @Test("Legacy defaults do not replace multi-item areas")
    func legacyDefaultsDoNotReplaceMultiItemAreas() {
        let trailingText = TemplateItem(
            type: .text,
            name: "User Text",
            value: "Preserve me"
        )
        let leftTopItems = [
            TemplateItem(
                type: .variable,
                name: "Legacy Title",
                value: "{{title}}"
            ),
            trailingText
        ]
        let leftBottomItems = [
            TemplateItem(
                type: .variable,
                name: "Legacy Capture Date",
                value: "记录于{{capture_date_display}}"
            ),
            trailingText
        ]
        let rightBottomItems = [
            TemplateItem(
                type: .variable,
                name: "Legacy Anchor Sentence",
                value: "今天{{anchor_age_text}}"
            ),
            trailingText
        ]
        var template = Template.classicWhite
        template.leftTopArea.items = leftTopItems
        template.leftBottomArea.items = leftBottomItems
        template.rightBottomArea.items = rightBottomItems

        let normalized = template.normalizedForEditing

        #expect(normalized.leftTopArea.items == leftTopItems)
        #expect(normalized.leftBottomArea.items == leftBottomItems)
        #expect(normalized.rightBottomArea.items == rightBottomItems)
    }

    @Test("Legacy defaults still migrate single-item areas")
    func legacyDefaultsStillMigrateSingleItemAreas() {
        var template = Template.classicWhite
        template.leftTopArea.items = [
            TemplateItem(
                type: .variable,
                name: "Legacy Title",
                value: "{{title}}"
            )
        ]
        template.leftBottomArea.items = [
            TemplateItem(
                type: .variable,
                name: "Legacy Capture Date",
                value: "记录于{{capture_date_display}}"
            )
        ]
        template.rightBottomArea.items = [
            TemplateItem(
                type: .variable,
                name: "Legacy Anchor Sentence",
                value: "今天{{anchor_age_text}}"
            )
        ]

        let normalized = template.normalizedForEditing

        #expect(
            normalized.leftTopArea.items.map(\.value)
            == [TemplateItem.relationshipDeviceLine.value]
        )
        #expect(
            normalized.leftBottomArea.items.map(\.value)
            == [TemplateItem.captureDateLine.value]
        )
        #expect(
            normalized.rightBottomArea.items.map(\.value)
            == [TemplateItem.memorySummary.value]
        )
    }

    @Test("Legacy default migration preserves item identity and disabled state")
    func legacyDefaultMigrationPreservesIdentityAndDisabledState() throws {
        let itemID = UUID()
        var template = Template.classicWhite
        template.leftTopArea.items = [
            TemplateItem(
                id: itemID,
                type: .variable,
                name: "Legacy Title",
                value: "{{title}}",
                isEnabled: false
            )
        ]

        let migrated = try #require(
            template.normalizedForEditing.leftTopArea.items.first
        )

        #expect(migrated.id == itemID)
        #expect(migrated.isEnabled == false)
        #expect(migrated.value == TemplateItem.relationshipDeviceLine.value)
    }
}
