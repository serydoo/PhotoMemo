import Foundation

final class ExternalIntakeRequestStore {

    static let storageKey =
        "photomemo.externalIntake.requests"

    private let defaults:
        UserDefaults

    init(
        defaults: UserDefaults
    ) {
        self.defaults = defaults
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

        var requests = loadRequests()
        requests.append(request)

        return saveRequestsFailureContext(
            requests,
            diagnosticsSeed:
                diagnosticsSeed,
            persistedRequestID:
                request.id
        )
    }

    func drainRequestsResult(
        encode:
            ([ExternalPhotoIntakeRequest]) throws
            -> Data = {
                try JSONEncoder().encode($0)
            }
    ) -> ExternalPhotoIntakeDrainResult {

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

    func loadRequestsResult()
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
                        )
                )
            )
        }
    }
}

private extension ExternalIntakeRequestStore {

    func loadRequests()
    -> [ExternalPhotoIntakeRequest] {

        switch loadRequestsResult() {
        case .success(let requests):
            return requests
        case .noValue,
             .decodingFailed:
            return []
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

        defaults.set(
            data,
            forKey: Self.storageKey
        )
        defaults.synchronize()
        return .success
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
                forKey: Self.storageKey
            )
            defaults.synchronize()

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
}
