#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 preview sync coordinator")
struct V1PreviewSyncCoordinatorTests {

    @Test("refreshPreview composes text before syncing a single region")
    func refreshPreviewComposesTextBeforeSyncingASingleRegion() {
        let draft =
            V1PreviewDraft(
                items: [.text("记录")]
            )
        var receivedRegion: CardRegion?
        var receivedText = ""

        let coordinator =
            V1PreviewSyncCoordinator(
                composeText: { _ in
                    "记录iPhone 17 Pro Max"
                },
                syncRegionPreview: { region, text in
                    receivedRegion = region
                    receivedText = text
                },
                syncRegionPreviews: { _ in },
                loadPreviewText: { _ in "" }
            )

        coordinator.refreshPreview(
            for: .slotA,
            draft: draft
        )

        #expect(receivedRegion == .slotA)
        #expect(receivedText == "记录iPhone 17 Pro Max")
    }

    @Test("refreshDynamicPreview composes each region and syncs them together")
    func refreshDynamicPreviewComposesEachRegionAndSyncsThemTogether() {
        var receivedPreviews: [CardRegion: String] = [:]

        let coordinator =
            V1PreviewSyncCoordinator(
                composeText: { draft in
                    draft.singleLineTemplateText.uppercased()
                },
                syncRegionPreview: { _, _ in },
                syncRegionPreviews: {
                    receivedPreviews = $0
                },
                loadPreviewText: { _ in "" }
            )

        coordinator.refreshDynamicPreview(
            draftsByRegion: [
                .slotA: .init(items: [.text("记录")]),
                .slotD: .init(items: [.text("记忆")])
            ]
        )

        #expect(
            receivedPreviews[.slotA]
            == "记录"
        )
        #expect(
            receivedPreviews[.slotD]
            == "记忆"
        )
    }

    @Test("previewText delegates to the configured loader")
    func previewTextDelegatesToTheConfiguredLoader() {
        let coordinator =
            V1PreviewSyncCoordinator(
                composeText: { _ in "" },
                syncRegionPreview: { _, _ in },
                syncRegionPreviews: { _ in },
                loadPreviewText: {
                    region in
                    "\(region.rawValue)-preview"
                }
            )

        #expect(
            coordinator.previewText(
                for: .slotB
            ) == "slotB-preview"
        )
    }
}
#endif
