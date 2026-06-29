import Foundation
import Testing
@testable import PhotoMemo

@Suite("BatchFixtureCoverage", .serialized)
struct BatchFixtureCoverageTests {

    @MainActor
    @Test("Builds single-item and multi-item fixture batches with stable task metadata")
    func buildsSingleAndMultiItemFixtureBatches() throws {

        let execution =
            BatchQueueExecution(
                externalIntakeStore:
                    makeExternalIntakeStore()
            )

        let firstURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .portraitJPEG
            )
        let secondURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .landscapeJPEG
            )

        let single =
            execution.enqueue(
                payloads: [
                    BatchTaskIntakePayload(
                        sourceURL: firstURL
                    )
                ],
                configuration:
                    makeConfiguration(),
                launchSource:
                    .shareExtension
            )

        let multi =
            execution.enqueue(
                payloads: [
                    BatchTaskIntakePayload(
                        sourceURL: firstURL
                    ),
                    BatchTaskIntakePayload(
                        sourceURL: secondURL
                    )
                ],
                configuration:
                    makeConfiguration(),
                launchSource:
                    .automation,
                title: "Fixture Batch"
            )

        #expect(single?.totalTaskCount == 1)
        #expect(
            single?.tasks.first?.fileName
            == firstURL.lastPathComponent
        )
        #expect(multi?.totalTaskCount == 2)
        #expect(multi?.title == "Fixture Batch")
        #expect(
            multi?.tasks.map(\.fileName)
            == [
                firstURL.lastPathComponent,
                secondURL.lastPathComponent
            ]
        )
        #expect(multi?.launchSource == .automation)
    }

    @Test("Formats share queues from start time and photo count")
    func formatsShareQueuesFromStartTimeAndPhotoCount() throws {

        let calendar =
            Calendar(identifier: .gregorian)
        let now =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 6,
                        day: 29,
                        hour: 20,
                        minute: 0
                    )
                )
            )
        let today =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 6,
                        day: 29,
                        hour: 18,
                        minute: 42
                    )
                )
            )
        let yesterday =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 6,
                        day: 28,
                        hour: 9,
                        minute: 7
                    )
                )
            )
        let earlierThisYear =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 2,
                        day: 3,
                        hour: 6,
                        minute: 5
                    )
                )
            )
        let previousYear =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2025,
                        month: 12,
                        day: 31,
                        hour: 23,
                        minute: 58
                    )
                )
            )

        #expect(
            PhotoMemoQueueDisplayFormatter.title(
                startedAt: today,
                photoCount: 3,
                now: now
            ) == "18:42（3张）"
        )
        #expect(
            PhotoMemoQueueDisplayFormatter.title(
                startedAt: yesterday,
                photoCount: 1,
                now: now
            ) == "昨天 09:07（1张）"
        )
        #expect(
            PhotoMemoQueueDisplayFormatter.title(
                startedAt: earlierThisYear,
                photoCount: 12,
                now: now
            ) == "2月3日 06:05（12张）"
        )
        #expect(
            PhotoMemoQueueDisplayFormatter.title(
                startedAt: previousYear,
                photoCount: 2,
                now: now
            ) == "2025年12月31日 23:58（2张）"
        )
    }

    @MainActor
    @Test("Share queue creation follows the earliest payload request time")
    func shareQueueCreationFollowsEarliestPayloadRequestTime() throws {

        let execution =
            BatchQueueExecution(
                externalIntakeStore:
                    makeExternalIntakeStore()
            )

        let firstURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .portraitJPEG
            )
        let secondURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .landscapeJPEG
            )
        let calendar =
            Calendar(identifier: .gregorian)
        let earlyRequest =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 6,
                        day: 29,
                        hour: 8,
                        minute: 12
                    )
                )
            )
        let laterRequest =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 6,
                        day: 29,
                        hour: 8,
                        minute: 15
                    )
                )
            )

        let job =
            try #require(
                execution.enqueue(
                    payloads: [
                        BatchTaskIntakePayload(
                            sourceURL: firstURL,
                            requestedAt: laterRequest
                        ),
                        BatchTaskIntakePayload(
                            sourceURL: secondURL,
                            requestedAt: earlyRequest
                        )
                    ],
                    configuration:
                        makeConfiguration(),
                    launchSource:
                        .shareExtension
                )
            )

        #expect(job.createdAt == earlyRequest)
        #expect(
            job.title
            == PhotoMemoQueueDisplayFormatter.title(
                startedAt: earlyRequest,
                photoCount: 2
            )
        )
    }

    @MainActor
    @Test("Payload provenance overrides temporary URL naming and survives into imported photos")
    func payloadProvenanceOverridesTemporaryURLNamingAndSurvivesIntoImportedPhotos() async throws {

        let execution =
            BatchQueueExecution(
                externalIntakeStore:
                    makeExternalIntakeStore()
            )

        let fixtureURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneJPEG
            )

        let job =
            execution.enqueue(
                payloads: [
                    BatchTaskIntakePayload(
                        sourceURL: fixtureURL,
                        sourceIdentifier: "asset-local-6001",
                        fileName: "IMG_6001.HEIC",
                        contentTypeIdentifier: "public.heic"
                    )
                ],
                configuration:
                    makeConfiguration(),
                launchSource:
                    .shareExtension
            )

        let task =
            try #require(job?.tasks.first)

        #expect(task.fileName == "IMG_6001.HEIC")
        #expect(task.sourceIdentifier == "asset-local-6001")
        #expect(task.contentTypeIdentifier == "public.heic")

        let importedPhoto =
            try await BatchProcessingCoordinator()
            .importPhoto(
                for: task
            )

        #expect(
            importedPhoto.sourceInfo.originalFileName
            == "IMG_6001.HEIC"
        )
        #expect(
            importedPhoto.sourceInfo.assetLocalIdentifier
            == "asset-local-6001"
        )
        #expect(
            importedPhoto.sourceInfo.contentTypeIdentifier
            == "public.heic"
        )
    }

    @MainActor
    @Test("Cancelling managed fixture batches cleans temporary copies and marks tasks cancelled")
    func cancellingManagedFixtureBatchCleansTemporaryCopies() throws {

        let context =
            try makeManagedBatchContext(
                fixtures: [
                    .noGPSJPEG,
                    .lowMetadataJPEG
                ]
            )

        defer {
            cleanup(
                directoryURL:
                    context.directoryURL,
                defaultsSuiteName:
                    context.defaultsSuiteName
            )
        }

        let execution =
            BatchQueueExecution(
                externalIntakeStore:
                    context.intakeStore
            )

        var jobs = [
            BatchJob(
                title: "Managed Fixtures",
                state: .queued,
                launchSource: .shareExtension,
                configuration:
                    makeConfiguration(),
                tasks: [
                    BatchTask(
                        sourceURL:
                            context.managedURLs[0]
                    ),
                    BatchTask(
                        sourceURL:
                            context.managedURLs[1],
                        phase: .importing
                    )
                ]
            )
        ]

        let didCancel =
            execution.cancelJob(
                in: &jobs,
                jobID: jobs[0].id
            )

        #expect(didCancel)
        #expect(jobs[0].state == .cancelled)
        #expect(
            jobs[0].tasks.allSatisfy {
                $0.phase == .cancelled
            }
        )
        #expect(
            context.managedURLs.allSatisfy {
                !FileManager.default
                    .fileExists(
                        atPath: $0.path
                    )
            }
        )
    }

    @MainActor
    @Test("Retry keeps non-retryable failures intact while requeueing eligible fixture tasks")
    func retryKeepsNonRetryableFailuresIntact() throws {

        let execution =
            BatchQueueExecution(
                externalIntakeStore:
                    makeExternalIntakeStore()
            )

        let retryableURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .gpsJPEG
            )
        let permanentFailureURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .noGPSJPEG
            )
        let completedURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneJPEG
            )

        var jobs = [
            BatchJob(
                title: "Retry Fixtures",
                state: .failed,
                configuration:
                    makeConfiguration(),
                tasks: [
                    BatchTask(
                        sourceURL:
                            retryableURL,
                        phase: .failed,
                        retryCount: 0,
                        failure:
                            BatchTaskFailure(
                                phase: .exporting,
                                message:
                                    "Temporary write error",
                                canRetry: true
                            )
                    ),
                    BatchTask(
                        sourceURL:
                            permanentFailureURL,
                        phase: .failed,
                        retryCount: 0,
                        failure:
                            BatchTaskFailure(
                                phase:
                                    .savingToPhotoLibrary,
                                message:
                                    "Source missing",
                                canRetry: false
                            )
                    ),
                    BatchTask(
                        sourceURL:
                            completedURL,
                        phase: .completed,
                        retryCount: 0
                    )
                ]
            )
        ]

        let didRetry =
            execution.retryFailedTasks(
                in: &jobs,
                jobID: jobs[0].id
            )

        #expect(didRetry)
        #expect(jobs[0].tasks[0].phase == .queued)
        #expect(jobs[0].tasks[0].retryCount == 1)
        #expect(jobs[0].tasks[0].failure == nil)
        #expect(jobs[0].tasks[1].phase == .failed)
        #expect(
            jobs[0].tasks[1].failure?.canRetry
            == false
        )
        #expect(jobs[0].tasks[2].phase == .completed)
        #expect(jobs[0].state == .queued)
    }
}

private extension BatchFixtureCoverageTests {

    struct ManagedBatchContext {

        let intakeStore:
            ExternalPhotoIntakeStore

        let directoryURL: URL

        let defaultsSuiteName: String

        let managedURLs: [URL]
    }

    func makeConfiguration()
    -> BatchConfigurationSnapshot {

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
            selectedAlbumIdentifier: ""
        )
    }

    func makeExternalIntakeStore()
    -> ExternalPhotoIntakeStore {

        let suiteName =
            "PhotoMemoTests.\(UUID().uuidString)"
        let defaults =
            UserDefaults(
                suiteName: suiteName
            ) ?? .standard
        let directoryURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )

        return ExternalPhotoIntakeStore(
            defaults: defaults,
            intakeDirectoryURL: directoryURL
        )
    }

    func makeManagedBatchContext(
        fixtures: [SyntheticFixture]
    ) throws -> ManagedBatchContext {

        let suiteName =
            "PhotoMemoTests.\(UUID().uuidString)"
        let defaults =
            UserDefaults(
                suiteName: suiteName
            ) ?? .standard
        let directoryURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )
        let intakeStore =
            ExternalPhotoIntakeStore(
                defaults: defaults,
                intakeDirectoryURL: directoryURL
            )

        let requestID = UUID()
        let managedURLs = try fixtures
            .enumerated()
            .map { index, fixture in

                let sourceURL =
                    try SyntheticFixtureLibrary
                    .fixtureURL(fixture)

                guard let managedURL =
                    intakeStore.createManagedCopy(
                        from: sourceURL,
                        requestID: requestID,
                        index: index
                    )
                else {
                    throw BatchFixtureCoverageError
                        .managedCopyCreationFailed(
                            sourceURL
                        )
                }

                return managedURL
            }

        return ManagedBatchContext(
            intakeStore: intakeStore,
            directoryURL: directoryURL,
            defaultsSuiteName: suiteName,
            managedURLs: managedURLs
        )
    }

    func cleanup(
        directoryURL: URL,
        defaultsSuiteName: String
    ) {

        try? FileManager.default.removeItem(
            at: directoryURL
        )
        UserDefaults(
            suiteName: defaultsSuiteName
        )?.removePersistentDomain(
            forName: defaultsSuiteName
        )
    }
}

private enum BatchFixtureCoverageError:
    LocalizedError {

    case managedCopyCreationFailed(URL)

    var errorDescription: String? {

        switch self {

        case let .managedCopyCreationFailed(url):
            return "Failed to create managed copy for \(url.lastPathComponent)."
        }
    }
}
