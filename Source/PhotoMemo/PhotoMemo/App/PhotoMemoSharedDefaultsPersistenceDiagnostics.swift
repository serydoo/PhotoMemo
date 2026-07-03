import Foundation

struct PhotoMemoSharedDefaultsReadFailure:
    Hashable,
    Sendable {

    let storageKey: String

    let payloadByteCount: Int

    let underlyingDescription: String

    let rawPayload: Data?

    nonisolated init(
        storageKey: String,
        payloadByteCount: Int,
        underlyingDescription: String,
        rawPayload: Data? = nil
    ) {
        self.storageKey = storageKey
        self.payloadByteCount = payloadByteCount
        self.underlyingDescription =
            underlyingDescription
        self.rawPayload = rawPayload
    }
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
