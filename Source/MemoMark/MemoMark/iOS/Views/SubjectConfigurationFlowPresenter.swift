#if !MEMOMARK_SHARE_EXTENSION
import Foundation

enum SubjectConfigurationFlowPresenter {

    @MainActor
    static func makeFlowState(
        from liveSession: ConfigurationSession,
        persistSubject: ((MemorySubject) async throws -> Void)? = nil,
        didPersistSubject: ((MemorySubject) -> Void)? = nil
    ) -> SubjectConfigurationFlowState? {
        SubjectConfigurationFlowState(
            liveSession: liveSession,
            persistSubject: persistSubject,
            didPersistSubject: didPersistSubject
        )
    }
}
#endif
