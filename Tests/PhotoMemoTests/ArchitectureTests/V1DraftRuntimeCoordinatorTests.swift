#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 draft runtime coordinator")
struct V1DraftRuntimeCoordinatorTests {

    @Test("updateTextItem bridges view state changes and refreshes only dirty previews")
    @MainActor
    func updateTextItemBridgesViewStateChangesAndRefreshesOnlyDirtyPreviews() {
        let itemID = UUID()
        var viewState =
            V1DraftOrchestrationCoordinator
            .ViewState(
                regionDrafts: [
                    .slotA: V1EditorDraft(
                        items: [
                            V1ContentItem(
                                id: itemID,
                                kind: .text,
                                title: "文字",
                                value: "旧文案",
                                savedValue: "旧文案",
                                systemImage: "textformat"
                            )
                        ]
                    )
                ],
                activeTextItemIDs: [:],
                activeConfigurationStatus: .idle
            )
        var refreshedDrafts: [CardRegion: V1PreviewDraft] = [:]

        let coordinator =
            V1DraftRuntimeCoordinator(
                loadViewState: {
                    viewState
                },
                updateViewState: {
                    viewState = $0
                },
                makeDefaultDraft: { region in
                    V1EditorDraft(
                        items: [
                            .text("default-\(region.rawValue)")
                        ]
                    )
                },
                refreshPreviewText: { _, _ in
                    Issue.record(
                        "Single-region refresh should not be used for mutation updates."
                    )
                },
                refreshPreviewTexts: {
                    refreshedDrafts = $0
                }
            )

        coordinator.updateTextItem(
            itemID,
            text: "新文案",
            for: .slotA
        )

        #expect(
            viewState.regionDrafts[.slotA]?.items.first?.value
            == "新文案"
        )
        #expect(
            viewState.activeTextItemIDs[.slotA]
            == itemID
        )
        #expect(
            viewState.activeConfigurationStatus
            == .dirty
        )
        #expect(
            Set(refreshedDrafts.keys)
            == Set([.slotA])
        )
        #expect(
            refreshedDrafts[.slotA]?.singleLineTemplateText
            == "新文案"
        )
    }

    @Test("bootstrapDrafts replaces region drafts, preserves other view state, and refreshes all memory regions")
    @MainActor
    func bootstrapDraftsReplacesRegionDraftsPreservesOtherViewStateAndRefreshesAllMemoryRegions() {
        let activeID = UUID()
        var viewState =
            V1DraftOrchestrationCoordinator
            .ViewState(
                regionDrafts: [
                    .slotA: V1EditorDraft(
                        items: [.text("旧内容")]
                    )
                ],
                activeTextItemIDs: [
                    .slotA: activeID
                ],
                activeConfigurationStatus: .saved
            )
        var refreshedDrafts: [CardRegion: V1PreviewDraft] = [:]

        let coordinator =
            V1DraftRuntimeCoordinator(
                loadViewState: {
                    viewState
                },
                updateViewState: {
                    viewState = $0
                },
                makeDefaultDraft: { region in
                    V1EditorDraft(
                        items: [
                            .text("default-\(region.rawValue)")
                        ]
                    )
                },
                refreshPreviewText: { _, _ in
                    Issue.record(
                        "Bootstrap should refresh previews in batch."
                    )
                },
                refreshPreviewTexts: {
                    refreshedDrafts = $0
                }
            )
        let bootstrapCoordinator =
            V1DraftBootstrapCoordinator {
                .success([
                    .slotB: .init(
                        items: [.text("锚点内容")]
                    )
                ])
            }

        coordinator.bootstrapDrafts(
            using: bootstrapCoordinator
        )

        #expect(
            viewState.regionDrafts[.slotB]?.singleLineText
            == "锚点内容"
        )
        #expect(
            viewState.activeTextItemIDs[.slotA]
            == activeID
        )
        #expect(
            viewState.activeConfigurationStatus
            == .saved
        )
        #expect(
            Set(refreshedDrafts.keys)
            == Set(CardRegion.memoryCardRegions)
        )
        #expect(
            refreshedDrafts[.slotB]?.singleLineTemplateText
            == "锚点内容"
        )
    }

    @Test("refreshPreview falls back to the default draft when local editor state is empty")
    @MainActor
    func refreshPreviewFallsBackToTheDefaultDraftWhenLocalEditorStateIsEmpty() {
        var receivedRegion: CardRegion?
        var receivedDraft: V1PreviewDraft?

        let coordinator =
            V1DraftRuntimeCoordinator(
                loadViewState: {
                    .init(
                        regionDrafts: [:],
                        activeTextItemIDs: [:],
                        activeConfigurationStatus: .idle
                    )
                },
                updateViewState: { _ in },
                makeDefaultDraft: { region in
                    V1EditorDraft(
                        items: [
                            .text("default-\(region.rawValue)")
                        ]
                    )
                },
                refreshPreviewText: { region, draft in
                    receivedRegion = region
                    receivedDraft = draft
                },
                refreshPreviewTexts: { _ in
                    Issue.record(
                        "Single-region refresh should not batch."
                    )
                }
            )

        coordinator.refreshPreview(
            for: .slotC
        )

        #expect(receivedRegion == .slotC)
        #expect(
            receivedDraft?.singleLineTemplateText
            == "default-slotC"
        )
    }
}
#endif
