#if !MEMOMARK_SHARE_EXTENSION
import Testing
@testable import MemoMark

@MainActor
@Suite("Configuration preview viewing choice")
struct ConfigurationPreviewVisibilityTests {
    @Test("Editing temporarily restores preview without overwriting the choice")
    func editingPreservesCollapsedChoice() {
        var state = ConfigurationPreviewVisibilityState()
        #expect(state.isVisible(isEditingCardContent: false))
        state.isCollapsed = true
        #expect(!state.isVisible(isEditingCardContent: false))
        #expect(state.isVisible(isEditingCardContent: true))
        #expect(state.isCollapsed)
        #expect(!state.isVisible(isEditingCardContent: false))
        state.isCollapsed = false
        #expect(state.isVisible(isEditingCardContent: false))
    }

    @Test("Preview actions and hidden layout summary are translated in every supported language")
    func localizedActions() {
        let keys = [
            "configuration.preview.collapse", "configuration.preview.expand",
            "configuration.preview.visible", "configuration.preview.hidden",
            "configuration.layout.result.edit"
        ]
        for language in MemoMarkLanguage.allCases {
            for key in keys {
                let value = language.localized(key: key, fallback: "MISSING")
                #expect(value != "MISSING")
                #expect(value != key)
                #expect(!value.isEmpty)
            }
        }
    }

    @Test("A fresh application presentation starts with the preview visible")
    func freshPresentationShowsPreview() {
        var prior = ConfigurationPreviewVisibilityState()
        prior.isCollapsed = true
        let fresh = ConfigurationPreviewVisibilityState()
        #expect(!fresh.isCollapsed)
        #expect(fresh.isVisible(isEditingCardContent: false))
        #expect(prior.isCollapsed)
    }
}
#endif
