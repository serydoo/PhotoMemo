#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 preview sync coordinator")
struct V1PreviewSyncCoordinatorTests {

    @Test("refreshPreview syncs the render model display text for a single region")
    func refreshPreviewSyncsTheRenderModelDisplayTextForASingleRegion() {
        let model =
            V1PreviewRenderModel(
                templateSourceText:
                    "记录{{memory_summary}}",
                displayText:
                    "记录iPhone 17 Pro Max"
            )
        var receivedRegion: CardRegion?
        var receivedText = ""

        let coordinator =
            V1PreviewSyncCoordinator(
                syncRegionPreview: { region, text in
                    receivedRegion = region
                    receivedText = text
                },
                syncRegionPreviews: { _ in },
                loadPreviewText: { _ in "" }
            )

        coordinator.refreshPreview(
            for: .slotA,
            model: model
        )

        #expect(receivedRegion == .slotA)
        #expect(receivedText == "记录iPhone 17 Pro Max")
    }

    @Test("refreshDynamicPreview syncs each region using render model display text")
    func refreshDynamicPreviewSyncsEachRegionUsingRenderModelDisplayText() {
        var receivedPreviews: [CardRegion: String] = [:]

        let coordinator =
            V1PreviewSyncCoordinator(
                syncRegionPreview: { _, _ in },
                syncRegionPreviews: {
                    receivedPreviews = $0
                },
                loadPreviewText: { _ in "" }
            )

        coordinator.refreshDynamicPreview(
            modelsByRegion: [
                .slotA: .init(
                    templateSourceText: "记录",
                    displayText: "记录"
                ),
                .slotD: .init(
                    templateSourceText: "{{memory_summary}}",
                    displayText: "记忆"
                )
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
