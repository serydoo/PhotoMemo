import Foundation
import Testing
@testable import PhotoMemo

@Suite("SharedBatchQueueSnapshotService")
struct SharedBatchQueueSnapshotServiceTests {

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
