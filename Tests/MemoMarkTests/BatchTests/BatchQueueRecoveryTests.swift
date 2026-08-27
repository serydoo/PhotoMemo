import Foundation
import Testing
@testable import MemoMark

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

        #expect(reference?.jobID == newerJob.id)
        #expect(reference?.taskID == newerJob.tasks[0].id)
    }

    @Test("Resume marks missing managed intake sources as non retryable failures")
    func resumeMarksMissingManagedIntakeSourcesAsNonRetryableFailures() {

        let missingManagedURL =
            MemoMarkSharedContainer
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
        #expect(
            jobs[0].tasks[0].failure?.diagnosticCode
            == ProductionDiagnosticErrorCode
                .processingSourceMissing
                .rawValue
        )
        #expect(
            jobs[0].tasks[0].failure?.supportID?
                .hasPrefix("JOB-") == true
        )
        #expect(
            jobs[0].tasks[0].failure?.message
                .contains("接收的照片副本已不可用") == true
        )
        #expect(jobs[0].state == BatchJobState.failed)
    }

    @Test("Resume does not treat a sibling path prefix as managed intake")
    func resumeRejectsManagedIntakeSiblingPrefix() {
        let intakeRoot =
            MemoMarkSharedContainer
            .externalIntakeDirectoryURL
            .standardizedFileURL
        let missingSiblingURL =
            intakeRoot
            .deletingLastPathComponent()
            .appendingPathComponent(
                intakeRoot.lastPathComponent + "Backup",
                isDirectory: true
            )
            .appendingPathComponent(
                "missing-\(UUID().uuidString).jpg",
                isDirectory: false
            )
        var jobs = [
            Self.makeJob(
                title: "09:05（1张）",
                createdAt:
                    Date(timeIntervalSince1970: 100),
                sourceURL:
                    missingSiblingURL
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
        #expect(jobs[0].tasks[0].phase == BatchTaskPhase.queued)
        #expect(jobs[0].tasks[0].failure == nil)
        #expect(jobs[0].state == BatchJobState.queued)
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
                    template: .classicWhite,
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
