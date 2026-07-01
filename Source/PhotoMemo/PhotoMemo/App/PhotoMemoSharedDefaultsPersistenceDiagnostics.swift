import Foundation

struct PhotoMemoSharedDefaultsReadFailure:
    Hashable,
    Sendable {

    let storageKey: String

    let payloadByteCount: Int

    let underlyingDescription: String
}

enum PhotoMemoSharedDefaultsReadResult<Value> {
    case noValue
    case success(Value)
    case decodingFailed(
        PhotoMemoSharedDefaultsReadFailure
    )
}

struct PhotoMemoSharedDefaultsWriteFailure:
    Hashable,
    Sendable {

    let storageKey: String

    let underlyingDescription: String
}

enum PhotoMemoSharedDefaultsWriteResult {
    case success
    case encodingFailed(
        PhotoMemoSharedDefaultsWriteFailure
    )
}
