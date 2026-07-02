#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 draft orchestration coordinator")
struct V1DraftOrchestrationCoordinatorTests {

    @Test("draft(for:) falls back to the provided default editor draft when no local region draft exists")
    func draftFallsBackToProvidedDefaultEditorDraft() {
        let defaultDraft =
            V1EditorDraft(
                items: [.text("默认文案")]
            )

        let resolved =
            V1DraftOrchestrationCoordinator
            .draft(
                for: .slotA,
                viewState: .init(
                    regionDrafts: [:],
                    activeTextItemIDs: [:],
                    activeConfigurationMessage: ""
                ),
                makeDefaultDraft: { _ in
                    defaultDraft
                }
            )

        #expect(resolved == defaultDraft)
    }

    @Test("applyMutationUpdate bridges the updated view state and returns preview drafts only for dirty regions")
    func applyMutationUpdateBridgesStateAndReturnsDirtyPreviewDrafts() {
        let updatedState =
            V1DraftMutationCoordinator.State(
                regionDrafts: [
                    .slotA: .init(
                        items: [
                            .text("记录"),
                            .token(
                                value: "途途今天11个月28天啦！",
                                templateValue:
                                    "{{memory_summary}}"
                            ),
                            .text("")
                        ]
                    )
                ],
                activeTextItemIDs: [:],
                activeConfigurationMessage:
                    V1DraftMutationCoordinator
                    .dirtyStateMessage
            )

        let application =
            V1DraftOrchestrationCoordinator
            .applyMutationUpdate(
                .init(
                    state: updatedState,
                    dirtyRegions: [.slotA]
                )
            )

        #expect(
            application.viewState.regionDrafts[
                .slotA
            ]?.singleLineText
            == "记录途途今天11个月28天啦！"
        )
        #expect(
            application.viewState
            .activeConfigurationMessage
            == V1DraftMutationCoordinator
                .dirtyStateMessage
        )
        #expect(
            Set(
                application.previewDraftsByRegion
                    .keys
            ) == Set([.slotA])
        )
        #expect(
            application.previewDraftsByRegion[
                .slotA
            ]?.singleLineTemplateText
            == "记录途途今天11个月28天啦！"
        )
    }
}
#endif
