#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 draft mutation coordinator")
struct V1DraftMutationCoordinatorTests {

    @Test("draft(for:) falls back to the provided default draft when no local region draft exists")
    func draftForFallsBackToDefaultDraft() {
        let defaultDraft =
            V1DraftMutationDraft(
                items: [.text("默认文案")]
            )

        let resolved =
            V1DraftMutationCoordinator
            .draft(
                for: .slotA,
                state: .init(),
                makeDefaultDraft: { _ in defaultDraft }
            )

        #expect(resolved == defaultDraft)
    }

    @Test("prependText inserts a new leading text item, routes active item focus, and marks the draft dirty")
    func prependTextRoutesFocusAndMarksDraftDirty() {
        let trailing = UUID()
        let initialDraft =
            V1DraftMutationDraft(
                items: [
                    .token(
                        value: "记录",
                        templateValue: "{{capture_summary}}"
                    ),
                    .text("", id: trailing)
                ]
            )
        let initialState =
            V1DraftMutationCoordinator.State(
                regionDrafts: [.slotA: initialDraft],
                activeTextItemIDs: [:],
                activeConfigurationStatus: .idle
            )

        let update =
            V1DraftMutationCoordinator
            .prependText(
                "前缀",
                for: .slotA,
                in: initialState,
                makeDefaultDraft: { _ in initialDraft }
            )
        let draft =
            update.state.regionDrafts[.slotA]

        #expect(update.dirtyRegions == [.slotA])
        #expect(
            update.state.activeConfigurationStatus
            == .dirty
        )
        #expect(draft?.items.map(\.value) == ["前缀", "记录", ""])

        let prependedID =
            try! #require(
                draft?.items.first?.id
            )
        #expect(
            update.state.activeTextItemIDs[.slotA]
            == prependedID
        )
    }

    @Test("appendText keeps a single trailing text input and routes active item focus to the appended text")
    func appendTextKeepsSingleTrailingInputAndRoutesFocus() {
        let emptyTail = UUID()
        let initialDraft =
            V1DraftMutationDraft(
                items: [
                    .token(
                        value: "记录",
                        templateValue: "{{capture_summary}}"
                    ),
                    .text("", id: emptyTail)
                ]
            )

        let update =
            V1DraftMutationCoordinator
            .appendText(
                "结尾",
                for: .slotB,
                in: .init(regionDrafts: [.slotB: initialDraft]),
                makeDefaultDraft: { _ in initialDraft }
            )
        let draft =
            try! #require(
                update.state.regionDrafts[.slotB]
            )

        #expect(draft.items.map(\.value) == ["记录", "结尾", ""])
        #expect(draft.items.count == 3)
        #expect(
            update.state.activeTextItemIDs[.slotB]
            == draft.items[1].id
        )
    }

    @Test("removeItem normalizes trailing text after deleting a composed item")
    func removeItemNormalizesTrailingText() {
        let keptText = UUID()
        let removedToken = UUID()
        let emptyTail = UUID()
        let initialDraft =
            V1DraftMutationDraft(
                items: [
                    .text("前文", id: keptText),
                    .token(
                        value: "记录",
                        templateValue: "{{capture_summary}}",
                        id: removedToken
                    ),
                    .text("", id: emptyTail)
                ]
            )

        let update =
            V1DraftMutationCoordinator
            .removeItem(
                id: removedToken,
                from: .slotC,
                in: .init(regionDrafts: [.slotC: initialDraft]),
                makeDefaultDraft: { _ in initialDraft }
            )
        let draft =
            try! #require(
                update.state.regionDrafts[.slotC]
            )

        #expect(draft.items.map(\.value) == ["前文"])
        #expect(update.dirtyRegions == [.slotC])
    }

    @Test("insert places a composed item after the active text item and preserves a trailing text input")
    func insertPlacesComposedItemAfterActiveTextItem() {
        let leadingText = UUID()
        let trailingText = UUID()
        let initialDraft =
            V1DraftMutationDraft(
                items: [
                    .text("前文", id: leadingText),
                    .text("", id: trailingText)
                ]
            )
        let initialState =
            V1DraftMutationCoordinator.State(
                regionDrafts: [.slotD: initialDraft],
                activeTextItemIDs: [.slotD: leadingText],
                activeConfigurationStatus: .idle
            )

        let update =
            V1DraftMutationCoordinator
            .insert(
                .token(
                    title: "拍摄信息",
                    value: "记录",
                    templateValue: "{{capture_summary}}",
                    systemImage: "camera"
                ),
                into: .slotD,
                in: initialState,
                makeDefaultDraft: { _ in initialDraft }
            )
        let draft =
            try! #require(
                update.state.regionDrafts[.slotD]
            )

        #expect(
            draft.items.map(\.kind)
            == [.text, .token, .text]
        )
        #expect(draft.items.map(\.value) == ["前文", "记录", ""])
        #expect(draft.items[1].title == "拍摄信息")
        #expect(draft.items[1].systemImage == "camera")
        #expect(
            update.state.activeTextItemIDs[.slotD]
            == leadingText
        )
    }

    @Test("insert before an active empty trailing text item reuses that trailing slot instead of leaving duplicate empty text items")
    func insertBeforeActiveEmptyTrailingTextReusesTrailingSlot() {
        let emptyTail = UUID()
        let initialDraft =
            V1DraftMutationDraft(
                items: [
                    .token(
                        value: "记录",
                        templateValue: "{{capture_summary}}"
                    ),
                    .text("", id: emptyTail)
                ]
            )
        let initialState =
            V1DraftMutationCoordinator.State(
                regionDrafts: [.slotA: initialDraft],
                activeTextItemIDs: [.slotA: emptyTail],
                activeConfigurationStatus: .idle
            )

        let update =
            V1DraftMutationCoordinator
            .insert(
                .token(
                    value: "地点",
                    templateValue: "{{location_display}}"
                ),
                into: .slotA,
                in: initialState,
                makeDefaultDraft: { _ in initialDraft }
            )
        let draft =
            try! #require(
                update.state.regionDrafts[.slotA]
            )

        #expect(draft.items.map(\.value) == ["记录", "地点", ""])
        #expect(draft.items.count == 3)
    }

    @Test("normalizeTrailingTextInput appends a trailing text item after a non-text item and removes duplicate empty trailing text inputs")
    func normalizeTrailingTextInputAppendsTailAndRemovesDuplicates() {
        var tokenOnly =
            V1DraftMutationDraft(
                items: [
                    .token(
                        value: "记录",
                        templateValue: "{{capture_summary}}"
                    )
                ]
            )
        tokenOnly.normalizeTrailingTextInput()

        #expect(tokenOnly.items.map(\.value) == ["记录", ""])

        var duplicateTrailing =
            V1DraftMutationDraft(
                items: [
                    .text("前文"),
                    .text(""),
                    .text("")
                ]
            )
        duplicateTrailing.normalizeTrailingTextInput()

        #expect(
            duplicateTrailing.items.map(\.value)
            == ["前文", ""]
        )
    }
}
#endif
