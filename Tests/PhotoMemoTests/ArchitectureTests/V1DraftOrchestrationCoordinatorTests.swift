#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 draft orchestration coordinator", .serialized)
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
                    activeConfigurationStatus: .idle
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
                                value: "今天途途11个月28天",
                                templateValue:
                                    "{{memory_summary}}"
                            ),
                            .text("")
                        ]
                    )
                ],
                activeTextItemIDs: [:],
                activeConfigurationStatus: .dirty
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
            == "记录今天途途11个月28天"
        )
        #expect(
            application.viewState
            .activeConfigurationStatus
            == .dirty
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
            == "记录{{memory_summary}}"
        )
        #expect(
            application.previewDraftsByRegion[
                .slotA
            ]?.resolvedSingleLineText
            == "记录今天途途11个月28天"
        )
    }
}
#endif
