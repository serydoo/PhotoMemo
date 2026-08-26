import Foundation
import Combine

@MainActor
final class MemoMarkAppRuntime:
    ObservableObject {

    let commerceStore:
        MemoMarkCommerceStore

    let environment:
        AppEnvironment

    let batchQueueStore: BatchQueueStore

    let backgroundStatusService:
        MemoMarkBackgroundStatusService

    let permissionCenter = PermissionCenter()

#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
    lazy var backgroundTaskCoordinator =
        MemoMarkBackgroundTaskCoordinator(
            batchQueueStore: batchQueueStore,
            prepareQueue: { [weak self] in
                self?.flushExternalRequests()
                    ?? .retryableFailure
            }
        )
#endif

#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
    let backgroundExecutionService:
        MemoMarkiOSBackgroundExecutionService

#if canImport(ActivityKit)
    let liveActivityBridgeService:
        MemoMarkiOSLiveActivityBridgeService

    let liveActivityDriverService:
        MemoMarkiOSLiveActivityDriverService
#endif
#endif

    let externalIntakeCenter:
        ExternalPhotoIntakeCenter

    private let externalIntakeStore:
        ExternalPhotoIntakeStore

    private var cancellables:
        Set<AnyCancellable> = []

    private var isFlushingExternalRequests = false

    init(
        environment: AppEnvironment
    ) {
        SubjectAvatarAssetOptimizationService
            .cleanupTemporaryAssetDirectories()
        self.environment =
            environment
        self.commerceStore =
            MemoMarkCommerceStore(
                persistence:
                    MemoMarkCommercePersistence(
                        defaults:
                            environment.defaults
                    )
            )
        self.batchQueueStore =
            environment.batchQueueStore
        self.backgroundStatusService =
            MemoMarkBackgroundStatusService(
                batchQueueStore:
                    self.batchQueueStore
            )
#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
        self.backgroundExecutionService =
            MemoMarkiOSBackgroundExecutionService(
                batchQueueStore:
                    self.batchQueueStore,
                productionDiagnostics:
                    environment.repositories
                    .productionDiagnostics
            )
#if canImport(ActivityKit)
        self.liveActivityBridgeService =
            MemoMarkiOSLiveActivityBridgeService(
                backgroundStatusService:
                    self
                    .backgroundStatusService
            )
        self.liveActivityDriverService =
            MemoMarkiOSLiveActivityDriverService(
                bridgeService:
                    self
                    .liveActivityBridgeService
            )
#endif
#endif
        self.externalIntakeCenter =
            environment.externalIntakeCenter
        self.externalIntakeStore =
            environment.services
            .externalIntakeStore
#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
        self.backgroundTaskCoordinator.register()
#endif

        commerceStore.$snapshot
            .removeDuplicates()
            .sink { [weak batchQueueStore] snapshot in
                batchQueueStore?
                    .updateCommerceSnapshot(snapshot)
            }
            .store(in: &cancellables)

        batchQueueStore.$commerceSnapshot
            .removeDuplicates()
            .sink { [weak commerceStore] snapshot in
                commerceStore?
                    .adoptSharedSnapshot(snapshot)
            }
            .store(in: &cancellables)

        Task { [weak self] in
            guard let self else {
                return
            }
            await self.commerceStore.start()
            let marketingVersion =
                Bundle.main.object(
                    forInfoDictionaryKey:
                        "CFBundleShortVersionString"
                ) as? String ?? "1"
            self.commerceStore
                .applyMajorVersionGiftIfNeeded(
                    marketingVersion:
                        marketingVersion
                )
            self.batchQueueStore
                .updateCommerceSnapshot(
                    self.commerceStore.snapshot
                )
        }
    }

    convenience init(
        batchQueueStore: BatchQueueStore? = nil,
        externalIntakeCenter:
            ExternalPhotoIntakeCenter? = nil
    ) {
        self.init(
            environment:
                AppEnvironment.live(
                    batchQueueStore:
                        batchQueueStore,
                    externalIntakeCenter:
                        externalIntakeCenter
                )
        )
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

    @discardableResult
    func flushExternalRequests()
    -> BackgroundQueuePreparationResult {

        guard !isFlushingExternalRequests else {
            return .retryableFailure
        }
        isFlushingExternalRequests = true
        defer {
            isFlushingExternalRequests = false
        }

        let requests =
            externalIntakeCenter
            .drainPendingRequests()

        MemoMarkShareDiagnostics.record(
            stage: .appDrain,
            message: "drainedRequests=\(requests.count)"
        )

        if let failure = externalIntakeCenter.intakePersistenceError {
            MemoMarkShareDiagnostics.record(
                stage: .appDrain,
                message:
                    "requestPersistenceReadFailed storageKey=\(failure.storageKey) bytes=\(failure.payloadByteCount)"
            )
        }

        guard externalIntakeCenter.intakePersistenceError == nil else {
            return BackgroundQueuePreparationResult.resolve(
                enqueuedRequestCount: 0,
                failedRequestCount: 1,
                pendingTaskCount: batchQueueStore.pendingTaskCount
            )
        }

        guard !requests.isEmpty else {
            return BackgroundQueuePreparationResult.resolve(
                enqueuedRequestCount: 0,
                failedRequestCount: 0,
                pendingTaskCount: batchQueueStore.pendingTaskCount
            )
        }

        var consumedPayloadKeys = Set<String>()
        var enqueuedRequestCount = 0
        var failedRequestCount = 0

        for request in requests {
            let processedRequest =
                ProcessShareIntent(
                    request: request,
                    consumedPayloadKeys:
                        consumedPayloadKeys,
                    coordinator:
                        environment
                        .coordinators
                        .share
                )
                .executeSynchronously()

            switch processedRequest {
            case .success(let receipt):
                consumedPayloadKeys =
                    receipt.consumedPayloadKeys

                MemoMarkShareDiagnostics.record(
                    stage: .appRequestValidated,
                    message:
                        "payloads=\(receipt.requestedPayloadCount), valid=\(receipt.validPayloadCount), unique=\(receipt.uniquePayloadCount)",
                    requestID:
                        receipt.requestID
                )
                if receipt.job != nil {
                    enqueuedRequestCount += 1
                }

                if let droppedReason =
                    receipt.droppedReason {
                    MemoMarkShareDiagnostics.record(
                        stage: .appRequestDropped,
                        message:
                            droppedReason,
                        requestID:
                            receipt.requestID
                    )
                    recordAcknowledgementResult(
                        externalIntakeCenter
                            .acknowledgeProcessedRequests(
                                [request]
                            ),
                        requestID:
                            request.id
                    )
                    continue
                }

                MemoMarkShareDiagnostics.record(
                    stage: .appEnqueueCreated,
                    message:
                        "tasks=\(receipt.uniquePayloadCount)",
                    requestID:
                        receipt.requestID,
                    jobID:
                        receipt.job?.id
                )

                recordEnqueuedTaskRoutes(
                    in: receipt.job,
                    requestID:
                        receipt.requestID
                )
                recordAcknowledgementResult(
                    externalIntakeCenter
                        .acknowledgeProcessedRequests(
                            [request]
                        ),
                    requestID:
                        request.id
                )
            case .failure(let error):
                failedRequestCount += 1
                MemoMarkShareDiagnostics.record(
                    stage: .appEnqueueFailed,
                    message:
                        error.message,
                    requestID:
                        request.id
                )
            }
        }

        externalIntakeCenter.updateDefaultConfiguration(
            batchQueueStore
                .defaultConfigurationSnapshot
        )

        return BackgroundQueuePreparationResult.resolve(
            enqueuedRequestCount: enqueuedRequestCount,
            failedRequestCount: failedRequestCount,
            pendingTaskCount: batchQueueStore.pendingTaskCount
        )
    }

    private func recordAcknowledgementResult(
        _ result:
            MemoMarkSharedDefaultsWriteResult,
        requestID: UUID
    ) {

        guard case .encodingFailed(let failure) = result else {
            return
        }

        MemoMarkShareDiagnostics.record(
            stage:
                .appRequestAcknowledgementFailed,
            message:
                "storageKey=\(failure.storageKey)",
            requestID:
                requestID
        )
    }

    func refreshExternalIntakeState() {

        guard !isFlushingExternalRequests else {
            return
        }

        externalIntakeCenter.updateDefaultConfiguration(
            batchQueueStore
                .defaultConfigurationSnapshot
        )
        flushExternalRequests()

        batchQueueStore.retryPersistenceIfNeeded()

        guard permissionCenter.canAccessPhotoLibrary else {
            return
        }

        batchQueueStore.startProcessingIfNeeded()

        guard externalIntakeCenter.intakePersistenceError == nil else {
            return
        }

        guard let intakeReferencedURLs =
            externalIntakeCenter
            .referencedManagedSourceURLs() else {
            return
        }

        externalIntakeStore
            .cleanupOrphanedManagedContent(
                keepingReferencedURLs:
                    batchQueueStore
                    .referencedManagedSourceURLs
                    .union(intakeReferencedURLs)
            )
    }

    func refreshPermissionsAndResume() async {
        await permissionCenter.refreshStatuses()
        if permissionCenter.canAccessPhotoLibrary {
            refreshExternalIntakeState()
        }
    }

    func authorizePhotoWorkflow() async {
        permissionCenter.markPrimerPresented()
        guard await permissionCenter
            .requestPhotoLibraryPermission() else {
            return
        }
        refreshExternalIntakeState()
    }

    func authorizeNotificationWorkflow() async {
        permissionCenter.markPrimerPresented()
        _ = await permissionCenter
            .requestNotificationPermission()
    }

    private func recordEnqueuedTaskRoutes(
        in job: BatchJob?,
        requestID: UUID
    ) {

        guard let job else {
            return
        }

        for task in job.tasks.prefix(20) {
            let contentType =
                task.contentTypeIdentifier
                ?? "nil"
            let hasSourceIdentifier =
                task.sourceIdentifier?
                .isEmpty == false

            MemoMarkShareDiagnostics.record(
                stage: .appEnqueueTaskRoute,
                message:
                    "taskID=\(task.id.uuidString), contentType=\(contentType), hasSourceIdentifier=\(hasSourceIdentifier)",
                requestID: requestID,
                jobID: job.id
            )
        }
    }
}
