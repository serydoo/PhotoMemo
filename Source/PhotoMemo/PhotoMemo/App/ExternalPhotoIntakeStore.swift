import Foundation

struct ExternalPhotoIntakeDrainResult {
    let requests:
        [ExternalPhotoIntakeRequest]

    let clearPersistedRequestsResult:
        PhotoMemoSharedDefaultsWriteResult?
}

final class ExternalPhotoIntakeStore {

    static let shared =
        ExternalPhotoIntakeStore()

    private let requestStore:
        ExternalIntakeRequestStore

    private let managedFileStore:
        ManagedIntakeFileStore

    private let cleanupService:
        IntakeCleanupService

    init(
        defaults: UserDefaults =
            PhotoMemoSharedContainer
            .sharedUserDefaults,
        intakeDirectoryURL: URL =
            PhotoMemoSharedContainer
            .externalIntakeDirectoryURL
    ) {
        self.requestStore =
            ExternalIntakeRequestStore(
                defaults: defaults
            )
        self.managedFileStore =
            ManagedIntakeFileStore(
                intakeDirectoryURL:
                    intakeDirectoryURL
            )
        self.cleanupService =
            IntakeCleanupService(
                intakeDirectoryURL:
                    intakeDirectoryURL
            )
    }

    func persistRequest(
        urls: [URL],
        source: BatchJobLaunchSource,
        importSummary:
            ExternalPhotoImportSummary? = nil,
        configurationSnapshot:
            BatchConfigurationSnapshot
    ) -> ExternalPhotoIntakeRequest? {

        let normalizedInputURLs =
            managedFileStore
            .uniqueStandardizedURLs(
                from: urls
            )

        let requestID = UUID()
        let managedURLs =
            managedFileStore
            .preparedManagedURLs(
                for: normalizedInputURLs,
                requestID: requestID
            )

        guard !managedURLs.isEmpty else {
            return nil
        }

        let managedItems =
            managedURLs.map {
                ExternalPhotoIntakeItem(
                    managedURL: $0
                )
            }

        return persistManagedRequest(
            id: requestID,
            urls: managedURLs,
            items: managedItems,
            source: source,
            importSummary:
                importSummary,
            configurationSnapshot:
                configurationSnapshot
        )
    }

    func persistRequest(
        items: [ExternalPhotoIntakeItem],
        source: BatchJobLaunchSource,
        importSummary:
            ExternalPhotoImportSummary? = nil,
        configurationSnapshot:
            BatchConfigurationSnapshot
    ) -> ExternalPhotoIntakeRequest? {

        let normalizedItems =
            managedFileStore
            .uniqueIntakeItems(
                from: items
            )

        let requestID = UUID()
        let managedItems =
            normalizedItems
            .enumerated()
            .compactMap {
                index,
                item -> ExternalPhotoIntakeItem? in

                guard let managedURL =
                    managedFileStore
                    .createManagedCopy(
                        from: item.managedURL,
                        requestID: requestID,
                        index: index,
                        preferredOriginalFileName:
                            item.originalFileName
                    )
                else {
                    return nil
                }

                return ExternalPhotoIntakeItem(
                    managedURL: managedURL,
                    originalFileName:
                        item.originalFileName,
                    sourceIdentifier:
                        item.sourceIdentifier,
                    contentTypeIdentifier:
                        item.contentTypeIdentifier,
                    livePhotoRecoveryHint:
                        item.livePhotoRecoveryHint
                )
            }

        guard !managedItems.isEmpty else {
            return nil
        }

        return persistManagedRequest(
            id: requestID,
            urls:
                managedItems.map(
                    \.managedURL
                ),
            items: managedItems,
            source: source,
            importSummary:
                importSummary,
            configurationSnapshot:
                configurationSnapshot
        )
    }

    func persistManagedRequest(
        id: UUID = UUID(),
        urls: [URL],
        items: [ExternalPhotoIntakeItem]? = nil,
        source: BatchJobLaunchSource,
        importSummary:
            ExternalPhotoImportSummary? = nil,
        configurationSnapshot:
            BatchConfigurationSnapshot
    ) -> ExternalPhotoIntakeRequest? {

        persistManagedRequestDetailed(
            id: id,
            urls: urls,
            items: items,
            source: source,
            importSummary:
                importSummary,
            configurationSnapshot:
                configurationSnapshot
        ).request
    }

    func persistManagedRequestDetailed(
        id: UUID = UUID(),
        urls: [URL],
        items: [ExternalPhotoIntakeItem]? = nil,
        source: BatchJobLaunchSource,
        importSummary:
            ExternalPhotoImportSummary? = nil,
        configurationSnapshot:
            BatchConfigurationSnapshot,
        diagnosticsSeed:
            PhotoMemoShareIntakeOperationSeed = .init()
    ) -> PhotoMemoShareIntakePersistResult {

        let normalizedURLs =
            managedFileStore
            .uniqueStandardizedURLs(
                from: urls
            )

        let normalizedItems =
            managedFileStore
            .normalizedIntakeItems(
                items,
                matching: normalizedURLs
            )

        guard !normalizedURLs.isEmpty else {
            let error =
                PhotoMemoShareIntakeDiagnosticError
                .make(
                    description:
                        "Share intake had no managed URLs to persist.",
                    code: 2001
                )

            return PhotoMemoShareIntakePersistResult(
                request: nil,
                failureContext:
                    diagnosticsSeed
                    .failureContext(
                        stage: .persist,
                        operation:
                            "persistManagedRequest.validateManagedURLs",
                        persistedRequestID:
                            id,
                        importSummary:
                            importSummary,
                        error: error
                    )
            )
        }

        let request =
            ExternalPhotoIntakeRequest(
                id: id,
                launchSource: source,
                urls: normalizedURLs,
                items: normalizedItems,
                configurationSnapshot:
                    configurationSnapshot,
                importSummary:
                    importSummary
            )

        if let saveFailure =
            requestStore.persistRequest(
                request,
                diagnosticsSeed:
                    diagnosticsSeed
            ) {
            normalizedURLs.forEach {
                cleanupService
                    .cleanupManagedSourceIfNeeded(
                        at: $0
                    )
            }

            return PhotoMemoShareIntakePersistResult(
                request: nil,
                failureContext:
                    saveFailure
            )
        }

        return PhotoMemoShareIntakePersistResult(
            request: request,
            failureContext: nil
        )
    }

    func drainRequests()
    -> [ExternalPhotoIntakeRequest] {

        drainRequestsResult()
            .requests
    }

    func drainRequestsResult(
        encode:
            ([ExternalPhotoIntakeRequest]) throws
            -> Data = {
                try JSONEncoder().encode($0)
            }
    ) -> ExternalPhotoIntakeDrainResult {

        requestStore
            .drainRequestsResult(
                encode: encode
            )
    }

    func loadRequestsResult()
    -> PhotoMemoSharedDefaultsReadResult<
        [ExternalPhotoIntakeRequest]
    > {

        requestStore
            .loadRequestsResult()
    }

    func createManagedCopy(
        from url: URL,
        requestID: UUID,
        index: Int,
        preferredOriginalFileName: String? = nil
    ) -> URL? {

        managedFileStore
            .createManagedCopy(
                from: url,
                requestID: requestID,
                index: index,
                preferredOriginalFileName:
                    preferredOriginalFileName
            )
    }

    func createManagedCopy(
        fromData data: Data,
        requestID: UUID,
        index: Int,
        preferredFileExtension: String?,
        preferredBaseName: String? = nil
    ) -> URL? {

        managedFileStore
            .createManagedCopy(
                fromData: data,
                requestID: requestID,
                index: index,
                preferredFileExtension:
                    preferredFileExtension,
                preferredBaseName:
                    preferredBaseName
            )
    }

    func createManagedCopyDetailed(
        from url: URL,
        requestID: UUID,
        index: Int,
        preferredOriginalFileName: String? = nil,
        requiresReadableImage: Bool = true,
        diagnosticsSeed:
            PhotoMemoShareIntakeOperationSeed = .init()
    ) -> PhotoMemoShareIntakeManagedCopyResult {

        managedFileStore
            .createManagedCopyDetailed(
                from: url,
                requestID: requestID,
                index: index,
                preferredOriginalFileName:
                    preferredOriginalFileName,
                requiresReadableImage:
                    requiresReadableImage,
                diagnosticsSeed:
                    diagnosticsSeed
            )
    }

    func createManagedCopyDetailed(
        fromData data: Data,
        requestID: UUID,
        index: Int,
        preferredFileExtension: String?,
        preferredBaseName: String? = nil,
        diagnosticsSeed:
            PhotoMemoShareIntakeOperationSeed = .init()
    ) -> PhotoMemoShareIntakeManagedCopyResult {

        managedFileStore
            .createManagedCopyDetailed(
                fromData: data,
                requestID: requestID,
                index: index,
                preferredFileExtension:
                    preferredFileExtension,
                preferredBaseName:
                    preferredBaseName,
                diagnosticsSeed:
                    diagnosticsSeed
            )
    }

    func cleanupManagedSourceIfNeeded(
        at url: URL
    ) {

        cleanupService
            .cleanupManagedSourceIfNeeded(
                at: url
            )
    }

    func cleanupOrphanedManagedContent(
        keepingReferencedURLs
        referencedURLs: Set<URL>
    ) {

        cleanupService
            .cleanupOrphanedManagedContent(
                keepingReferencedURLs:
                    referencedURLs
            )
    }
}
