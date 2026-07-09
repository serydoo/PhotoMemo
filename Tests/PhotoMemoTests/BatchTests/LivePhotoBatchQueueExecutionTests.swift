#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("Live Photo batch queue execution")
struct LivePhotoBatchQueueExecutionTests {

    @MainActor
    @Test("Live Photo payloads are handled by the internal Live Photo processor")
    func livePhotoPayloadsUseInternalLivePhotoProcessor() async throws {
        let suiteName =
            "PhotoMemo.LivePhotoBatchQueueExecutionTests.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let intakeDirectoryURL =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )
        defer {
            try? FileManager.default.removeItem(
                at: intakeDirectoryURL
            )
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let livePhotoType =
            try #require(
                UTType("com.apple.live-photo")
            )
        let processor =
            RecordingLivePhotoBatchTaskProcessor()
        let store =
            BatchQueueStore(
                defaults: defaults,
                settingsService:
                    SettingsService(
                        defaults: defaults
                    ),
                externalIntakeStore:
                    ExternalPhotoIntakeStore(
                        defaults: defaults,
                        intakeDirectoryURL:
                            intakeDirectoryURL
                    ),
                livePhotoProcessor:
                    processor
            )
        let configuration =
            makeConfiguration(
                outputMode:
                    .originalFormat
            )

        _ = store.enqueue(
            payloads: [
                BatchTaskIntakePayload(
                    sourceURL:
                        URL(
                            fileURLWithPath:
                                "/tmp/IMG_6093.HEIC"
                        ),
                    sourceIdentifier:
                        "live-photo-local-identifier",
                    fileName: "IMG_6093.HEIC",
                    contentTypeIdentifier:
                        livePhotoType.identifier
                )
            ],
            configuration:
                configuration,
            launchSource:
                .quickAction
        )

        let didFinish =
            await waitForQueueToFinish(
                store
            )

        #expect(didFinish)
        #expect(
            processor.requests.map(\.task.sourceIdentifier)
            == [
                "live-photo-local-identifier"
            ]
        )
        #expect(
            processor.requests.first?.configuration
                .v1MediaOutputMode
            == .originalFormat
        )
        #expect(
            store.jobs.first?.tasks.first?.phase
            == .completed
        )
        #expect(
            store.jobs.first?.tasks.first?
                .savedAssetIdentifier
            == "rendered-live-photo-asset"
        )
    }
}

private extension LivePhotoBatchQueueExecutionTests {

    @MainActor
    func makeConfiguration(
        outputMode: V1MediaOutputMode
    ) -> BatchConfigurationSnapshot {
        BatchConfigurationSnapshot(
            template:
                .template1
                .normalizedForEditing,
            badge: nil,
            anchor: nil,
            shouldWritePhotoDescription:
                true,
            photoDescriptionOverride:
                "",
            selectedAlbumIdentifier: "",
            mediaOutputModeRawValue:
                outputMode.rawValue
        )
    }

    @MainActor
    func waitForQueueToFinish(
        _ store: BatchQueueStore
    ) async -> Bool {
        for _ in 0..<50 {
            if store.jobs.first?.tasks.first?.phase
                .isTerminal == true {
                return true
            }

            try? await Task.sleep(
                nanoseconds: 20_000_000
            )
        }

        return store.jobs.first?.tasks.first?.phase
            .isTerminal == true
    }
}

@MainActor
private final class RecordingLivePhotoBatchTaskProcessor:
    LivePhotoBatchTaskProcessing {

    struct Request {
        let task: BatchTask
        let configuration: BatchConfigurationSnapshot
    }

    private(set) var requests: [Request] = []

    func process(
        task: BatchTask,
        configuration: BatchConfigurationSnapshot
    ) async throws -> LivePhotoBatchTaskResult {
        requests.append(
            Request(
                task: task,
                configuration: configuration
            )
        )

        return LivePhotoBatchTaskResult(
            saveResult:
                PhotoLibrarySaveResult(
                    albumTitle: "MemoMark",
                    assetLocalIdentifier:
                        "rendered-live-photo-asset"
                ),
            notificationSourceURL: nil,
            temporaryFileURLs: []
        )
    }
}
#endif
