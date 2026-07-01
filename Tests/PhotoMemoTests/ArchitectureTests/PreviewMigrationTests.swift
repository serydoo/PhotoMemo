#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Preview migration", .serialized)
struct PreviewMigrationTests {

    @MainActor
    @Test("UpdateRegionPreviewIntent writes preview text through PreviewCoordinator")
    func updateRegionPreviewIntentWritesPreviewTextThroughCoordinator() {

        let session =
            ConfigurationSession()
        let coordinator =
            PreviewCoordinator(
                buildService:
                    RecordCardBuildService()
            )

        let result =
            UpdateRegionPreviewIntent(
                region: .slotA,
                text: "记录 iPhone 17 Pro Max",
                session: session,
                coordinator: coordinator
            )
            .executeSynchronously()

        switch result {
        case .success:
            #expect(
                session.previewText(
                    for: .slotA
                )
                == "记录 iPhone 17 Pro Max"
            )
        case .failure(let error):
            Issue.record(
                "Expected single-region preview sync to succeed, got \(error.message)"
            )
        }
    }

    @MainActor
    @Test("UpdateRegionPreviewsIntent syncs multiple preview regions and LoadRegionPreviewTextIntent reads them back")
    func updateRegionPreviewsIntentSyncsMultipleRegionsAndLoadIntentReadsThemBack() {

        let session =
            ConfigurationSession()
        let coordinator =
            PreviewCoordinator(
                buildService:
                    RecordCardBuildService()
            )
        let previews: [CardRegion: String] = [
            .slotA: "记录 iPhone 17 Pro Max",
            .slotB: "记录于 2026.05.24 14:33:00",
            .slotC: "20mm f/1.9 1/117s ISO80",
            .slotD: "途途 当天 1岁"
        ]

        let syncResult =
            UpdateRegionPreviewsIntent(
                previews: previews,
                session: session,
                coordinator: coordinator
            )
            .executeSynchronously()

        switch syncResult {
        case .success:
            break
        case .failure(let error):
            Issue.record(
                "Expected multi-region preview sync to succeed, got \(error.message)"
            )
        }

        for (region, expectedText) in previews {
            let loadResult =
                LoadRegionPreviewTextIntent(
                    region: region,
                    session: session,
                    coordinator: coordinator
                )
                .executeSynchronously()

            switch loadResult {
            case .success(let text):
                #expect(text == expectedText)
            case .failure(let error):
                Issue.record(
                    "Expected preview load for \(region) to succeed, got \(error.message)"
                )
            }
        }
    }
}
#endif
