import Foundation
import Testing
@testable import PhotoMemo

@Suite("Batch queue recovery")
struct BatchQueueRecoveryTests {

    @MainActor
    @Test("Newest queued share job is selected before older queued jobs")
    func newestQueuedShareJobIsSelectedBeforeOlderQueuedJobs() {

        let execution =
            BatchQueueExecution()
        let olderJob =
            Self.makeJob(
                title: "09:05（1张）",
                createdAt:
                    Date(timeIntervalSince1970: 100),
                sourceURL:
                    URL(fileURLWithPath: "/tmp/old-share.jpg")
            )
        let newerJob =
            Self.makeJob(
                title: "09:12（1张）",
                createdAt:
                    Date(timeIntervalSince1970: 200),
                sourceURL:
                    URL(fileURLWithPath: "/tmp/new-share.jpg")
            )

        let reference =
            execution.nextPendingTaskReference(
                in: [
                    newerJob,
                    olderJob
                ]
            )

        #expect(reference?.jobIndex == 0)
        #expect(reference?.taskIndex == 0)
    }

    @Test("Resume marks missing managed intake sources as non retryable failures")
    func resumeMarksMissingManagedIntakeSourcesAsNonRetryableFailures() {

        let missingManagedURL =
            PhotoMemoSharedContainer
            .externalIntakeDirectoryURL
            .appendingPathComponent(
                "missing-\(UUID().uuidString)",
                isDirectory: true
            )
            .appendingPathComponent(
                "photo.jpg",
                isDirectory: false
            )
        var jobs = [
            Self.makeJob(
                title: "09:05（1张）",
                createdAt:
                    Date(timeIntervalSince1970: 100),
                sourceURL:
                    missingManagedURL
            )
        ]

        let changed =
            BatchQueuePersistence()
            .normalizeJobsForResume(
                &jobs,
                deriveJobState:
                    BatchQueueExecution()
                    .derivedJobState(from:)
            )

        #expect(changed)
        #expect(jobs[0].tasks[0].phase == BatchTaskPhase.failed)
        #expect(jobs[0].tasks[0].failure?.canRetry == false)
        #expect(jobs[0].state == BatchJobState.failed)
    }
}

private extension BatchQueueRecoveryTests {

    static func makeJob(
        title: String,
        createdAt: Date,
        sourceURL: URL
    ) -> BatchJob {

        BatchJob(
            title: title,
            createdAt: createdAt,
            updatedAt: createdAt,
            state: .queued,
            launchSource: .shareExtension,
            configuration:
                BatchConfigurationSnapshot(
                    template: .template1,
                    badge: nil,
                    anchor: nil,
                    shouldWritePhotoDescription: true,
                    photoDescriptionOverride: "",
                    selectedAlbumIdentifier: ""
                ),
            tasks: [
                BatchTask(
                    sourceURL:
                        sourceURL,
                    phase:
                        .queued
                )
            ]
        )
    }
}
