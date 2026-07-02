import Foundation
import Testing
@testable import PhotoMemo

@Suite("TemplateVariableEngine")
struct TemplateVariableEngineTests {

    @Test("Replaces known tokens and clears missing ones")
    func replacesKnownTokensAndClearsMissingOnes() {

        let engine = TemplateVariableEngine()
        let context = MetadataContext(
            values: [
                "model": "iPhone 17 Pro",
                "capture_date_short": "2026.06.20"
            ]
        )

        let rendered = engine.render(
            "{{model}} · {{capture_date_short}} · {{missing_token}}",
            context: context
        )

        #expect(rendered == "iPhone 17 Pro · 2026.06.20 · ")
    }

    @Test("Returns plain text templates without token scanning changes")
    func returnsPlainTextTemplatesWithoutTokenScanningChanges() {

        let engine = TemplateVariableEngine()
        let context = MetadataContext(
            values: [
                "model": "iPhone 17 Pro"
            ]
        )

        let rendered = engine.render(
            "右下默认说明",
            context: context
        )

        #expect(rendered == "右下默认说明")
    }
}
