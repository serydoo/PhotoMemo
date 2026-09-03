#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Value-type lifecycle state for an avatar optimization request.
///
/// The editor remains the owner of presentation and persistence. This type
/// only owns request identity and cancellation semantics so an older async
/// result cannot mutate a newer subject or crop request.
struct SubjectAvatarOptimizationRequest: Hashable {

    let requestID: UUID
    let subjectID: UUID

    init(requestID: UUID = UUID(), subjectID: UUID) {
        self.requestID = requestID
        self.subjectID = subjectID
    }
}

struct SubjectAvatarOptimizationState: Equatable {

    private(set) var activeRequest: SubjectAvatarOptimizationRequest?
    private(set) var isOptimizing = false

    @discardableResult
    mutating func begin(
        subjectID: UUID
    ) -> SubjectAvatarOptimizationRequest {
        let request = SubjectAvatarOptimizationRequest(subjectID: subjectID)
        activeRequest = request
        isOptimizing = false
        return request
    }

    mutating func markOptimizing(
        _ request: SubjectAvatarOptimizationRequest
    ) {
        guard activeRequest == request else {
            return
        }
        isOptimizing = true
    }

    /// Keeps the request alive while the crop sheet owns the next user step.
    /// A confirmation must still be able to prove it belongs to this request.
    mutating func markReadyForCrop(
        _ request: SubjectAvatarOptimizationRequest
    ) {
        guard activeRequest == request else {
            return
        }
        isOptimizing = false
    }

    mutating func invalidate() {
        activeRequest = nil
        isOptimizing = false
    }

    func isCurrent(
        _ request: SubjectAvatarOptimizationRequest,
        subjectID: UUID
    ) -> Bool {
        activeRequest == request && request.subjectID == subjectID
    }

    mutating func finish(
        _ request: SubjectAvatarOptimizationRequest
    ) {
        guard activeRequest == request else {
            return
        }
        activeRequest = nil
        isOptimizing = false
    }
}
#endif
