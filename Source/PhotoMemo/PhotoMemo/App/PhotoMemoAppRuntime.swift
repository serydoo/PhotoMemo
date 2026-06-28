import Foundation
import Combine

@MainActor
final class PhotoMemoAppRuntime:
    ObservableObject {

    let batchQueueStore: BatchQueueStore

    let backgroundStatusService:
        PhotoMemoBackgroundStatusService

#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
    let backgroundExecutionService:
        PhotoMemoiOSBackgroundExecutionService

#if canImport(ActivityKit)
    let liveActivityBridgeService:
        PhotoMemoiOSLiveActivityBridgeService

    let liveActivityDriverService:
        PhotoMemoiOSLiveActivityDriverService
#endif
#endif

    let externalIntakeCenter:
        ExternalPhotoIntakeCenter

    private let externalIntakeStore:
        ExternalPhotoIntakeStore

    init(
        batchQueueStore: BatchQueueStore? = nil,
        externalIntakeCenter:
            ExternalPhotoIntakeCenter? = nil
    ) {
        self.batchQueueStore =
            batchQueueStore
            ?? BatchQueueStore()
        self.backgroundStatusService =
            PhotoMemoBackgroundStatusService(
                batchQueueStore:
                    self.batchQueueStore
            )
#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
        self.backgroundExecutionService =
            PhotoMemoiOSBackgroundExecutionService(
                batchQueueStore:
                    self.batchQueueStore
            )
#if canImport(ActivityKit)
        self.liveActivityBridgeService =
            PhotoMemoiOSLiveActivityBridgeService(
                backgroundStatusService:
                    self
                    .backgroundStatusService
            )
        self.liveActivityDriverService =
            PhotoMemoiOSLiveActivityDriverService(
                bridgeService:
                    self
                    .liveActivityBridgeService
            )
#endif
#endif
        self.externalIntakeCenter =
            externalIntakeCenter
            ?? .shared
        self.externalIntakeStore =
            .shared
    }

    func handleExternalURLs(
        _ urls: [URL],
        source: BatchJobLaunchSource
    ) {

        externalIntakeCenter.submit(
            urls: urls,
            importSummary: nil,
            source: source
        )
    }

    func flushExternalRequests() {

        let requests =
            externalIntakeCenter
            .drainPendingRequests()

        guard !requests.isEmpty else {
            return
        }

        for request in requests {
            let validPayloads =
                request.intakePayloads.filter {
                    isValidRequestSourceURL(
                        $0.sourceURL
                    )
                }

            let intakeSummary =
                resolvedIntakeSummary(
                    for: request,
                    validURLCount:
                        validPayloads.count
                )

            guard !validPayloads.isEmpty else {
                request.urls.forEach {
                    externalIntakeStore
                        .cleanupManagedSourceIfNeeded(
                            at: $0
                        )
                }
                continue
            }

            _ = batchQueueStore.enqueue(
                payloads: validPayloads,
                configuration:
                    request.configurationSnapshot,
                launchSource:
                    request.launchSource,
                intakeSummary:
                    intakeSummary,
                title:
                    resolvedRequestTitle(
                        receivedAt:
                            request.receivedAt,
                        taskCount:
                            validPayloads.count
                    )
                    )
        }

        externalIntakeCenter.updateDefaultConfiguration(
            batchQueueStore
                .defaultConfigurationSnapshot
        )
    }

    func refreshExternalIntakeState() {

        externalIntakeStore
            .cleanupOrphanedManagedContent(
                keepingReferencedURLs:
                    batchQueueStore
                    .referencedManagedSourceURLs
            )

        externalIntakeCenter.updateDefaultConfiguration(
            batchQueueStore
                .defaultConfigurationSnapshot
        )
        flushExternalRequests()
    }
}

private extension PhotoMemoAppRuntime {

    func resolvedRequestTitle(
        receivedAt: Date,
        taskCount: Int
    ) -> String {

        PhotoMemoQueueDisplayFormatter.title(
            startedAt:
                receivedAt,
            photoCount:
                taskCount
        )
    }

    func isValidRequestSourceURL(
        _ url: URL
    ) -> Bool {

        guard url.isFileURL else {
            return false
        }

        return FileManager.default
            .fileExists(
                atPath:
                    url.standardizedFileURL
                    .path
            )
    }

    func resolvedIntakeSummary(
        for request:
            ExternalPhotoIntakeRequest,
        validURLCount: Int
    ) -> ExternalPhotoImportSummary? {

        let droppedCount =
            max(
                request.urls.count
                - validURLCount,
                0
            )

        guard
            let existingSummary =
                request.importSummary
        else {
            guard droppedCount > 0 else {
                return nil
            }

            return ExternalPhotoImportSummary(
                importedCount:
                    validURLCount,
                skippedCount: 0,
                failedCount:
                    droppedCount
            )
        }

        let adjustedImportedCount =
            min(
                existingSummary.importedCount,
                validURLCount
            )

        let additionalFailedCount =
            max(
                existingSummary.importedCount
                - adjustedImportedCount,
                0
            )

        return ExternalPhotoImportSummary(
            importedCount:
                adjustedImportedCount,
            skippedCount:
                existingSummary.skippedCount,
            failedCount:
                existingSummary.failedCount
                + additionalFailedCount
        )
    }
}
