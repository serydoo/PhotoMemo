#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum V1IOSSubjectConfigurationFlowPresenter {

    @MainActor
    static func makeFlowState(
        from liveSession: ConfigurationSession,
        persistSubject: ((MemorySubject) async throws -> Void)? = nil,
        didPersistSubject: ((MemorySubject) -> Void)? = nil
    ) -> V1IOSSubjectConfigurationFlowState? {
        V1IOSSubjectConfigurationFlowState(
            liveSession: liveSession,
            persistSubject: persistSubject,
            didPersistSubject: didPersistSubject
        )
    }
}
#endif
