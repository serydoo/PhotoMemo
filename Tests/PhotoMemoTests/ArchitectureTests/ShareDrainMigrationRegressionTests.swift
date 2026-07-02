#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("Share drain migration regression", .serialized)
struct ShareDrainMigrationRegressionTests {

    @MainActor
    @Test("SubmitExternalURLsIntent refreshes configuration and keeps only supported unique image inputs")
    func submitExternalURLsIntentRefreshesConfigurationAndFiltersInputs() async throws {

        let context = try Self.makeContext(
            named:
                "PhotoMemo.ShareDrainMigrationRegressionTests.Submit.\(UUID().uuidString)"
        )
        defer { Self.cleanup(context) }

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneJPEG
            )
        let unsupportedURL =
            context.rootDirectoryURL
            .appendingPathComponent("notes.txt")

        try Data("not-an-image".utf8).write(
            to: unsupportedURL
        )

        let latestSnapshot =
            context.environment.repositories
            .configuration
            .loadDefaultBatchConfigurationSnapshot()
        var staleSnapshot =
            latestSnapshot
        staleSnapshot.selectedAlbumIdentifier =
            "stale-album"
        staleSnapshot.photoDescriptionOverride =
            "stale-description"

        context.environment.externalIntakeCenter
            .updateDefaultConfiguration(
                staleSnapshot
            )

        let importSummary =
            ExternalPhotoImportSummary(
                importedCount: 1,
                skippedCount: 1,
                failedCount: 1
            )
        let result =
            await SubmitExternalURLsIntent(
                urls: [
                    sourceURL,
                    sourceURL,
                    unsupportedURL
                ],
                importSummary:
                    importSummary,
                source: .shareExtension,
                coordinator:
                    context.environment
                    .coordinators.share
            )
            .execute()

        switch result {
        case .success(let receipt):
            #expect(
                receipt.requestedURLCount == 3
            )
            #expect(
                receipt.source == .shareExtension
            )
        case .failure(let error):
            Issue.record(
                "Expected submit intent to succeed, got \(error.message)"
            )
        }

        let drainedResult =
            context.environment.coordinators
            .share
            .drainPendingRequests()

        switch drainedResult {
        case .success(let requests):
            #expect(requests.count == 1)

            let request =
                try #require(
                    requests.first
                )

            #expect(
                request.launchSource
                == .shareExtension
            )
            #expect(
                request.importSummary
                == importSummary
            )
            #expect(
                request.configurationSnapshot
                    .selectedAlbumIdentifier
                == latestSnapshot
                    .selectedAlbumIdentifier
            )
            #expect(
                request.configurationSnapshot
                    .photoDescriptionOverride
                == latestSnapshot
                    .photoDescriptionOverride
            )
            #expect(
                request.configurationSnapshot
                    .selectedAlbumIdentifier
                != staleSnapshot
                    .selectedAlbumIdentifier
            )
            #expect(
                request.configurationSnapshot
                    .photoDescriptionOverride
                != staleSnapshot
                    .photoDescriptionOverride
            )
            #expect(request.urls.count == 1)
            #expect(
                request.items?.count == 1
            )

            let managedURL =
                try #require(
                    request.urls.first
                )

            #expect(
                managedURL.path.hasPrefix(
                    context.intakeDirectoryURL.path
                )
            )
            #expect(
                FileManager.default.fileExists(
                    atPath: managedURL.path
                )
            )
        case .failure(let error):
            Issue.record(
                "Expected drain to succeed, got \(error.message)"
            )
        }
    }

    @MainActor
    @Test("QueueCoordinator enqueues drained share requests without changing launch source or payload metadata")
    func queueCoordinatorEnqueuesDrainedShareRequestsWithoutChangingSemantics() async throws {

        let context = try Self.makeContext(
            named:
                "PhotoMemo.ShareDrainMigrationRegressionTests.Enqueue.\(UUID().uuidString)"
        )
        defer { Self.cleanup(context) }

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneJPEG
            )
        let importSummary =
            ExternalPhotoImportSummary(
                importedCount: 1,
                skippedCount: 0,
                failedCount: 0
            )

        _ =
            await SubmitExternalURLsIntent(
                urls: [sourceURL],
                importSummary:
                    importSummary,
                source: .shareExtension,
                coordinator:
                    context.environment
                    .coordinators.share
            )
            .execute()

        let request =
            try #require(
                context.environment.coordinators
                .share
                .drainPendingRequests()
                .value?
                .first
            )
        let payload =
            try #require(
                request.intakePayloads.first
            )
        let result =
            context.environment.coordinators
            .queue
            .enqueue(
                payloads:
                    request.intakePayloads,
                configuration:
                    request.configurationSnapshot,
                launchSource:
                    request.launchSource,
                intakeSummary:
                    request.importSummary
            )

        switch result {
        case .success(let job):
            #expect(
                job.launchSource
                == request.launchSource
            )
            #expect(
                job.configuration
                == request.configurationSnapshot
            )
            #expect(
                job.intakeSummary
                == importSummary
            )
            #expect(job.tasks.count == 1)

            let task =
                try #require(
                    job.tasks.first
                )

            #expect(
                task.sourceURL
                == payload.sourceURL
            )
            #expect(
                task.fileName
                == (
                    payload.fileName
                    ?? payload.sourceURL
                        .lastPathComponent
                )
            )
            #expect(
                task.sourceIdentifier
                == payload.sourceIdentifier
            )
            #expect(
                task.contentTypeIdentifier
                == payload.contentTypeIdentifier
            )
            #expect(
                context.environment
                .batchQueueStore.jobs
                .contains {
                    $0.id == job.id
                }
            )
        case .failure(let error):
            Issue.record(
                "Expected queue coordinator to enqueue the drained request, got \(error.message)"
            )
        }
    }

    @MainActor
    @Test("ProcessShareIntent enqueues a drained request without changing request semantics")
    func processShareIntentEnqueuesDrainedRequestWithoutChangingSemantics() async throws {

        let context = try Self.makeContext(
            named:
                "PhotoMemo.ShareDrainMigrationRegressionTests.ProcessIntent.\(UUID().uuidString)"
        )
        defer { Self.cleanup(context) }

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneJPEG
            )
        let receivedAt =
            try #require(
                Calendar(identifier: .gregorian)
                .date(
                    from: DateComponents(
                        year: 2026,
                        month: 6,
                        day: 30,
                        hour: 14,
                        minute: 18
                    )
                )
            )
        let summary =
            ExternalPhotoImportSummary(
                importedCount: 1,
                skippedCount: 0,
                failedCount: 0
            )
        let request =
            ExternalPhotoIntakeRequest(
                launchSource: .shareExtension,
                urls: [sourceURL],
                items: [
                    ExternalPhotoIntakeItem(
                        managedURL: sourceURL,
                        originalFileName:
                            "IMG_9558.HEIC",
                        sourceIdentifier:
                            "asset-local-9558",
                        contentTypeIdentifier:
                            UTType.heic.identifier
                    )
                ],
                configurationSnapshot:
                    context.environment
                    .repositories
                    .configuration
                    .loadDefaultBatchConfigurationSnapshot(),
                importSummary: summary,
                receivedAt: receivedAt
            )

        let result =
            await ProcessShareIntent(
                request: request,
                consumedPayloadKeys: [],
                coordinator:
                    context.environment
                    .coordinators.share
            )
            .execute()

        switch result {
        case .success(let receipt):
            #expect(
                receipt.requestID
                == request.id
            )
            #expect(
                receipt.validPayloadCount
                == 1
            )
            #expect(
                receipt.uniquePayloadCount
                == 1
            )
            #expect(
                receipt.intakeSummary
                == summary
            )

            let job =
                try #require(
                    receipt.job
                )

            #expect(
                job.launchSource
                == request.launchSource
            )
            #expect(
                job.configuration
                == request.configurationSnapshot
            )
            #expect(
                job.intakeSummary
                == summary
            )
            #expect(
                job.title
                == PhotoMemoQueueDisplayFormatter.title(
                    startedAt:
                        receivedAt,
                    photoCount: 1
                )
            )
        case .failure(let error):
            Issue.record(
                "Expected process share intent to succeed, got \(error.message)"
            )
        }
    }
}

private extension ShareDrainMigrationRegressionTests {

    struct TestContext {

        let suiteName: String

        let defaults: UserDefaults

        let rootDirectoryURL: URL

        let intakeDirectoryURL: URL

        let environment: AppEnvironment
    }

    @MainActor
    static func makeContext(
        named suiteName: String
    ) throws -> TestContext {

        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let rootDirectoryURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )
        let intakeDirectoryURL =
            rootDirectoryURL
            .appendingPathComponent(
                "ExternalIntake",
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: rootDirectoryURL,
            withIntermediateDirectories: true
        )

        let environment =
            AppEnvironment.live(
                defaults: defaults,
                intakeDirectoryURL:
                    intakeDirectoryURL
            )

        return TestContext(
            suiteName: suiteName,
            defaults: defaults,
            rootDirectoryURL:
                rootDirectoryURL,
            intakeDirectoryURL:
                intakeDirectoryURL,
            environment: environment
        )
    }

    static func cleanup(
        _ context: TestContext
    ) {

        try? FileManager.default.removeItem(
            at: context.rootDirectoryURL
        )
        context.defaults.removePersistentDomain(
            forName: context.suiteName
        )
    }
}
#endif
