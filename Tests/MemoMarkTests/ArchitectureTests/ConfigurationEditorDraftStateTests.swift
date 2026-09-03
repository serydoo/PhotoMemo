#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Configuration editor draft state")
struct ConfigurationEditorDraftStateTests {

    @Test("style switches preserve each isolated editor buffer")
    func styleSwitchPreservesBuffers() {
        let classicDraft: [CardRegion: MemoryCardEditorDraft] = [
            .slotA: MemoryCardEditorDraft(items: [])
        ]
        let minimalDraft: [CardRegion: MemoryCardEditorDraft] = [
            .slotA: MemoryCardEditorDraft(items: [])
        ]
        var state = ConfigurationEditorDraftState()

        state.activate(.classicWhite, fallback: classicDraft)
        state.commitActive(for: .classicWhite)
        state.activate(.minimal, fallback: minimalDraft)

        #expect(state.active == minimalDraft)
        #expect(state.byPresentationStyle[.classicWhite] == classicDraft)
        #expect(state.draftsForSaving[.minimal] == minimalDraft)
    }

    @Test("projection replaces active and style-scoped buffers atomically")
    func projectionReplacesBothBuffers() {
        var state = ConfigurationEditorDraftState()
        let active = [CardRegion.slotA: MemoryCardEditorDraft(items: [])]
        let inactive = [CardRegion.slotA: MemoryCardEditorDraft(items: [])]

        state.replace(
            active: active,
            byPresentationStyle: [.minimal: inactive],
            activeStyle: .minimal
        )

        #expect(state.active == active)
        #expect(state.byPresentationStyle[.minimal] == active)
        #expect(state.draftsForSaving[.minimal] == active)
    }
}
#endif
