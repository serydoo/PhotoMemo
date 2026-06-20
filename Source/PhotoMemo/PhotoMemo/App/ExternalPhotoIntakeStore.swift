import Foundation

final class ExternalPhotoIntakeStore {

    static let shared =
        ExternalPhotoIntakeStore()

    private let storageKey =
        "photomemo.externalIntake.requests"

    private let defaults: UserDefaults

    private let intakeDirectoryURL: URL

    init(
        defaults: UserDefaults =
            PhotoMemoSharedContainer
            .sharedUserDefaults,
        intakeDirectoryURL: URL =
            PhotoMemoSharedContainer
            .externalIntakeDirectoryURL
    ) {
        self.defaults = defaults
        self.intakeDirectoryURL =
            intakeDirectoryURL
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
            uniqueStandardizedURLs(
                from: urls
            )

        let requestID = UUID()
        let managedURLs =
            preparedManagedURLs(
                for: normalizedInputURLs,
                requestID: requestID
            )

        guard !managedURLs.isEmpty else {
            return nil
        }

        return persistManagedRequest(
            id: requestID,
            urls: managedURLs,
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
        source: BatchJobLaunchSource,
        importSummary:
            ExternalPhotoImportSummary? = nil,
        configurationSnapshot:
            BatchConfigurationSnapshot
    ) -> ExternalPhotoIntakeRequest? {

        persistManagedRequestDetailed(
            id: id,
            urls: urls,
            source: source,
            importSummary:
                importSummary,
            configurationSnapshot:
                configurationSnapshot
        ).request
    }

    func drainRequests() -> [ExternalPhotoIntakeRequest] {

        let requests = loadRequests()

        guard !requests.isEmpty else {
            return []
        }

        _ = saveRequests([])
        return requests
    }

    func cleanupManagedSourceIfNeeded(
        at url: URL
    ) {

        let normalizedURL =
            url.standardizedFileURL

        guard isManagedIntakeURL(
            normalizedURL
        ) else {
            return
        }

        do {
            if FileManager.default.fileExists(
                atPath: normalizedURL.path
            ) {
                try FileManager.default.removeItem(
                    at: normalizedURL
                )
            }

            cleanupEmptyParentDirectories(
                startingAt:
                    normalizedURL
                    .deletingLastPathComponent()
            )
        } catch {
            return
        }
    }

    func createManagedCopy(
        from url: URL,
        requestID: UUID,
        index: Int
    ) -> URL? {

        createManagedCopyDetailed(
            from: url,
            requestID: requestID,
            index: index
        ).managedURL
    }

    func createManagedCopy(
        fromData data: Data,
        requestID: UUID,
        index: Int,
        preferredFileExtension: String?,
        preferredBaseName: String? = nil
    ) -> URL? {

        createManagedCopyDetailed(
            fromData: data,
            requestID: requestID,
            index: index,
            preferredFileExtension:
                preferredFileExtension,
            preferredBaseName:
                preferredBaseName
        ).managedURL
    }

    func createManagedCopyDetailed(
        from url: URL,
        requestID: UUID,
        index: Int,
        diagnosticsSeed:
            PhotoMemoShareIntakeOperationSeed = .init()
    ) -> PhotoMemoShareIntakeManagedCopyResult {

        let normalizedURL =
            url.standardizedFileURL

        guard normalizedURL.isFileURL else {
            let error =
                PhotoMemoShareIntakeDiagnosticError
                .make(
                    description:
                        "Share intake received a non-file URL.",
                    code: 1001
                )

            return PhotoMemoShareIntakeManagedCopyResult(
                managedURL: nil,
                temporaryCopyResult:
                    "non-file-url",
                sharedContainerDestination: nil,
                failureContext:
                    diagnosticsSeed
                    .failureContext(
                        stage: .copy,
                        operation:
                            "createManagedCopy.validateSourceURL",
                        returnedURL:
                            normalizedURL,
                        temporaryCopyResult:
                            "non-file-url",
                        error: error
                    )
            )
        }

        if normalizedURL.path.hasPrefix(
            intakeDirectoryURL.path
        ) {
            return PhotoMemoShareIntakeManagedCopyResult(
                managedURL:
                    normalizedURL,
                temporaryCopyResult:
                    "already-managed",
                sharedContainerDestination:
                    normalizedURL,
                failureContext: nil
            )
        }

        if let ensureRootFailure =
            ensureDirectoryFailureContext(
                at: intakeDirectoryURL,
                stage: .copy,
                operation:
                    "createManagedCopy.ensureIntakeDirectory",
                diagnosticsSeed:
                    diagnosticsSeed,
                temporaryCopyResult:
                    "prepare-intake-directory"
            ) {
            return PhotoMemoShareIntakeManagedCopyResult(
                managedURL: nil,
                temporaryCopyResult:
                    "prepare-intake-directory-failed",
                sharedContainerDestination:
                    intakeDirectoryURL,
                failureContext:
                    ensureRootFailure
            )
        }

        let requestDirectoryURL =
            intakeDirectoryURL
            .appendingPathComponent(
                requestID.uuidString,
                isDirectory: true
            )

        if let ensureRequestFailure =
            ensureDirectoryFailureContext(
                at: requestDirectoryURL,
                stage: .copy,
                operation:
                    "createManagedCopy.ensureRequestDirectory",
                diagnosticsSeed:
                    diagnosticsSeed,
                temporaryCopyResult:
                    "prepare-request-directory"
            ) {
            return PhotoMemoShareIntakeManagedCopyResult(
                managedURL: nil,
                temporaryCopyResult:
                    "prepare-request-directory-failed",
                sharedContainerDestination:
                    requestDirectoryURL,
                failureContext:
                    ensureRequestFailure
            )
        }

        let destinationURL =
            requestDirectoryURL
            .appendingPathComponent(
                managedFileName(
                    for: normalizedURL,
                    index: index
                )
            )

        let accessGranted =
            normalizedURL
            .startAccessingSecurityScopedResource()

        defer {
            if accessGranted {
                normalizedURL
                    .stopAccessingSecurityScopedResource()
            }
        }

        do {
            if FileManager.default.fileExists(
                atPath:
                    destinationURL.path
            ) {
                try FileManager.default
                    .removeItem(
                        at: destinationURL
                    )
            }

            try FileManager.default.copyItem(
                at: normalizedURL,
                to: destinationURL
            )

            let managedURL =
                destinationURL
                .standardizedFileURL

            return PhotoMemoShareIntakeManagedCopyResult(
                managedURL:
                    managedURL,
                temporaryCopyResult:
                    "copied",
                sharedContainerDestination:
                    managedURL,
                failureContext: nil
            )
        } catch {
            let wrappedError =
                PhotoMemoShareIntakeDiagnosticError
                .make(
                    description:
                        "Share intake failed to copy a provider URL into the shared container.",
                    code: 1002,
                    underlyingError: error
                )

            return PhotoMemoShareIntakeManagedCopyResult(
                managedURL: nil,
                temporaryCopyResult:
                    "copy-failed",
                sharedContainerDestination:
                    destinationURL,
                failureContext:
                    diagnosticsSeed
                    .failureContext(
                        stage: .copy,
                        operation:
                            "createManagedCopy.copyItem",
                        returnedURL:
                            normalizedURL,
                        temporaryCopyResult:
                            "copy-failed",
                        sharedContainerDestination:
                            destinationURL,
                        error: wrappedError
                    )
            )
        }
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

        if let ensureRootFailure =
            ensureDirectoryFailureContext(
                at: intakeDirectoryURL,
                stage: .copy,
                operation:
                    "createManagedCopyFromData.ensureIntakeDirectory",
                diagnosticsSeed:
                    diagnosticsSeed,
                temporaryCopyResult:
                    "prepare-intake-directory"
            ) {
            return PhotoMemoShareIntakeManagedCopyResult(
                managedURL: nil,
                temporaryCopyResult:
                    "prepare-intake-directory-failed",
                sharedContainerDestination:
                    intakeDirectoryURL,
                failureContext:
                    ensureRootFailure
            )
        }

        let requestDirectoryURL =
            intakeDirectoryURL
            .appendingPathComponent(
                requestID.uuidString,
                isDirectory: true
            )

        if let ensureRequestFailure =
            ensureDirectoryFailureContext(
                at: requestDirectoryURL,
                stage: .copy,
                operation:
                    "createManagedCopyFromData.ensureRequestDirectory",
                diagnosticsSeed:
                    diagnosticsSeed,
                temporaryCopyResult:
                    "prepare-request-directory"
            ) {
            return PhotoMemoShareIntakeManagedCopyResult(
                managedURL: nil,
                temporaryCopyResult:
                    "prepare-request-directory-failed",
                sharedContainerDestination:
                    requestDirectoryURL,
                failureContext:
                    ensureRequestFailure
            )
        }

        let destinationURL =
            requestDirectoryURL
            .appendingPathComponent(
                managedFileName(
                    preferredBaseName:
                        preferredBaseName,
                    preferredFileExtension:
                        preferredFileExtension,
                    index: index
                )
            )

        do {
            try data.write(
                to: destinationURL,
                options: .atomic
            )

            let managedURL =
                destinationURL
                .standardizedFileURL

            return PhotoMemoShareIntakeManagedCopyResult(
                managedURL:
                    managedURL,
                temporaryCopyResult:
                    "copied-data",
                sharedContainerDestination:
                    managedURL,
                failureContext: nil
            )
        } catch {
            let wrappedError =
                PhotoMemoShareIntakeDiagnosticError
                .make(
                    description:
                        "Share intake failed to write fallback data into the shared container.",
                    code: 1003,
                    underlyingError: error
                )

            return PhotoMemoShareIntakeManagedCopyResult(
                managedURL: nil,
                temporaryCopyResult:
                    "write-data-failed",
                sharedContainerDestination:
                    destinationURL,
                failureContext:
                    diagnosticsSeed
                    .failureContext(
                        stage: .copy,
                        operation:
                            "createManagedCopyFromData.writeData",
                        temporaryCopyResult:
                            "write-data-failed",
                        sharedContainerDestination:
                            destinationURL,
                        error: wrappedError
                    )
            )
        }
    }

    func persistManagedRequestDetailed(
        id: UUID = UUID(),
        urls: [URL],
        source: BatchJobLaunchSource,
        importSummary:
            ExternalPhotoImportSummary? = nil,
        configurationSnapshot:
            BatchConfigurationSnapshot,
        diagnosticsSeed:
            PhotoMemoShareIntakeOperationSeed = .init()
    ) -> PhotoMemoShareIntakePersistResult {

        let normalizedURLs =
            uniqueStandardizedURLs(
                from: urls
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
                configurationSnapshot:
                    configurationSnapshot,
                importSummary:
                    importSummary
            )

        var requests = loadRequests()
        requests.append(request)

        if let saveFailure =
            saveRequestsFailureContext(
                requests,
                diagnosticsSeed:
                    diagnosticsSeed,
                persistedRequestID:
                    id
            ) {
            normalizedURLs.forEach {
                cleanupManagedSourceIfNeeded(
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

    func cleanupOrphanedManagedContent(
        keepingReferencedURLs
        referencedURLs: Set<URL>
    ) {

        let normalizedReferencedURLs =
            Set(
                referencedURLs.map {
                    $0.standardizedFileURL
                }
            )

        guard
            let requestDirectories =
                try? FileManager.default
                .contentsOfDirectory(
                    at: intakeDirectoryURL,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                )
        else {
            return
        }

        for requestDirectoryURL
            in requestDirectories {

            guard
                let childURLs =
                    try? FileManager.default
                    .contentsOfDirectory(
                        at: requestDirectoryURL,
                        includingPropertiesForKeys: nil,
                        options: [.skipsHiddenFiles]
                    )
            else {
                continue
            }

            let retainedChildren =
                childURLs.filter { childURL in
                    normalizedReferencedURLs
                        .contains(
                            childURL
                            .standardizedFileURL
                        )
                }

            if retainedChildren.isEmpty {
                try? FileManager.default
                    .removeItem(
                        at: requestDirectoryURL
                    )
                continue
            }

            for childURL in childURLs
            where !normalizedReferencedURLs
                .contains(
                    childURL.standardizedFileURL
                ) {

                try? FileManager.default
                    .removeItem(
                        at: childURL
                    )
            }

            cleanupEmptyParentDirectories(
                startingAt:
                    requestDirectoryURL
            )
        }
    }
}

private extension ExternalPhotoIntakeStore {

    func loadRequests() -> [ExternalPhotoIntakeRequest] {

        guard
            let data = defaults.data(
                forKey: storageKey
            ),
            let requests =
                try? JSONDecoder().decode(
                    [ExternalPhotoIntakeRequest].self,
                    from: data
                )
        else {
            return []
        }

        return requests
    }

    @discardableResult
    func saveRequests(
        _ requests: [ExternalPhotoIntakeRequest]
    ) -> Bool {

        guard
            let data =
                try? JSONEncoder().encode(
                    requests
                )
        else {
            return false
        }

        defaults.set(
            data,
            forKey: storageKey
        )
        return true
    }

    func saveRequestsFailureContext(
        _ requests: [ExternalPhotoIntakeRequest],
        diagnosticsSeed:
            PhotoMemoShareIntakeOperationSeed,
        persistedRequestID: UUID
    ) -> PhotoMemoShareIntakeFailureContext? {

        do {
            let data =
                try JSONEncoder().encode(
                    requests
                )

            defaults.set(
                data,
                forKey: storageKey
            )

            return nil
        } catch {
            let wrappedError =
                PhotoMemoShareIntakeDiagnosticError
                .make(
                    description:
                        "Share intake failed to encode shared request metadata.",
                    code: 2002,
                    underlyingError: error
                )

            return diagnosticsSeed
                .failureContext(
                    stage: .serialization,
                    operation:
                        "persistManagedRequest.encodeRequests",
                    persistedRequestID:
                        persistedRequestID,
                    error: wrappedError
                )
        }
    }

    func ensureDirectoryFailureContext(
        at directoryURL: URL,
        stage:
            PhotoMemoShareIntakeFailureStage,
        operation: String,
        diagnosticsSeed:
            PhotoMemoShareIntakeOperationSeed,
        temporaryCopyResult: String
    ) -> PhotoMemoShareIntakeFailureContext? {

        do {
            try FileManager.default
                .createDirectory(
                    at: directoryURL,
                    withIntermediateDirectories:
                        true,
                    attributes: nil
                )
            return nil
        } catch {
            let wrappedError =
                PhotoMemoShareIntakeDiagnosticError
                .make(
                    description:
                        "Share intake failed to prepare the shared container directory.",
                    code: 1004,
                    underlyingError: error
                )

            return diagnosticsSeed
                .failureContext(
                    stage: stage,
                    operation:
                        operation,
                    temporaryCopyResult:
                        temporaryCopyResult,
                    sharedContainerDestination:
                        directoryURL,
                    error: wrappedError
                )
        }
    }

    func preparedManagedURLs(
        for urls: [URL],
        requestID: UUID
    ) -> [URL] {

        PhotoMemoSharedContainer
            .ensureDirectory(
                at: intakeDirectoryURL
            )

        return urls.enumerated().compactMap {
            index,
            url in

            copyURLIntoManagedInbox(
                url,
                requestID: requestID,
                index: index
            )
        }
    }

    func uniqueStandardizedURLs(
        from urls: [URL]
    ) -> [URL] {

        urls.reduce(into: [URL]()) {
            partialResult,
            url in

            let normalizedURL =
                url.standardizedFileURL

            if !partialResult.contains(
                normalizedURL
            ) {
                partialResult.append(
                    normalizedURL
                )
            }
        }
    }

    func copyURLIntoManagedInbox(
        _ url: URL,
        requestID: UUID,
        index: Int
    ) -> URL? {

        guard url.isFileURL else {
            return nil
        }

        let normalizedURL =
            url.standardizedFileURL

        if normalizedURL.path.hasPrefix(
            intakeDirectoryURL.path
        ) {
            return normalizedURL
        }

        let requestDirectoryURL =
            intakeDirectoryURL
            .appendingPathComponent(
                requestID.uuidString,
                isDirectory: true
            )

        guard
            PhotoMemoSharedContainer
            .ensureDirectory(
                at: requestDirectoryURL
            )
        else {
            return nil
        }

        let destinationURL =
            requestDirectoryURL
            .appendingPathComponent(
                managedFileName(
                    for: normalizedURL,
                    index: index
                )
            )

        let accessGranted =
            normalizedURL
            .startAccessingSecurityScopedResource()

        defer {
            if accessGranted {
                normalizedURL
                    .stopAccessingSecurityScopedResource()
            }
        }

        do {
            if FileManager.default.fileExists(
                atPath: destinationURL.path
            ) {
                try FileManager.default.removeItem(
                    at: destinationURL
                )
            }

            try FileManager.default.copyItem(
                at: normalizedURL,
                to: destinationURL
            )

            return destinationURL
                .standardizedFileURL
        } catch {
            return nil
        }
    }

    func isManagedIntakeURL(
        _ url: URL
    ) -> Bool {

        url.path.hasPrefix(
            intakeDirectoryURL.path
        )
    }

    func cleanupEmptyParentDirectories(
        startingAt directoryURL: URL
    ) {

        var currentDirectoryURL =
            directoryURL
                .standardizedFileURL
        let intakeRootPath =
            intakeDirectoryURL
                .standardizedFileURL
                .path

        while currentDirectoryURL.path != intakeRootPath,
              currentDirectoryURL.path.hasPrefix(
                intakeRootPath
              ) {

            guard
                let children =
                    try? FileManager.default
                    .contentsOfDirectory(
                        at: currentDirectoryURL,
                        includingPropertiesForKeys: nil
                    ),
                children.isEmpty
            else {
                return
            }

            try? FileManager.default.removeItem(
                at: currentDirectoryURL
            )

            currentDirectoryURL =
                currentDirectoryURL
                .deletingLastPathComponent()
        }
    }

    func managedFileName(
        for url: URL,
        index: Int
    ) -> String {

        let baseName =
            url.deletingPathExtension()
            .lastPathComponent
            .replacingOccurrences(
                of: "/",
                with: "-"
            )
            .replacingOccurrences(
                of: ":",
                with: "-"
            )

        let fileExtension =
            url.pathExtension

        if fileExtension.isEmpty {
            return "\(index)-\(baseName)"
        }

        return "\(index)-\(baseName).\(fileExtension)"
    }

    func managedFileName(
        preferredBaseName: String?,
        preferredFileExtension: String?,
        index: Int
    ) -> String {

        let sanitizedBaseName =
            preferredBaseName?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .replacingOccurrences(
                of: "/",
                with: "-"
            )
            .replacingOccurrences(
                of: ":",
                with: "-"
            )

        let baseName =
            sanitizedBaseName?.isEmpty == false
            ? sanitizedBaseName ?? "shared-image"
            : "shared-image"

        let fileExtension =
            preferredFileExtension?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .replacingOccurrences(
                of: ".",
                with: ""
            )
            .lowercased()
            ?? ""

        if fileExtension.isEmpty {
            return "\(index)-\(baseName)"
        }

        return "\(index)-\(baseName).\(fileExtension)"
    }
}
