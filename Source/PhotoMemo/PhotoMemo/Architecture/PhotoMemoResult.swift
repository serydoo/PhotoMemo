import Foundation

enum PhotoMemoErrorCode:
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

struct PhotoMemoError:
    Error,
    Hashable,
    Sendable {

    let code: PhotoMemoErrorCode

    let message: String

    let underlyingDescription: String?

    init(
        code: PhotoMemoErrorCode,
        message: String,
        underlyingDescription: String? = nil
    ) {
        self.code = code
        self.message = message
        self.underlyingDescription =
            underlyingDescription
    }

    static func wrapped(
        _ error: Error,
        code: PhotoMemoErrorCode,
        message: String
    ) -> Self {

        Self(
            code: code,
            message: message,
            underlyingDescription:
                String(
                    describing: error
                )
        )
    }

    static func readFailure(
        _ failure:
            PhotoMemoSharedDefaultsReadFailure,
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
            PhotoMemoSharedDefaultsWriteFailure,
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

enum PhotoMemoResult<Value> {
    case success(Value)
    case failure(PhotoMemoError)

    var value: Value? {

        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }

    var error: PhotoMemoError? {

        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }

    func map<MappedValue>(
        _ transform: (Value) -> MappedValue
    ) -> PhotoMemoResult<MappedValue> {

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
        _ transform: (Value) -> PhotoMemoResult<MappedValue>
    ) -> PhotoMemoResult<MappedValue> {

        switch self {
        case .success(let value):
            return transform(value)
        case .failure(let error):
            return .failure(error)
        }
    }
}
