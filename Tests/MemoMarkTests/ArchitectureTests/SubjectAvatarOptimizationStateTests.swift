#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Subject avatar optimization state")
struct SubjectAvatarOptimizationStateTests {

    @Test("a new request is accepted only for its subject")
    func requestIdentityIsScopedToSubject() {
        var state = SubjectAvatarOptimizationState()
        let request = state.begin(subjectID: UUID())

        #expect(state.isCurrent(request, subjectID: request.subjectID))
        #expect(!state.isCurrent(request, subjectID: UUID()))
    }

    @Test("a newer request invalidates the previous request")
    func newerRequestWins() {
        var state = SubjectAvatarOptimizationState()
        let first = state.begin(subjectID: UUID())
        let second = state.begin(subjectID: first.subjectID)

        #expect(!state.isCurrent(first, subjectID: first.subjectID))
        #expect(state.isCurrent(second, subjectID: second.subjectID))
    }

    @Test("invalidating a request also clears the busy state")
    func invalidationClearsBusyState() {
        var state = SubjectAvatarOptimizationState()
        let request = state.begin(subjectID: UUID())
        state.markOptimizing(request)

        state.invalidate()

        #expect(state.activeRequest == nil)
        #expect(state.isOptimizing == false)
    }
}
#endif
