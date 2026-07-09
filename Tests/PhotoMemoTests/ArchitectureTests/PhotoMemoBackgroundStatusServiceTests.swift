#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@MainActor
@Suite("Background status service")
struct PhotoMemoBackgroundStatusServiceTests {

    @Test("Latest completed external job is not masked by older retryable failures")
    func latestCompletedExternalJobIsNotMaskedByOlderRetryableFailures() throws {

        let suiteName =
            "PhotoMemo.BackgroundStatusServiceTests.latest.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let olderFailureID =
            UUID()
        let latestCompletedID =
            UUID()
        let configuration =
            BatchConfigurationSnapshot(
                template: .template1,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        let jobs = [
            BatchJob(
                id: latestCompletedID,
                title: "10:22（11张）",
                createdAt:
                    Date(
                        timeIntervalSince1970: 200
                    ),
                updatedAt:
                    Date(
                        timeIntervalSince1970: 220
                    ),
                state: .completed,
                launchSource: .quickAction,
                configuration: configuration,
                tasks: [
                    BatchTask(
                        sourceURL:
                            URL(
                                fileURLWithPath:
                                    "/tmp/latest.heic"
                            ),
                        fileName: "latest.heic",
                        phase: .completed
                    )
                ]
            ),
            BatchJob(
                id: olderFailureID,
                title: "10:13（5张）",
                createdAt:
                    Date(
                        timeIntervalSince1970: 100
                    ),
                updatedAt:
                    Date(
                        timeIntervalSince1970: 120
                    ),
                state: .failed,
                launchSource: .quickAction,
                configuration: configuration,
                tasks: [
                    BatchTask(
                        sourceURL:
                            URL(
                                fileURLWithPath:
                                    "/tmp/older.heic"
                            ),
                        fileName: "older.heic",
                        phase: .failed,
                        failure:
                            BatchTaskFailure(
                                phase: .exporting,
                                message:
                                    "PHPhotosErrorDomain error 3164",
                                canRetry: true
                            )
                    )
                ]
            )
        ]

        defaults.set(
            try JSONEncoder().encode(jobs),
            forKey:
                "photomemo.batchQueue.jobs"
        )

        let store =
            BatchQueueStore(
                defaults: defaults,
                settingsService:
                    SettingsService(
                        defaults: defaults
                    )
            )
        let service =
            PhotoMemoBackgroundStatusService(
                batchQueueStore: store
            )

        #expect(
            service.currentSnapshot?.jobID
            == latestCompletedID
        )
        #expect(
            service.currentSnapshot?.presentationState
            == .completed
        )
        #expect(
            service.currentSnapshot?.feedbackState
            == .completed
        )

        defaults.removePersistentDomain(
            forName: suiteName
        )
    }
}
#endif
