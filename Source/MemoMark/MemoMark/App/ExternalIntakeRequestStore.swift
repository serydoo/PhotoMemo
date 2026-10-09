import Foundation
import Darwin

final class ExternalIntakeRequestStore {

    static let storageKey =
        "photomemo.externalIntake.requests"

    private let defaults:
        UserDefaults

    private let lockURL: URL?

    private let synchronizeDefaults: () -> Bool

    private static let processLock = NSLock()

    init(
        defaults: UserDefaults,
        lockURL: URL? = nil,
        synchronizeDefaults: (() -> Bool)? = nil
    ) {
        self.defaults = defaults
        self.lockURL = lockURL
        self.synchronizeDefaults =
            synchronizeDefaults
            ?? defaults.synchronize
    }

    static let continuationKey = "photomemo.externalIntake.continuation.v1"

    private struct Continuation: Codable {
        let identifier: String
        let sessionID: UUID
        var expiresAt: Date
        var acceptedRequestIDs: [UUID]
        var pendingRequestIDs: [UUID]
    }

    /// Routing is serialized with intake persistence. A joined Share never
    /// creates a second system task that would merely wait for the same owner.
    func reserveContinuation(requestID: UUID, identifier: String, now: Date = Date()) throws -> String {
        try withCriticalSection {
            if var active = try readContinuation(), active.expiresAt > now {
                guard active.acceptedRequestIDs.count < 1024 else { throw CocoaError(.fileWriteOutOfSpace) }
                if !active.acceptedRequestIDs.contains(requestID) {
                    active.acceptedRequestIDs.append(requestID)
                    active.pendingRequestIDs.append(requestID)
                }
                try associateContinuation(requestID: requestID, sessionID: active.sessionID)
                try writeContinuation(active)
                return active.identifier
            }
            let next = Continuation(identifier: identifier, sessionID: requestID, expiresAt: now.addingTimeInterval(180),
                acceptedRequestIDs: [requestID], pendingRequestIDs: [requestID])
            try associateContinuation(requestID: requestID, sessionID: next.sessionID)
            try writeContinuation(next)
            return identifier
        }
    }

    /// Empty observation and close happen under the same lock as append.
    /// Requests appended after close must reserve a new system task.
    func nextContinuation(identifier: String, now: Date = Date()) throws -> UUID? {
        try withCriticalSection {
            guard var active = try readContinuation() else { return nil }
            guard active.identifier == identifier else { throw CancellationError() }
            try reconcileContinuation(&active)
            guard !active.pendingRequestIDs.isEmpty else {
                try writeContinuation(nil)
                return nil
            }
            let requestID = active.pendingRequestIDs.removeFirst()
            active.expiresAt = now.addingTimeInterval(180)
            try writeContinuation(active)
            return requestID
        }
    }

    @discardableResult
    func renewContinuation(identifier: String, now: Date = Date()) throws -> Bool {
        try withCriticalSection {
            guard var active = try readContinuation(), active.identifier == identifier else { return false }
            active.expiresAt = now.addingTimeInterval(180)
            try writeContinuation(active)
            return true
        }
    }

    func finishContinuation(identifier: String, suspendRequestsAt: Date? = nil) throws -> [UUID] {
        try withCriticalSection {
            guard var active = try readContinuation(), active.identifier == identifier else { return [] }
            try reconcileContinuation(&active)
            if let suspendRequestsAt {
                switch loadRequestsResultUnlocked() {
                case .success(var requests):
                    let accepted = Set(active.acceptedRequestIDs)
                    for index in requests.indices where accepted.contains(requests[index].id) {
                        requests[index].executionSuspendedAt = requests[index].executionSuspendedAt ?? suspendRequestsAt
                    }
                    guard case .success = saveRequestsResult(requests, encode: { try JSONEncoder().encode($0) }) else {
                        throw CocoaError(.fileWriteUnknown)
                    }
                case .noValue: break
                case .decodingFailed: throw CocoaError(.fileReadCorruptFile)
                }
            }
            try writeContinuation(nil)
            return active.acceptedRequestIDs
        }
    }

    func continuationRequestIDs(identifier: String) throws -> Set<UUID> {
        try withCriticalSection {
            guard var active = try readContinuation(), active.identifier == identifier else { return [] }
            try reconcileContinuation(&active)
            return Set(active.acceptedRequestIDs)
        }
    }

    private func associateContinuation(requestID: UUID, sessionID: UUID) throws {
        switch loadRequestsResultUnlocked() {
        case .success(var requests):
            guard let index = requests.firstIndex(where: { $0.id == requestID }) else { return }
            requests[index].continuedExecutionSessionID = sessionID
            guard case .success = saveRequestsResult(requests, encode: { try JSONEncoder().encode($0) }) else {
                throw CocoaError(.fileWriteUnknown)
            }
        case .noValue: break
        case .decodingFailed: throw CocoaError(.fileReadCorruptFile)
        }
    }

    /// Recover a crash between durable request association and route write.
    private func reconcileContinuation(_ active: inout Continuation) throws {
        switch loadRequestsResultUnlocked() {
        case .success(let requests):
            for request in requests where request.continuedExecutionSessionID == active.sessionID
                && !active.acceptedRequestIDs.contains(request.id) {
                active.acceptedRequestIDs.append(request.id)
                active.pendingRequestIDs.append(request.id)
            }
        case .noValue: break
        case .decodingFailed: throw CocoaError(.fileReadCorruptFile)
        }
    }

    private func readContinuation() throws -> Continuation? {
        guard let data = defaults.data(forKey: Self.continuationKey) else { return nil }
        return try JSONDecoder().decode(Continuation.self, from: data)
    }

    private func writeContinuation(_ state: Continuation?) throws {
        let previous = defaults.data(forKey: Self.continuationKey)
        let encoded = try state.map { try JSONEncoder().encode($0) }
        if let encoded { defaults.set(encoded, forKey: Self.continuationKey) }
        else { defaults.removeObject(forKey: Self.continuationKey) }
        _ = synchronizeDefaults()
        guard defaults.data(forKey: Self.continuationKey) == encoded else {
            if let previous { defaults.set(previous, forKey: Self.continuationKey) }
            else { defaults.removeObject(forKey: Self.continuationKey) }
            _ = synchronizeDefaults()
            throw CocoaError(.fileWriteUnknown)
        }
    }

    func persistRequest(
        _ request: ExternalPhotoIntakeRequest,
        diagnosticsSeed:
            MemoMarkShareIntakeOperationSeed
    ) -> MemoMarkShareIntakeFailureContext? {

        let sharedContainerReadiness =
            MemoMarkSharedContainer
            .handoffReadiness()
        _ = MemoMarkShareDiagnostics
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
                        MemoMarkShareIntakeDiagnosticError
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
                        MemoMarkSharedDefaultsWriteFailure(
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
    -> MemoMarkSharedDefaultsReadResult<
        [ExternalPhotoIntakeRequest]
    > {

        do {
            return try withCriticalSection {
                loadRequestsResultUnlocked()
            }
        } catch {
            return .decodingFailed(
                MemoMarkSharedDefaultsReadFailure(
                    storageKey: Self.storageKey,
                    payloadByteCount: 0,
                    underlyingDescription:
                        String(describing: error)
                )
            )
        }
    }

    /// Preserve staged sources and the frozen intent when the system interrupts
    /// a request before it has a durable queue job.
    func suspendRequest(_ requestID: UUID, at date: Date = Date()) -> MemoMarkSharedDefaultsWriteResult {
        do {
            return try withCriticalSection {
                var requests: [ExternalPhotoIntakeRequest]
                switch loadRequestsResultUnlocked() {
                case .success(let stored): requests = stored
                case .noValue: return .success
                case .decodingFailed: throw CocoaError(.fileReadCorruptFile)
                }
                guard let index = requests.firstIndex(where: { $0.id == requestID }),
                      requests[index].executionSuspendedAt == nil else { return .success }
                requests[index].executionSuspendedAt = date
                return saveRequestsResult(requests, encode: { try JSONEncoder().encode($0) })
            }
        } catch {
            return .encodingFailed(.init(storageKey: Self.storageKey, underlyingDescription: String(describing: error)))
        }
    }

    func acknowledgeRequests(
        _ requestIDs: Set<UUID>,
        encode:
            ([ExternalPhotoIntakeRequest]) throws
            -> Data = {
                try JSONEncoder().encode($0)
            }
    ) -> MemoMarkSharedDefaultsWriteResult {

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
                MemoMarkSharedDefaultsWriteFailure(
                    storageKey: Self.storageKey,
                    underlyingDescription:
                        String(describing: error)
                )
            )
        }
    }

    func loadRequestsResult()
    -> MemoMarkSharedDefaultsReadResult<
        [ExternalPhotoIntakeRequest]
    > {

        do {
            return try withCriticalSection {
                loadRequestsResultUnlocked()
            }
        } catch {
            return .decodingFailed(
                MemoMarkSharedDefaultsReadFailure(
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
    -> MemoMarkSharedDefaultsReadResult<
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
                MemoMarkSharedDefaultsReadFailure(
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
    ) -> MemoMarkSharedDefaultsWriteResult {

        let data: Data

        do {
            data = try encode(
                requests
            )
        } catch {
            return .encodingFailed(
                MemoMarkSharedDefaultsWriteFailure(
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
            MemoMarkShareIntakeOperationSeed,
        persistedRequestID: UUID
    ) -> MemoMarkShareIntakeFailureContext? {

        do {
            let data = try JSONEncoder().encode(requests)
            switch saveEncodedDataResult(data) {
            case .success:
                return nil
            case .encodingFailed(let failure):
                let wrappedError =
                    MemoMarkShareIntakeDiagnosticError
                    .make(
                        description:
                            "Share intake failed to persist shared request metadata.",
                        code: 2002,
                        underlyingError:
                            NSError(
                                domain: MemoMarkShareIntakeDiagnosticError.domain,
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
                MemoMarkShareIntakeDiagnosticError
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
    ) -> MemoMarkSharedDefaultsWriteResult {

        defaults.set(
            data,
            forKey: Self.storageKey
        )

        _ = synchronizeDefaults()

        guard defaults.data(forKey: Self.storageKey) == data else {
            return .encodingFailed(
                MemoMarkSharedDefaultsWriteFailure(
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
