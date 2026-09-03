import Foundation
import Combine

/// Describes process-scoped runtime capabilities that are safe to expose to
/// presentation policy.  This is intentionally not persisted: UI automation
/// must be able to make deterministic choices without changing a user's
/// durable workflow state.
struct MemoMarkRuntimeEnvironment: Equatable, Sendable {

    let isUITestingHarness: Bool

    static var current: Self {
#if DEBUG
        Self(
            isUITestingHarness:
                ProcessInfo.processInfo.arguments.contains(
                    "-uiTestingHarnessOnly"
                )
        )
#else
        Self(isUITestingHarness: false)
#endif
    }
}

@MainActor
final class MemoMarkAppRuntime:
    ObservableObject {

    let runtimeEnvironment:
        MemoMarkRuntimeEnvironment = .current

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
            queueRuntime: batchQueueStore,
            prepareQueue: { [weak self] in
                await self?.flushExternalRequests()
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

    private let externalIntakeDrainCoordinator:
        ExternalIntakeDrainCoordinator

    private var cancellables:
        Set<AnyCancellable> = []

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
        self.externalIntakeDrainCoordinator =
            ExternalIntakeDrainCoordinator(
                externalIntakeCenter:
                    self.externalIntakeCenter,
                shareCoordinator:
                    environment.coordinators.share,
                queueProjection:
                    self.batchQueueStore
            )
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

        // File-open is an external production-intake path, not a UI shortcut.
        // Route it through the same coordinator as Share so the configuration
        // snapshot is refreshed from durable truth at the acceptance boundary.
        _ = environment
            .coordinators
            .share
            .submit(
                urls: urls,
                source: source
            )
    }

    @discardableResult
    func flushExternalRequests()
    async -> BackgroundQueuePreparationResult {
        await externalIntakeDrainCoordinator.drain()
    }

    func refreshExternalIntakeState() async {

        guard !externalIntakeDrainCoordinator.isDraining else {
            return
        }

        externalIntakeCenter.updateDefaultConfiguration(
            batchQueueStore
                .defaultConfigurationSnapshot
        )
        await flushExternalRequests()

        await batchQueueStore.retryPersistenceIfNeeded()

        guard permissionCenter.canAccessPhotoLibrary else {
            return
        }

        await batchQueueStore.startProcessingIfNeeded()

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
            await refreshExternalIntakeState()
        }
    }

    func authorizePhotoWorkflow() async {
        permissionCenter.markPrimerPresented()
        guard await permissionCenter
            .requestPhotoLibraryPermission() else {
            return
        }
        await refreshExternalIntakeState()
    }

    func authorizeNotificationWorkflow() async {
        permissionCenter.markPrimerPresented()
        _ = await permissionCenter
            .requestNotificationPermission()
    }

}
