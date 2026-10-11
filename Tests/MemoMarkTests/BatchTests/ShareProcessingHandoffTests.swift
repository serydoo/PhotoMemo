import Testing
@testable import MemoMark

@Suite("Share processing handoff")
struct ShareProcessingHandoffTests {
    @Test("Accepted Continued work stays in Photos even if recovery scheduling is unavailable")
    @MainActor func acceptedDoesNotOpenHost() async {
        var opened = false
        let result = await ShareProcessingHandoff.perform(requiresPhotoAuthorization: false,
            submitContinued: { true }, openHost: { opened = true; return true })
        #expect(result == .background)
        #expect(!opened)
    }

    @Test("Photo authorization uses host without submitting background processing")
    @MainActor func authorizationRequiresHost() async {
        var submitted = false
        let result = await ShareProcessingHandoff.perform(requiresPhotoAuthorization: true,
            submitContinued: { submitted = true; return true }, openHost: { true })
        #expect(result == .foreground)
        #expect(!submitted)
    }

    @Test("Unavailable or rejected Continued submission falls back to host", arguments: [true, false])
    @MainActor func failedSubmissionFallsBack(hostOpens: Bool) async {
        var order: [String] = []
        let result = await ShareProcessingHandoff.perform(requiresPhotoAuthorization: false,
            submitContinued: { order.append("submit"); return false },
            openHost: { order.append("open"); return hostOpens })
        #expect(order == ["submit", "open"])
        #expect(result == (hostOpens ? .foreground : .handoffFailed))
    }
}
