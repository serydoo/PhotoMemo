#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 draft bootstrap coordinator")
struct V1DraftBootstrapCoordinatorTests {

    @Test("bootstrapDrafts prefers intent-backed preview drafts when available")
    func bootstrapDraftsPrefersIntentBackedPreviewDraftsWhenAvailable() {
        let coordinator =
            V1DraftBootstrapCoordinator {
                .success([
                    .slotA: .init(
                        items: [
                            .text("记录")
                        ]
                    )
                ])
            }

        let drafts =
            coordinator.bootstrapDrafts {
                region in
                .init(
                    items: [
                        .text(region.rawValue)
                    ]
                )
            }

        #expect(
            drafts[.slotA]?.items.map(\.value)
            == ["记录"]
        )
    }

    @Test("bootstrapDrafts falls back to default editor drafts for all memory regions")
    func bootstrapDraftsFallsBackToDefaultEditorDraftsForAllMemoryRegions() {
        let coordinator =
            V1DraftBootstrapCoordinator {
                .failure(
                    PhotoMemoError(
                        code: .previewBuildFailed,
                        message: "failed"
                    )
                )
            }

        let drafts =
            coordinator.bootstrapDrafts {
                region in
                V1EditorDraft(
                    items: [
                        V1ContentItem.text(
                            "default-\(region.rawValue)"
                        )
                    ]
                )
            }

        #expect(
            CardRegion.memoryCardRegions.allSatisfy {
                drafts[$0]?.items.first?.value
                == "default-\($0.rawValue)"
            }
        )
    }
}
#endif
