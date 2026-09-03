#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("V1 draft bootstrap coordinator")
struct V1DraftBootstrapCoordinatorTests {

    @Test("bootstrapDrafts prefers intent-backed preview drafts when available")
    func bootstrapDraftsPrefersIntentBackedPreviewDraftsWhenAvailable() {
        let coordinator =
            ConfigurationDraftBootstrapCoordinator {
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
            ConfigurationDraftBootstrapCoordinator {
                .failure(
                    MemoMarkError(
                        code: .previewBuildFailed,
                        message: "failed"
                    )
                )
            }

        let drafts =
            coordinator.bootstrapDrafts {
                region in
                MemoryCardEditorDraft(
                    items: [
                        MemoryCardContentItem.text(
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
