import Foundation

nonisolated enum MemoMarkErrorCode:
    String,
    Codable,
    Hashable,
    Sendable {

    case invalidInput
    case invalidState
    case configurationUnavailable
    case queueOperationFailed
    case persistenceReadFailed
    case persistenceWriteFailed
    case importFailed
    case previewBuildFailed
    case exportFailed
    case photoLibrarySaveFailed
    case unexpected
}

nonisolated struct MemoMarkError:
    Error,
    Hashable,
    Sendable {

    let code: MemoMarkErrorCode

    let message: String

    let underlyingDescription: String?

    let diagnosticCode: String?

    let supportID: String?

    init(
        code: MemoMarkErrorCode,
        message: String,
        underlyingDescription: String? = nil,
        diagnosticCode: String? = nil,
        supportID: String? = nil
    ) {
        self.code = code
        self.message = message
        self.underlyingDescription =
            underlyingDescription
        self.diagnosticCode = diagnosticCode
        self.supportID = supportID
    }

    static func wrapped(
        _ error: Error,
        code: MemoMarkErrorCode,
        message: String,
        underlyingDescription: String? = nil
    ) -> Self {

        Self(
            code: code,
            message: message,
            underlyingDescription:
                underlyingDescription
                ?? String(
                    describing: error
                )
        )
    }

    static func readFailure(
        _ failure:
            MemoMarkSharedDefaultsReadFailure,
        message: String
    ) -> Self {

        Self(
            code: .persistenceReadFailed,
            message: message,
            underlyingDescription:
                "\(failure.storageKey) (\(failure.payloadByteCount) bytes): \(failure.underlyingDescription)"
        )
    }

    static func writeFailure(
        _ failure:
            MemoMarkSharedDefaultsWriteFailure,
        message: String
    ) -> Self {

        Self(
            code: .persistenceWriteFailed,
            message: message,
            underlyingDescription:
                "\(failure.storageKey): \(failure.underlyingDescription)"
        )
    }
}

nonisolated enum MemoMarkResult<Value> {
    case success(Value)
    case failure(MemoMarkError)

    var value: Value? {

        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }

    var error: MemoMarkError? {

        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }

    func map<MappedValue>(
        _ transform: (Value) -> MappedValue
    ) -> MemoMarkResult<MappedValue> {

        switch self {
        case .success(let value):
            return .success(
                transform(value)
            )
        case .failure(let error):
            return .failure(error)
        }
    }

    func flatMap<MappedValue>(
        _ transform: (Value) -> MemoMarkResult<MappedValue>
    ) -> MemoMarkResult<MappedValue> {

        switch self {
        case .success(let value):
            return transform(value)
        case .failure(let error):
            return .failure(error)
        }
    }
}
