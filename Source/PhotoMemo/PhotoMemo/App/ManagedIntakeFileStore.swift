import Foundation

final class ManagedIntakeFileStore {

    private let intakeDirectoryURL:
        URL

    init(
        intakeDirectoryURL: URL
    ) {
        self.intakeDirectoryURL =
            intakeDirectoryURL
            .standardizedFileURL
    }

    func createManagedCopy(
        from url: URL,
        requestID: UUID,
        index: Int,
        preferredOriginalFileName: String? = nil
    ) -> URL? {

        createManagedCopyDetailed(
            from: url,
            requestID: requestID,
            index: index,
            preferredOriginalFileName:
                preferredOriginalFileName
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
        preferredOriginalFileName: String? = nil,
        requiresReadableImage: Bool = true,
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

        if isManagedIntakeURL(
            normalizedURL
        ) {
            guard !requiresReadableImage
                    || PhotoMemoImageFileReadiness
                .waitForReadableImageFile(
                    at: normalizedURL
                ) else {
                return unreadableManagedCopyResult(
                    sourceURL: normalizedURL,
                    destinationURL: normalizedURL,
                    diagnosticsSeed: diagnosticsSeed,
                    operation:
                        "createManagedCopy.validateAlreadyManagedImage",
                    temporaryCopyResult:
                        "already-managed-unreadable"
                )
            }

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
            uniqueManagedDestinationURL(
                in: requestDirectoryURL,
                preferredBaseName:
                    preferredManagedBaseName(
                        preferredOriginalFileName:
                            preferredOriginalFileName,
                        fallbackURL:
                            normalizedURL
                    ),
                preferredFileExtension:
                    preferredManagedFileExtension(
                        preferredOriginalFileName:
                            preferredOriginalFileName,
                        fallbackURL:
                            normalizedURL
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
            guard !requiresReadableImage
                    || PhotoMemoImageFileReadiness
                .waitForReadableImageFile(
                    at: normalizedURL
                ) else {
                return unreadableManagedCopyResult(
                    sourceURL: normalizedURL,
                    destinationURL: destinationURL,
                    diagnosticsSeed: diagnosticsSeed,
                    operation:
                        "createManagedCopy.waitForReadableSourceImage",
                    temporaryCopyResult:
                        "source-unreadable-before-copy"
                )
            }

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

            guard !requiresReadableImage
                    || PhotoMemoImageFileReadiness
                .waitForReadableImageFile(
                    at: managedURL
                ) else {
                try? FileManager.default
                    .removeItem(
                        at: managedURL
                    )
                return unreadableManagedCopyResult(
                    sourceURL: normalizedURL,
                    destinationURL: managedURL,
                    diagnosticsSeed: diagnosticsSeed,
                    operation:
                        "createManagedCopy.validateCopiedImage",
                    temporaryCopyResult:
                        "copied-but-unreadable"
                )
            }

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
            uniqueManagedDestinationURL(
                in: requestDirectoryURL,
                preferredBaseName:
                    preferredBaseName,
                preferredFileExtension:
                    preferredFileExtension
            )

        do {
            try data.write(
                to: destinationURL,
                options: .atomic
            )

            let managedURL =
                destinationURL
                .standardizedFileURL

            guard PhotoMemoImageFileReadiness
                .waitForReadableImageFile(
                    at: managedURL
                ) else {
                try? FileManager.default
                    .removeItem(
                        at: managedURL
                    )
                return unreadableManagedCopyResult(
                    sourceURL: nil,
                    destinationURL: managedURL,
                    diagnosticsSeed: diagnosticsSeed,
                    operation:
                        "createManagedCopyFromData.validateWrittenImage",
                    temporaryCopyResult:
                        "copied-data-but-unreadable"
                )
            }

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

    func preparedManagedURLs(
        for urls: [URL],
        requestID: UUID
    ) -> [URL] {

        do {
            try PhotoMemoSharedContainer
                .ensureDirectory(
                    at: intakeDirectoryURL
                )
        } catch {
            return []
        }

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

    func uniqueIntakeItems(
        from items: [ExternalPhotoIntakeItem]
    ) -> [ExternalPhotoIntakeItem] {

        items.reduce(into: [ExternalPhotoIntakeItem]()) {
            partialResult,
            item in

            let normalizedItem =
                ExternalPhotoIntakeItem(
                    managedURL:
                        item.managedURL
                        .standardizedFileURL,
                    originalFileName:
                        item.originalFileName,
                    sourceIdentifier:
                        item.sourceIdentifier,
                    contentTypeIdentifier:
                        item.contentTypeIdentifier,
                    livePhotoRecoveryHint:
                        item.livePhotoRecoveryHint
                )

            if !partialResult.contains(
                where: {
                    $0.managedURL
                        .standardizedFileURL
                        .path
                    == normalizedItem
                        .managedURL
                        .standardizedFileURL
                        .path
                }
            ) {
                partialResult.append(
                    normalizedItem
                )
            }
        }
    }

    func normalizedIntakeItems(
        _ items: [ExternalPhotoIntakeItem]?,
        matching normalizedURLs: [URL]
    ) -> [ExternalPhotoIntakeItem]? {

        guard let items,
              !items.isEmpty else {
            return nil
        }

        let allowedPaths =
            Set(
                normalizedURLs.map(\.path)
            )

        let filteredItems =
            items.filter {
                allowedPaths.contains(
                    $0.managedURL
                    .standardizedFileURL
                    .path
                )
            }

        guard !filteredItems.isEmpty else {
            return nil
        }

        return filteredItems
    }
}

private extension ManagedIntakeFileStore {

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

    func unreadableManagedCopyResult(
        sourceURL: URL?,
        destinationURL: URL,
        diagnosticsSeed:
            PhotoMemoShareIntakeOperationSeed,
        operation: String,
        temporaryCopyResult: String
    ) -> PhotoMemoShareIntakeManagedCopyResult {

        let wrappedError =
            PhotoMemoShareIntakeDiagnosticError
            .make(
                description:
                    "Share intake copied a file, but ImageIO could not read it as a complete image.",
                code: 1007
            )

        return PhotoMemoShareIntakeManagedCopyResult(
            managedURL: nil,
            temporaryCopyResult:
                temporaryCopyResult,
            sharedContainerDestination:
                destinationURL,
            failureContext:
                diagnosticsSeed
                .failureContext(
                    stage: .copy,
                    operation:
                        operation,
                    returnedURL:
                        sourceURL,
                    temporaryCopyResult:
                        temporaryCopyResult,
                    sharedContainerDestination:
                        destinationURL,
                    error: wrappedError
                )
        )
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

        if isManagedIntakeURL(
            normalizedURL
        ) {
            return normalizedURL
        }

        let requestDirectoryURL =
            intakeDirectoryURL
            .appendingPathComponent(
                requestID.uuidString,
                isDirectory: true
            )

        do {
            try PhotoMemoSharedContainer
                .ensureDirectory(
                    at: requestDirectoryURL
                )
        } catch {
            return nil
        }

        let destinationURL =
            uniqueManagedDestinationURL(
                in: requestDirectoryURL,
                preferredBaseName:
                    normalizedURL
                    .deletingPathExtension()
                    .lastPathComponent,
                preferredFileExtension:
                    normalizedURL
                    .pathExtension
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

        guard PhotoMemoImageFileReadiness
            .waitForReadableImageFile(
                at: normalizedURL
            ) else {
            return nil
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

        let normalizedPath =
            url.standardizedFileURL.path
        let intakeRootPath =
            intakeDirectoryURL.path

        return normalizedPath == intakeRootPath
            || normalizedPath.hasPrefix(
                intakeRootPath + "/"
            )
    }

    func uniqueManagedDestinationURL(
        in directoryURL: URL,
        preferredBaseName: String?,
        preferredFileExtension: String?
    ) -> URL {

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

        var candidateURL =
            managedDestinationURL(
                in: directoryURL,
                baseName: baseName,
                fileExtension: fileExtension
            )

        var copyIndex = 1

        while FileManager.default.fileExists(
            atPath: candidateURL.path
        ) {

            candidateURL =
                managedDestinationURL(
                    in: directoryURL,
                    baseName:
                        "\(baseName) (\(copyIndex))",
                    fileExtension:
                        fileExtension
                )
            copyIndex += 1
        }

        return candidateURL
    }

    func managedDestinationURL(
        in directoryURL: URL,
        baseName: String,
        fileExtension: String?
    ) -> URL {

        let sanitizedFileExtension =
            fileExtension?
            .replacingOccurrences(
                of: ".",
                with: ""
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if let sanitizedFileExtension,
           !sanitizedFileExtension.isEmpty {
            return directoryURL
                .appendingPathComponent(
                    baseName
                )
                .appendingPathExtension(
                    sanitizedFileExtension
                )
        }

        return directoryURL
            .appendingPathComponent(
                baseName
            )
    }

    func preferredManagedBaseName(
        preferredOriginalFileName: String?,
        fallbackURL: URL
    ) -> String {

        let resolvedFileName =
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                preferredOriginalFileName
            )
            ?? PhotoFileNameResolver
            .sanitizedOriginalFileName(
                fallbackURL.lastPathComponent
            )
            ?? fallbackURL.lastPathComponent

        let baseName =
            URL(fileURLWithPath: resolvedFileName)
            .deletingPathExtension()
            .lastPathComponent
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return baseName.isEmpty
            ? "shared-image"
            : baseName
    }

    func preferredManagedFileExtension(
        preferredOriginalFileName: String?,
        fallbackURL: URL
    ) -> String? {

        if let resolvedFileName =
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                preferredOriginalFileName
            ) {

            let preferredExtension =
                URL(fileURLWithPath: resolvedFileName)
                .pathExtension
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            if !preferredExtension.isEmpty {
                return preferredExtension
            }
        }

        let fallbackExtension =
            fallbackURL.pathExtension
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return fallbackExtension.isEmpty
            ? nil
            : fallbackExtension
    }
}
