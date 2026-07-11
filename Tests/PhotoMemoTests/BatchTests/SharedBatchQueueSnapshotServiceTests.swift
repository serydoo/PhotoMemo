import Foundation
import Testing
@testable import PhotoMemo

@Suite("SharedBatchQueueSnapshotService")
struct SharedBatchQueueSnapshotServiceTests {

    @Test("Specific-job snapshot loads distinguish empty, corrupted, missing-job, and success states")
    func specificJobSnapshotLoadsDistinguishFailureModes() throws {

        let suiteName =
            "photomemo.sharedBatchQueueSnapshot.loadResult.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let service =
            SharedBatchQueueSnapshotService(
                defaults: defaults
            )
        let requestedJobID =
            UUID()

        switch service.loadSnapshotResult(
            for: requestedJobID
        ) {
        case .noValue:
            break
        case .success,
             .jobNotFound,
             .decodingFailed:
            Issue.record(
                "Expected .noValue when no shared queue payload exists."
            )
        }

        defaults.set(
            Data("bad-snapshot".utf8),
            forKey:
                "photomemo.batchQueue.jobs"
        )

        switch service.loadSnapshotResult(
            for: requestedJobID
        ) {
        case .decodingFailed(let failure):
            #expect(
                failure.storageKey
                == "photomemo.batchQueue.jobs"
            )
            #expect(
                failure.payloadByteCount
                == Data("bad-snapshot".utf8).count
            )
        case .noValue,
             .success,
             .jobNotFound:
            Issue.record(
                "Expected .decodingFailed for corrupted shared queue payload."
            )
        }

        let persistedJob =
            BatchJob(
                id: UUID(),
                title: "Persisted Job",
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
                            URL(
                                fileURLWithPath:
                                    "/tmp/queued.jpg"
                            ),
                        fileName:
                            "queued.jpg",
                        phase: .queued
                    )
                ]
            )

        defaults.set(
            try JSONEncoder().encode(
                [persistedJob]
            ),
            forKey:
                "photomemo.batchQueue.jobs"
        )

        switch service.loadSnapshotResult(
            for: requestedJobID
        ) {
        case .jobNotFound:
            break
        case .noValue,
             .success,
             .decodingFailed:
            Issue.record(
                "Expected .jobNotFound when the queue payload exists without the requested job."
            )
        }

        switch service.loadSnapshotResult(
            for: persistedJob.id
        ) {
        case .success(let snapshot):
            #expect(snapshot.id == persistedJob.id)
            #expect(snapshot.totalCount == 1)
        case .noValue,
             .jobNotFound,
             .decodingFailed:
            Issue.record(
                "Expected .success for a persisted shared queue job."
            )
        }
    }

    @Test("Distinguishes missing shared queue data from decode failure")
    func distinguishesMissingDataFromDecodeFailure() throws {

        let suiteName =
            "photomemo.sharedBatchQueueSnapshot.result.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let service =
            SharedBatchQueueSnapshotService(
                defaults: defaults
            )

        switch service.loadJobsResult() {
        case .noValue:
            break
        case .success,
             .decodingFailed:
            Issue.record(
                "Expected .noValue for empty shared defaults payload."
            )
        }

        defaults.set(
            Data("not-json".utf8),
            forKey:
                "photomemo.batchQueue.jobs"
        )

        switch service.loadJobsResult() {
        case .decodingFailed(let failure):
            #expect(
                failure.storageKey
                == "photomemo.batchQueue.jobs"
            )
            #expect(
                failure.payloadByteCount
                == Data("not-json".utf8).count
            )
            #expect(
                !failure.underlyingDescription.isEmpty
            )
        case .noValue,
             .success:
            Issue.record(
                "Expected .decodingFailed for corrupted shared queue payload."
            )
        }
    }

    @Test("Reads persisted batch jobs as lightweight snapshots")
    func readsPersistedBatchJobsAsLightweightSnapshots() throws {

        let suiteName =
            "photomemo.sharedBatchQueueSnapshot.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let jobID =
            UUID()
        let jobs = [
            BatchJob(
                id: jobID,
                title: "Share Test",
                state: .running,
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
                            URL(
                                fileURLWithPath:
                                    "/tmp/queued.jpg"
                            ),
                        fileName:
                            "queued.jpg",
                        phase: .queued
                    ),
                    BatchTask(
                        sourceURL:
                            URL(
                                fileURLWithPath:
                                    "/tmp/exporting.jpg"
                            ),
                        fileName:
                            "exporting.jpg",
                        phase: .exporting,
                        progress:
                            BatchTaskProgress(
                                currentUnit: 2,
                                totalUnits: 4,
                                statusMessage:
                                    "正在生成图片"
                            )
                    ),
                    BatchTask(
                        sourceURL:
                            URL(
                                fileURLWithPath:
                                    "/tmp/completed.jpg"
                            ),
                        fileName:
                            "completed.jpg",
                        phase: .completed,
                        progress:
                            BatchTaskProgress(
                                currentUnit: 4,
                                totalUnits: 4,
                                statusMessage:
                                    "处理完成"
                            )
                    ),
                    BatchTask(
                        sourceURL:
                            URL(
                                fileURLWithPath:
                                    "/tmp/failed.jpg"
                            ),
                        fileName:
                            "failed.jpg",
                        phase: .failed,
                        failure:
                            BatchTaskFailure(
                                phase: .exporting,
                                message: "导出失败"
                            )
                    )
                ]
            )
        ]

        let data =
            try JSONEncoder()
            .encode(jobs)
        defaults.set(
            data,
            forKey:
                "photomemo.batchQueue.jobs"
        )

        let snapshot =
            try #require(
                SharedBatchQueueSnapshotService(
                    defaults: defaults
                )
                .loadSnapshot(
                    for: jobID
                )
            )

        #expect(snapshot.totalCount == 4)
        #expect(snapshot.completedCount == 1)
        #expect(snapshot.failedCount == 1)
        #expect(snapshot.runningCount == 2)
        #expect(snapshot.firstActiveTaskIndex == 0)
        #expect(snapshot.tasks[1].progressFraction == 0.5)
        #expect(snapshot.tasks[1].statusMessage == "正在生成图片")
        #expect(snapshot.tasks[3].failureMessage == "导出失败")
    }
}
