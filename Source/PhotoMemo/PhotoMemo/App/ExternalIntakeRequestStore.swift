import Foundation
import Darwin

final class ExternalIntakeRequestStore {

    static let storageKey =
        "photomemo.externalIntake.requests"

    private let defaults:
        UserDefaults

    private let lockURL: URL?

    private static let processLock = NSLock()

    init(
        defaults: UserDefaults,
        lockURL: URL? = nil
    ) {
        self.defaults = defaults
        self.lockURL = lockURL
    }

    func persistRequest(
        _ request: ExternalPhotoIntakeRequest,
        diagnosticsSeed:
            PhotoMemoShareIntakeOperationSeed
    ) -> PhotoMemoShareIntakeFailureContext? {

        let sharedContainerReadiness =
            PhotoMemoSharedContainer
            .handoffReadiness()
        _ = PhotoMemoShareDiagnostics
            .recordResult(
                stage: .appSharedContainerReadiness,
                message:
                    sharedContainerReadiness
                    .diagnosticMessage,
                requestID: request.id,
                defaults: defaults
            )

        do {
            return try withCriticalSection {
                switch loadRequestsResultUnlocked() {
                case .success(var requests):
                    requests.append(request)
                    return saveRequestsFailureContext(
                        requests,
                        diagnosticsSeed:
                            diagnosticsSeed,
                        persistedRequestID:
                            request.id
                    )
                case .noValue:
                    return saveRequestsFailureContext(
                        [request],
                        diagnosticsSeed:
                            diagnosticsSeed,
                        persistedRequestID:
                            request.id
                    )
                case .decodingFailed(let failure):
                    let error =
                        PhotoMemoShareIntakeDiagnosticError
                        .make(
                            description:
                                "Shared intake request metadata is corrupted and was not overwritten. storageKey=\(failure.storageKey) bytes=\(failure.payloadByteCount) reason=\(failure.underlyingDescription)",
                            code: 2003
                        )
                    return diagnosticsSeed.failureContext(
                        stage: .persist,
                        operation:
                            "persistRequest.loadExistingRequests",
                        persistedRequestID:
                            request.id,
                        error: error
                    )
                }
            }
        } catch {
            return diagnosticsSeed.failureContext(
                stage: .persist,
                operation:
                    "persistRequest.acquireSharedLock",
                persistedRequestID:
                    request.id,
                error: error
            )
        }
    }

    func drainRequestsResult(
        encode:
            ([ExternalPhotoIntakeRequest]) throws
            -> Data = {
                try JSONEncoder().encode($0)
            }
    ) -> ExternalPhotoIntakeDrainResult {

        do {
            return try withCriticalSection {
                let requests = loadRequests()

                guard !requests.isEmpty else {
                    return ExternalPhotoIntakeDrainResult(
                        requests: [],
                        clearPersistedRequestsResult: nil
                    )
                }

                return ExternalPhotoIntakeDrainResult(
                    requests: requests,
                    clearPersistedRequestsResult:
                        saveRequestsResult(
                            [],
                            encode: encode
                        )
                )
            }
        } catch {
            return ExternalPhotoIntakeDrainResult(
                requests: [],
                clearPersistedRequestsResult:
                    .encodingFailed(
                        PhotoMemoSharedDefaultsWriteFailure(
                            storageKey: Self.storageKey,
                            underlyingDescription:
                                String(describing: error)
                        )
                    )
            )
        }
    }

    func loadRequestsForProcessing()
    -> [ExternalPhotoIntakeRequest] {

        switch loadRequestsForProcessingResult() {
        case .success(let requests):
            return requests
        case .noValue,
             .decodingFailed:
            return []
        }
    }

    func loadRequestsForProcessingResult()
    -> PhotoMemoSharedDefaultsReadResult<
        [ExternalPhotoIntakeRequest]
    > {

        do {
            return try withCriticalSection {
                loadRequestsResultUnlocked()
            }
        } catch {
            return .decodingFailed(
                PhotoMemoSharedDefaultsReadFailure(
                    storageKey: Self.storageKey,
                    payloadByteCount: 0,
                    underlyingDescription:
                        String(describing: error)
                )
            )
        }
    }

    func acknowledgeRequests(
        _ requestIDs: Set<UUID>,
        encode:
            ([ExternalPhotoIntakeRequest]) throws
            -> Data = {
                try JSONEncoder().encode($0)
            }
    ) -> PhotoMemoSharedDefaultsWriteResult {

        do {
            return try withCriticalSection {
                let requests = loadRequests()
                let remainingRequests = requests.filter {
                    !requestIDs.contains($0.id)
                }

                guard remainingRequests.count != requests.count else {
                    return .success
                }

                return saveRequestsResult(
                    remainingRequests,
                    encode: encode
                )
            }
        } catch {
            return .encodingFailed(
                PhotoMemoSharedDefaultsWriteFailure(
                    storageKey: Self.storageKey,
                    underlyingDescription:
                        String(describing: error)
                )
            )
        }
    }

    func loadRequestsResult()
    -> PhotoMemoSharedDefaultsReadResult<
        [ExternalPhotoIntakeRequest]
    > {

        do {
            return try withCriticalSection {
                loadRequestsResultUnlocked()
            }
        } catch {
            return .decodingFailed(
                PhotoMemoSharedDefaultsReadFailure(
                    storageKey: Self.storageKey,
                    payloadByteCount: 0,
                    underlyingDescription:
                        String(describing: error)
                )
            )
        }
    }
}

private extension ExternalIntakeRequestStore {

    func withCriticalSection<Result>(
        _ operation: () throws -> Result
    ) throws -> Result {

        Self.processLock.lock()
        defer {
            Self.processLock.unlock()
        }

        guard let lockURL else {
            return try operation()
        }

        do {
            try FileManager.default.createDirectory(
                at: lockURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        } catch {
            throw ExternalIntakeRequestStoreLockError
                .directoryCreationFailed(
                    url: lockURL.deletingLastPathComponent(),
                    underlying: error
                )
        }

        let descriptor = Darwin.open(
            lockURL.path,
            O_CREAT | O_RDWR,
            S_IRUSR | S_IWUSR
        )

        guard descriptor >= 0 else {
            throw ExternalIntakeRequestStoreLockError
                .openFailed(
                    url: lockURL,
                    errno: errno
                )
        }

        defer {
            _ = Darwin.close(descriptor)
        }

        var lock = Darwin.flock()
        lock.l_type = Int16(F_WRLCK)
        lock.l_whence = Int16(SEEK_SET)
        guard Darwin.fcntl(
            descriptor,
            F_SETLKW,
            &lock
        ) == 0 else {
            throw ExternalIntakeRequestStoreLockError
                .acquireFailed(
                    url: lockURL,
                    errno: errno
                )
        }
        defer {
            var unlock = Darwin.flock()
            unlock.l_type = Int16(F_UNLCK)
            unlock.l_whence = Int16(SEEK_SET)
            _ = Darwin.fcntl(
                descriptor,
                F_SETLK,
                &unlock
            )
        }

        return try operation()
    }

    func loadRequests()
    -> [ExternalPhotoIntakeRequest] {

        switch loadRequestsResultUnlocked() {
        case .success(let requests):
            return requests
        case .noValue,
             .decodingFailed:
            return []
        }
    }

    func loadRequestsResultUnlocked()
    -> PhotoMemoSharedDefaultsReadResult<
        [ExternalPhotoIntakeRequest]
    > {

        guard
            let data = defaults.data(
                forKey: Self.storageKey
            )
        else {
            return .noValue
        }

        do {
            let requests =
                try JSONDecoder().decode(
                    [ExternalPhotoIntakeRequest].self,
                    from: data
                )
            return .success(requests)
        } catch {
            return .decodingFailed(
                PhotoMemoSharedDefaultsReadFailure(
                    storageKey:
                        Self.storageKey,
                    payloadByteCount:
                        data.count,
                    underlyingDescription:
                        String(
                            describing: error
                        ),
                    rawPayload: data
                )
            )
        }
    }

    func saveRequestsResult(
        _ requests: [ExternalPhotoIntakeRequest],
        encode:
            ([ExternalPhotoIntakeRequest]) throws
            -> Data
    ) -> PhotoMemoSharedDefaultsWriteResult {

        let data: Data

        do {
            data = try encode(
                requests
            )
        } catch {
            return .encodingFailed(
                PhotoMemoSharedDefaultsWriteFailure(
                    storageKey:
                        Self.storageKey,
                    underlyingDescription:
                        String(
                            describing: error
                        )
                )
            )
        }

        return saveEncodedDataResult(data)
    }

    func saveRequestsFailureContext(
        _ requests: [ExternalPhotoIntakeRequest],
        diagnosticsSeed:
            PhotoMemoShareIntakeOperationSeed,
        persistedRequestID: UUID
    ) -> PhotoMemoShareIntakeFailureContext? {

        do {
            let data = try JSONEncoder().encode(requests)
            switch saveEncodedDataResult(data) {
            case .success:
                return nil
            case .encodingFailed(let failure):
                let wrappedError =
                    PhotoMemoShareIntakeDiagnosticError
                    .make(
                        description:
                            "Share intake failed to persist shared request metadata.",
                        code: 2002,
                        underlyingError:
                            NSError(
                                domain: PhotoMemoShareIntakeDiagnosticError.domain,
                                code: 2002,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        failure.underlyingDescription
                                ]
                            )
                    )
                return diagnosticsSeed.failureContext(
                    stage: .serialization,
                    operation:
                        "persistManagedRequest.saveRequests",
                    persistedRequestID:
                        persistedRequestID,
                    error: wrappedError
                )
            }
        } catch {
            let wrappedError =
                PhotoMemoShareIntakeDiagnosticError
                .make(
                    description:
                        "Share intake failed to encode shared request metadata.",
                    code: 2002,
                    underlyingError: error
                )

            return diagnosticsSeed.failureContext(
                stage: .serialization,
                operation:
                    "persistManagedRequest.encodeRequests",
                persistedRequestID:
                    persistedRequestID,
                error: wrappedError
            )
        }
    }

    func saveEncodedDataResult(
        _ data: Data
    ) -> PhotoMemoSharedDefaultsWriteResult {

        defaults.set(
            data,
            forKey: Self.storageKey
        )

        guard defaults.synchronize() else {
            return .encodingFailed(
                PhotoMemoSharedDefaultsWriteFailure(
                    storageKey: Self.storageKey,
                    underlyingDescription:
                        "UserDefaults synchronize returned false."
                )
            )
        }

        guard defaults.data(forKey: Self.storageKey) == data else {
            return .encodingFailed(
                PhotoMemoSharedDefaultsWriteFailure(
                    storageKey: Self.storageKey,
                    underlyingDescription:
                        "UserDefaults read-back verification failed."
                )
            )
        }

        return .success
    }
}

private enum ExternalIntakeRequestStoreLockError:
    LocalizedError {

    case directoryCreationFailed(url: URL, underlying: Error)
    case openFailed(url: URL, errno: Int32)
    case acquireFailed(url: URL, errno: Int32)

    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed(let url, let underlying):
            return "Unable to create shared intake lock directory \(url.path): \(underlying)"
        case .openFailed(let url, let errno):
            return "Unable to open shared intake lock \(url.path), errno=\(errno)."
        case .acquireFailed(let url, let errno):
            return "Unable to acquire shared intake lock \(url.path), errno=\(errno)."
        }
    }
}
