import Foundation

struct MemoMarkSharedDefaultsReadFailure:
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

enum MemoMarkSharedDefaultsReadResult<Value> {
    case noValue
    case success(Value)
    case decodingFailed(
        MemoMarkSharedDefaultsReadFailure
    )
}

struct MemoMarkSharedDefaultsWriteFailure:
    Hashable,
    Sendable {

    let storageKey: String

    let underlyingDescription: String
}

enum MemoMarkSharedDefaultsWriteResult {
    case success
    case encodingFailed(
        MemoMarkSharedDefaultsWriteFailure
    )
}
